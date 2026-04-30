import 'dart:typed_data';

import 'package:chatmcp/llm/prompt.dart';
import 'package:chatmcp/utils/platform.dart' hide File;
import 'package:flutter/material.dart';
import 'package:chatmcp/llm/model.dart';
import 'package:chatmcp/llm/llm_factory.dart';
import 'package:chatmcp/llm/base_llm_client.dart';
import 'package:logging/logging.dart';
import 'package:file_picker/file_picker.dart';
import 'input_area.dart';
import 'package:chatmcp/provider/provider_manager.dart';
import 'package:chatmcp/utils/file_content.dart';
import 'package:chatmcp/dao/chat.dart';
import 'package:uuid/uuid.dart';
import 'chat_message_list.dart';
import 'package:chatmcp/utils/color.dart';
import 'chat_message_to_image.dart';
import 'package:chatmcp/utils/event_bus.dart';
import 'chat_code_preview.dart';
import 'package:chatmcp/generated/app_localizations.dart';
import 'dart:convert';
import 'package:chatmcp/mcp/models/json_rpc_message.dart';
import 'dart:async';
import 'package:chatmcp/echo/echo_api_client.dart';
import 'package:chatmcp/echo/echo_client.dart';
import 'package:chatmcp/echo/echo_loop_state.dart';
import 'package:chatmcp/echo/echo_theme.dart';
import 'package:chatmcp/echo/auth_service.dart';
import 'package:chatmcp/llm/openai_client.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ComposioAuthLink {
  final String toolkit;
  final String url;

  const _ComposioAuthLink({required this.toolkit, required this.url});
}

class _ChatPageState extends State<ChatPage> {
  Chat? _chat;
  List<ChatMessage> _messages = [];
  bool _isComposing = false; // Indicates if the user is currently composing a message
  BaseLLMClient? _llmClient;
  String _currentResponse = '';
  bool _isLoading = false; // Indicates if the chat is currently loading or processing a response
  String _parentMessageId = ''; // Parent message ID
  bool _isCancelled = false; // Indicates if the current operation has been cancelled by the user
  bool _isWaiting = false; // Indicates if the system is waiting for a response from the LLM

  // Echo sidecar — tracks last exchange for feedback signals
  String _lastUserMessage = '';
  String _lastAssistantMessage = '';
  String _lastModelUsed = '';

  // GlobalKey for InputArea to access focus methods
  final GlobalKey<InputAreaState> _inputAreaKey = GlobalKey<InputAreaState>();

  // Stores image bytes of the widget for sharing functionality
  Uint8List? bytes;

  bool mobile = kIsMobile;

  final List<RunFunctionEvent> _runFunctionEvents = [];
  bool _isRunningFunction = false;
  bool _skipNextLlmResponse = false;

  num _currentLoop = 0;

  // https://stackoverflow.com/questions/51791501/how-to-debounce-textfield-onchange-in-dart
  Timer? _debounce;
  static const int _chatPageDebounceTime = 100;

  @override
  void initState() {
    super.initState();
    _initializeState();
    on<ShareEvent>(_handleShare);
    unawaited(EchoLoopState().refresh());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isMobile() != mobile) {
        setState(() {
          mobile = _isMobile();
        });
      }
      if (!mobile && showModalCodePreview) {
        setState(() {
          Navigator.pop(context);
          showModalCodePreview = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _removeListeners();
    super.dispose();
  }

  // Initializes state and sets up related methods
  void _initializeState() {
    _initializeLLMClient();
    _addListeners();
    _initializeHistoryMessages();
    on<RunFunctionEvent>(_onRunFunction);
    on<SubmitPromptEvent>(_onSubmitPrompt);
  }

  Future<void> _onRunFunction(RunFunctionEvent event) async {
    setState(() {
      _runFunctionEvents.add(event);
    });

    if (!_isLoading) {
      _handleSubmitted(SubmitData("", []));
    }
  }

  Future<void> _onSubmitPrompt(SubmitPromptEvent event) async {
    if (!mounted || event.text.trim().isEmpty) return;
    await _handleSubmitted(SubmitData(event.text.trim(), []));
  }

  Future<bool> _showFunctionApprovalDialog(RunFunctionEvent event) async {
    if (_shouldAutoApproveComposioHelper(event)) {
      return true;
    }

    // Determines which MCP server's tool the function belongs to
    final clientName = _findClientName(ProviderManager.mcpServerProvider.tools, event.name);
    if (clientName == null) return false;

    final serverConfig = await ProviderManager.mcpServerProvider.loadServersAll();
    final servers = serverConfig['mcpServers'] as Map<String, dynamic>? ?? {};

    if (servers.containsKey(clientName)) {
      final config = servers[clientName] as Map<String, dynamic>? ?? {};
      final autoApprove = config['auto_approve'] as bool? ?? false;

      // Skips authorization dialog if auto-approve is enabled in server config
      if (autoApprove) {
        return true;
      }
    }

    // Verifies component is still mounted before showing dialog
    if (!mounted) return false;

    // Displays authorization dialog for function execution
    var t = AppLocalizations.of(context)!;
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
              title: Text(t.functionCallAuth),
              content: SingleChildScrollView(
                child: ListBody(children: <Widget>[Text(t.allowFunctionExecution), SizedBox(height: 8), Text(event.name), SizedBox(height: 8)]),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(t.cancel),
                  onPressed: () {
                    setState(() {
                      _runFunctionEvents.clear();
                    });
                    Navigator.of(context).pop(false);
                  },
                ),
                TextButton(
                  child: Text(t.allow),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                ),
              ],
            );
          },
        ) ??
        false;
  }

  bool _shouldAutoApproveComposioHelper(RunFunctionEvent event) {
    if (event.name == 'COMPOSIO_SEARCH_TOOLS' || event.name == 'COMPOSIO_WAIT_FOR_CONNECTIONS') {
      return true;
    }

    if (event.name != 'COMPOSIO_MANAGE_CONNECTIONS') {
      return false;
    }

    final toolkits = event.arguments['toolkits'];
    if (toolkits is! Iterable) {
      return true;
    }

    for (final toolkit in toolkits) {
      if (toolkit is Map) {
        final action = toolkit['action']?.toString().toLowerCase();
        if (action != null && action != 'add' && action != 'list') {
          return false;
        }
      }
    }

    return true;
  }

  void _addListeners() {
    ProviderManager.chatModelProvider.addListener(_initializeLLMClient);
    ProviderManager.chatProvider.addListener(_onChatProviderChanged);
  }

  void _removeListeners() {
    ProviderManager.chatModelProvider.removeListener(_initializeLLMClient);
    ProviderManager.chatProvider.removeListener(_onChatProviderChanged);
  }

  void _initializeLLMClient() {
    _llmClient = LLMFactoryHelper.createFromModel(ProviderManager.chatModelProvider.currentModel);
    setState(() {});
  }

  void _onChatProviderChanged() {
    // Detect explicit "new chat" requests and force a full reset.
    final trigger = ProviderManager.chatProvider.newChatTrigger;
    if (trigger != _lastNewChatTrigger) {
      _lastNewChatTrigger = trigger;
      setState(() {
        _messages = [];
        _chat = null;
        _parentMessageId = '';
      });
      _resetState();
      return;
    }

    _initializeHistoryMessages();
    if (_isMobile() && ProviderManager.chatProvider.showCodePreview && ProviderManager.chatProvider.artifactEvent != null) {
      _showMobileCodePreview();
    } else {
      setState(() {
        _showCodePreview = ProviderManager.chatProvider.showCodePreview;
      });
    }
  }

  bool _showCodePreview = false;
  int _lastNewChatTrigger = 0;

  List<ChatMessage> _allMessages = [];

  Future<List<ChatMessage>> _getHistoryTreeMessages() async {
    final activeChat = ProviderManager.chatProvider.activeChat;
    if (activeChat == null) return [];

    Map<String, List<String>> messageMap = {};

    final messages = await activeChat.getChatMessages();

    for (var message in messages) {
      if (message.role == MessageRole.user) {
        continue;
      }
      if (messageMap[message.parentMessageId] == null) {
        messageMap[message.parentMessageId] = [];
      }

      messageMap[message.parentMessageId]?.add(message.messageId);
    }

    for (var message in messages) {
      final brotherIds = messageMap[message.messageId] ?? [];

      if (brotherIds.length > 1) {
        int index = messages.indexWhere((m) => m.messageId == message.messageId);
        if (index != -1) {
          messages[index].childMessageIds ??= brotherIds;
        }

        for (var brotherId in brotherIds) {
          final index = messages.indexWhere((m) => m.messageId == brotherId);
          if (index != -1) {
            messages[index].brotherMessageIds ??= brotherIds;
          }
        }
      }
    }

    setState(() {
      _allMessages = messages;
    });

    if (messages.isEmpty) {
      return [];
    }

    final lastMessage = messages.last;
    return _getTreeMessages(lastMessage.messageId, messages);
  }

  List<ChatMessage> _getTreeMessages(String messageId, List<ChatMessage> messages) {
    final lastMessage = messages.firstWhere((m) => m.messageId == messageId);
    List<ChatMessage> treeMessages = [];

    ChatMessage? currentMessage = lastMessage;
    while (currentMessage != null) {
      if (currentMessage.role != MessageRole.user) {
        final childMessageIds = currentMessage.childMessageIds;
        if (childMessageIds != null && childMessageIds.isNotEmpty) {
          for (var childId in childMessageIds.reversed) {
            final childMessage = messages.firstWhere(
              (m) => m.messageId == childId,
              orElse: () => ChatMessage(content: '', role: MessageRole.user),
            );
            if (treeMessages.any((m) => m.messageId == childMessage.messageId)) {
              continue;
            }
            treeMessages.insert(0, childMessage);
          }
        }
      }

      treeMessages.insert(0, currentMessage);

      final parentId = currentMessage.parentMessageId;
      if (parentId.isEmpty) break;

      currentMessage = messages.firstWhere(
        (m) => m.messageId == parentId,
        orElse: () => ChatMessage(messageId: '', content: '', role: MessageRole.user, parentMessageId: ''),
      );

      if (currentMessage.messageId.isEmpty) break;
    }

    ChatMessage? nextMessage = messages
        .where((m) => m.role == MessageRole.user)
        .firstWhere(
          (m) => m.parentMessageId == lastMessage.messageId,
          orElse: () => ChatMessage(messageId: '', content: '', role: MessageRole.user),
        );

    while (nextMessage != null && nextMessage.messageId.isNotEmpty) {
      if (!treeMessages.any((m) => m.messageId == nextMessage!.messageId)) {
        treeMessages.add(nextMessage);
      }
      final childMessageIds = nextMessage.childMessageIds;
      if (childMessageIds != null && childMessageIds.isNotEmpty) {
        for (var childId in childMessageIds) {
          final childMessage = messages.firstWhere(
            (m) => m.messageId == childId,
            orElse: () => ChatMessage(messageId: '', content: '', role: MessageRole.user),
          );
          if (treeMessages.any((m) => m.messageId == childMessage.messageId)) {
            continue;
          }
          treeMessages.add(childMessage);
        }
      }

      nextMessage = messages.firstWhere(
        (m) => m.parentMessageId == nextMessage!.messageId,
        orElse: () => ChatMessage(messageId: '', content: '', role: MessageRole.user),
      );
    }

    return treeMessages;
  }

  // Message processing related methods
  Future<void> _initializeHistoryMessages() async {
    final activeChat = ProviderManager.chatProvider.activeChat;
    if (activeChat == null && _messages.isEmpty) {
      setState(() {
        _messages = [];
        _chat = null;
        _parentMessageId = '';
      });
      _resetState();
      // Auto focus input on desktop when creating new chat
      if (!kIsMobile) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _inputAreaKey.currentState?.requestFocus();
        });
      }
      return;
    }
    if (_chat?.id != activeChat?.id) {
      final messages = await _getHistoryTreeMessages();
      // Find the index of the last user message
      final lastUserIndex = messages.lastIndexWhere((m) => m.role == MessageRole.user);
      String parentId = '';

      // If a user message is found, and there is an assistant message after it, use the ID of the assistant message
      if (lastUserIndex != -1 && lastUserIndex + 1 < messages.length) {
        parentId = messages[lastUserIndex + 1].messageId;
      } else if (messages.isNotEmpty) {
        // If no suitable message is found, use the ID of the last message
        parentId = messages.last.messageId;
      }

      ProviderManager.chatProvider.clearArtifactEvent();

      setState(() {
        _messages = messages;
        _chat = activeChat;
        _parentMessageId = parentId;
      });
      _resetState();
      // Auto focus input on desktop when switching to a different chat
      if (!kIsMobile) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _inputAreaKey.currentState?.requestFocus();
        });
      }
    }
  }

  // UI building related methods
  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return Expanded(child: _buildEmptyState());
    }

    final parentMsgIndex = _messages.length - 1;
    for (var i = 0; i < parentMsgIndex; i++) {
      if (_messages[i].content?.contains('<function') == true && _messages[i].content?.contains('<function done="true"') == false) {
        _messages[i] = _messages[i].copyWith(content: _messages[i].content?.replaceAll("<function ", "<function done=\"true\" "));
      }
    }

    return Expanded(
      child: MessageList(
        messages: _isWaiting ? [..._messages, ChatMessage(content: '', role: MessageRole.loading)] : _messages.toList(),
        onRetry: _onRetry,
        onSwitch: _onSwitch,
      ),
    );
  }

  Widget _buildEmptyState() {
    final username = AuthService().username;
    final firstName = username != null && username.isNotEmpty ? username.split(' ').first : null;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';
    final headline = firstName != null ? '$greeting, $firstName.' : '$greeting.';

    final starters = ["What's something I've been avoiding?", "Help me think through a decision", "What have you noticed about me lately?"];

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/echo_logo.png', width: 44, height: 44),
          const SizedBox(height: 18),
          Text(
            headline,
            style: GoogleFonts.lora(fontSize: 22, fontStyle: FontStyle.italic, color: EchoColors.textPrimary, letterSpacing: -0.3, height: 1.3),
          ),
          const SizedBox(height: 6),
          Text("What's on your mind?", style: GoogleFonts.plusJakartaSans(fontSize: 13, color: EchoColors.textGhost)),
          const SizedBox(height: 28),
          ...starters.map((s) => Padding(padding: const EdgeInsets.only(bottom: 8), child: _buildStarterPrompt(s))),
        ],
      ),
    );
  }

  Widget _buildStarterPrompt(String text) {
    return GestureDetector(
      onTap: () {
        _inputAreaKey.currentState?.textController.text = text;
        _handleTextChanged(text);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0xFF0C0A08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: EchoColors.border),
        ),
        child: Text(text, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: EchoColors.textMuted, height: 1.4)),
      ),
    );
  }

  void _onSwitch(String messageId) {
    final messages = _getTreeMessages(messageId, _allMessages);
    setState(() {
      _messages = messages;
    });
  }

  // Message processing related methods
  void _handleTextChanged(String text) {
    setState(() {
      _isComposing = text.isNotEmpty;
    });
  }

  String? _findClientName(Map<String, List<Map<String, dynamic>>> tools, String toolName) {
    for (var entry in tools.entries) {
      final clientTools = entry.value;
      if (clientTools.any((tool) => tool['name'] == toolName)) {
        return entry.key;
      }
    }
    return null;
  }

  Future<void> _sendToolCallAndProcessResponse(String toolName, Map<String, dynamic> toolArguments) async {
    if (toolName == 'COMPOSIO_MANAGE_CONNECTIONS') {
      final handled = await _tryCreateManagedComposioAuth(toolArguments);
      if (handled) return;
    }

    final clientName = _findClientName(ProviderManager.mcpServerProvider.tools, toolName);
    if (clientName == null) {
      Logger.root.severe('No MCP server found for tool: $toolName');
      return;
    }

    final mcpClient = ProviderManager.mcpServerProvider.getClient(clientName);
    if (mcpClient == null) {
      Logger.root.severe('No MCP client found for tool: $toolName');
      return;
    }

    // Configures tool call with timeout and retry mechanism
    const int maxRetries = 3;
    const Duration timeout = Duration(seconds: 60 * 5);

    JSONRPCMessage? response;
    String? lastError;

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        Logger.root.info('send tool call attempt ${attempt + 1}/$maxRetries - name: $toolName arguments: $toolArguments');

        response = await mcpClient.sendToolCall(name: toolName, arguments: toolArguments).timeout(timeout);

        // Exits retry loop on successful response
        break;
      } catch (e) {
        lastError = e.toString();
        Logger.root.warning('tool call attempt ${attempt + 1}/$maxRetries failed: $e');

        // Implements exponential backoff before next retry attempt
        if (attempt < maxRetries - 1) {
          final delay = Duration(seconds: (attempt + 1) * 2); // Incremental delay
          Logger.root.info('waiting ${delay.inSeconds}s before retry...');
          await Future.delayed(delay);
        }
      }
    }

    // Logs error and updates UI when all retry attempts fail
    if (response == null) {
      Logger.root.severe('Tool call failed after $maxRetries attempts: $lastError');
      setState(() {
        _parentMessageId = _messages.last.messageId;
        final msgId = Uuid().v4();
        _messages.add(
          ChatMessage(
            messageId: msgId,
            content: '<call_function_result name="$toolName">\n failed to call function: $lastError\n</call_function_result>',
            role: MessageRole.assistant,
            name: toolName,
            parentMessageId: _parentMessageId,
          ),
        );
        _parentMessageId = msgId;
      });
      return;
    }

    Logger.root.info('Tool call success - name: $toolName arguments: $toolArguments response: $response');

    if (toolName == 'COMPOSIO_MANAGE_CONNECTIONS') {
      final authLinks = _extractComposioAuthLinks(response);
      if (authLinks.isNotEmpty) {
        setState(() {
          _currentResponse = _buildComposioAuthMessage(authLinks);
          _parentMessageId = _messages.last.messageId;
          final msgId = Uuid().v4();
          _messages.add(
            ChatMessage(messageId: msgId, content: _currentResponse, role: MessageRole.assistant, name: toolName, parentMessageId: _parentMessageId),
          );
          _parentMessageId = msgId;
          _skipNextLlmResponse = true;
        });
        return;
      }
    }

    setState(() {
      _currentResponse = response!.result['content'].toString();
      if (_currentResponse.isNotEmpty) {
        _parentMessageId = _messages.last.messageId;
        final msgId = Uuid().v4();
        _messages.add(
          ChatMessage(
            messageId: msgId,
            content: '<call_function_result name="$toolName">\n$_currentResponse\n</call_function_result>',
            role: MessageRole.assistant,
            name: toolName,
            parentMessageId: _parentMessageId,
          ),
        );
        _parentMessageId = msgId;
      }
    });
  }

  Future<bool> _tryCreateManagedComposioAuth(Map<String, dynamic> toolArguments) async {
    // Only intercept 'add' action — let 'list', 'rename', 'remove' pass through to MCP.
    final action = (toolArguments['action'] as String? ?? 'add').toLowerCase();
    if (action != 'add') return false;

    final toolkits = _extractComposioToolkits(toolArguments);
    if (toolkits.isEmpty) return false;

    final links = <_ComposioAuthLink>[];
    final setupErrors = <String>[];
    final composio = ProviderManager.composioProvider;

    for (final slug in toolkits) {
      // Resolve display name for the provider (e.g. 'gmail' → 'Gmail').
      final displayName = _slugToDisplayName(slug);
      final url = await composio.getConnectionUrl(displayName);
      if (url != null && url.isNotEmpty) {
        links.add(_ComposioAuthLink(toolkit: slug, url: url));
      } else {
        setupErrors.add(composio.lastError ?? 'Could not get an auth link for $slug.');
      }
    }

    setState(() {
      _parentMessageId = _messages.last.messageId;
      final msgId = Uuid().v4();
      _currentResponse = links.isNotEmpty
          ? _buildComposioAuthMessage(links)
          : _buildComposioSetupMessage(toolkits.first, setupErrors);
      _messages.add(
        ChatMessage(
          messageId: msgId,
          content: _currentResponse,
          role: MessageRole.assistant,
          name: 'COMPOSIO_MANAGE_CONNECTIONS',
          parentMessageId: _parentMessageId,
        ),
      );
      _parentMessageId = msgId;
      _skipNextLlmResponse = true;
    });
    return true;
  }

  String _slugToDisplayName(String slug) {
    const slugToDisplay = {
      'gmail': 'Gmail',
      'googlecalendar': 'Google Calendar',
      'kindle': 'Kindle / Reading',
      'spotify': 'Spotify',
      'notion': 'Notion',
      'github': 'GitHub',
      'slack': 'Slack',
      'twitter': 'Twitter / X',
    };
    return slugToDisplay[slug.toLowerCase()] ?? slug;
  }

  Set<String> _extractComposioToolkits(Map<String, dynamic> toolArguments) {
    final result = <String>{};

    // Singular 'toolkit' field (COMPOSIO_MANAGE_CONNECTIONS with action: 'add').
    final single = toolArguments['toolkit'];
    if (single is String && single.trim().isNotEmpty) {
      result.add(single.trim().toLowerCase());
    }

    // Plural 'toolkits' list (legacy / other tools).
    final toolkits = toolArguments['toolkits'];
    if (toolkits is Iterable) {
      for (final toolkit in toolkits) {
        if (toolkit is String) {
          result.add(toolkit.trim().toLowerCase());
        } else if (toolkit is Map) {
          final name = toolkit['name'] ?? toolkit['toolkit'] ?? toolkit['slug'];
          if (name != null) result.add(name.toString().trim().toLowerCase());
        }
      }
    }
    return result;
  }

  List<_ComposioAuthLink> _extractComposioAuthLinks(JSONRPCMessage response) {
    final links = <_ComposioAuthLink>[];
    final seen = <String>{};

    void addLink(String? toolkit, String? url) {
      if (url == null || url.trim().isEmpty || !_isComposioAuthUrl(url)) return;
      final normalizedToolkit = (toolkit == null || toolkit.trim().isEmpty) ? 'account' : toolkit.trim().toLowerCase();
      final key = '$normalizedToolkit|$url';
      if (seen.add(key)) {
        links.add(_ComposioAuthLink(toolkit: normalizedToolkit, url: url));
      }
    }

    String? toolkitFromMap(Map<dynamic, dynamic> value) {
      final toolkit = value['toolkit'] ?? value['toolkit_name'] ?? value['toolkitName'] ?? value['name'];
      return toolkit?.toString();
    }

    void scan(dynamic value, [String? toolkitHint]) {
      if (value is Map) {
        final toolkit = toolkitFromMap(value) ?? toolkitHint;
        final redirectUrl = value['redirect_url'] ?? value['redirectUrl'] ?? value['auth_url'] ?? value['authUrl'];
        if (redirectUrl is String) {
          addLink(toolkit, redirectUrl);
        }

        final results = value['results'];
        if (results is Map) {
          results.forEach((key, entry) => scan(entry, key.toString()));
        }

        for (final entry in value.entries) {
          if (entry.key == 'results') continue;
          scan(entry.value, toolkit);
        }
      } else if (value is Iterable) {
        for (final item in value) {
          scan(item, toolkitHint);
        }
      }
    }

    void scanText(String text) {
      try {
        scan(jsonDecode(text));
      } catch (_) {
        final matches = RegExp(r'https://(?:connect|platform)\.composio\.dev/link/[^\s"<>\\]+').allMatches(text);
        for (final match in matches) {
          addLink(null, match.group(0));
        }
      }
    }

    final result = response.result;
    if (result is Map) {
      final content = result['content'];
      if (content is Iterable) {
        for (final item in content) {
          if (item is Map && item['text'] is String) {
            scanText(item['text'] as String);
          } else {
            scan(item);
          }
        }
      }
      scan(result);
    } else {
      scan(result);
    }

    return links;
  }

  bool _isComposioAuthUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme) return false;
    if ((uri.host == 'connect.composio.dev' || uri.host == 'platform.composio.dev') &&
        uri.path.startsWith('/link/')) return true;
    final host = uri.host.toLowerCase();
    final path = uri.path.toLowerCase();
    return host.contains('composio') ||
        path.contains('/oauth') ||
        path.contains('/auth/') ||
        (host == 'accounts.google.com' && path.contains('/o/oauth2'));
  }

  String _buildComposioAuthMessage(List<_ComposioAuthLink> links) {
    final primaryLabel = _formatToolkitLabel(links.first.toolkit);
    final lines = <String>['Connect $primaryLabel', ''];

    for (final link in links) {
      final label = _formatToolkitLabel(link.toolkit);
      lines.add('[Connect $label](${link.url})');
    }

    lines.add('');
    lines.add('After approving access, return to Echo and I will continue automatically.');
    return lines.join('\n');
  }

  String _buildComposioSetupMessage(String toolkit, List<String> errors) {
    final label = _formatToolkitLabel(toolkit);
    final detail = errors.where((e) => e.trim().isNotEmpty).join('\n');
    return [
      'Could not connect $label.',
      '',
      'Make sure Echo Tools is running and your Composio API key is configured.',
      if (detail.isNotEmpty) '',
      if (detail.isNotEmpty) detail,
    ].join('\n');
  }

  String _formatToolkitLabel(String toolkit) {
    if (toolkit.toLowerCase() == 'gmail') return 'Gmail';
    return toolkit
        .replaceAll('-', ' ')
        .replaceAll('_', ' ')
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map((part) => part.substring(0, 1).toUpperCase() + part.substring(1))
        .join(' ');
  }

  ChatMessage? _findUserMessage(ChatMessage message) {
    final parentMessage = _messages.firstWhere(
      (m) => m.messageId == message.parentMessageId,
      orElse: () => ChatMessage(messageId: '', content: '', role: MessageRole.user),
    );

    if (parentMessage.messageId.isEmpty) return null;

    if (parentMessage.role != MessageRole.user) {
      return _findUserMessage(parentMessage);
    }

    return parentMessage;
  }

  Future<void> _onRetry(ChatMessage message) async {
    final userMessage = _findUserMessage(message);
    if (userMessage == null) return;

    final messageIndex = _messages.indexOf(userMessage);
    if (messageIndex == -1) return;

    final previousMessages = _messages.sublist(0, messageIndex + 1);

    setState(() {
      _messages = previousMessages;
      _parentMessageId = userMessage.messageId;
      _isLoading = true;
    });

    await _handleSubmitted(
      SubmitData(userMessage.content ?? '', (userMessage.files ?? []).map((f) => f as PlatformFile).toList()),
      addUserMessage: false,
    );
  }

  /// function calling style tool use
  Future<bool> _checkNeedToolCallFunction() async {
    if (_runFunctionEvents.isNotEmpty) return true;

    final lastMessage = _messages.last;

    final content = lastMessage.content ?? '';
    if (content.isEmpty) return false;

    final messages = _messages.toList();

    Logger.root.info('check need tool call: $messages');

    final result = await _llmClient!.checkToolCall(
      ProviderManager.chatModelProvider.currentModel.name,
      CompletionRequest(model: ProviderManager.chatModelProvider.currentModel.name, messages: [..._prepareMessageList()]),
      ProviderManager.mcpServerProvider.tools,
    );
    final needToolCall = result['need_tool_call'] ?? false;

    if (!needToolCall) {
      return false;
    }

    final toolCalls = result['tool_calls'] as List;
    for (var toolCall in toolCalls) {
      final functionEvent = RunFunctionEvent(toolCall['name'], toolCall['arguments']);

      _runFunctionEvents.add(functionEvent);

      _messages.add(
        ChatMessage(
          content: "<function name=\"${functionEvent.name}\">\n${jsonEncode(functionEvent.arguments)}\n</function>",
          role: MessageRole.assistant,
          parentMessageId: _parentMessageId,
        ),
      );

      _onRunFunction(functionEvent);
    }

    return needToolCall;
  }

  /// xml style function calling tool use
  Future<bool> _checkNeedToolCallXml() async {
    if (_runFunctionEvents.isNotEmpty) return true;

    final lastMessage = _messages.last;
    if (lastMessage.role == MessageRole.user) return true;

    final content = lastMessage.content ?? '';
    if (content.isEmpty) return false;

    // Parses function call tags in format <function name="toolName">args</function>.
    // Some messages are later marked with attributes like done="true", so allow
    // attributes before and after name.
    final RegExp functionTagRegex = RegExp(r'''<function\b[^>]*\bname=["']([^"']*)["'][^>]*>(.*?)</function>''', dotAll: true);
    final matches = functionTagRegex.allMatches(content);

    if (matches.isEmpty) return false;

    for (var match in matches) {
      final toolName = match.group(1);
      final toolArguments = match.group(2);

      if (toolName == null || toolArguments == null) continue;

      try {
        // Cleans and parses tool arguments by removing whitespace and newlines
        final cleanedToolArguments = toolArguments.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
        final toolArgumentsMap = jsonDecode(cleanedToolArguments);
        _onRunFunction(RunFunctionEvent(toolName, toolArgumentsMap));
      } catch (e) {
        Logger.root.warning('Failed to parse tool parameters: $e');
      }
    }

    return _runFunctionEvents.isNotEmpty;
  }

  Future<bool> _checkNeedToolCall() async {
    return await _checkNeedToolCallXml();
  }

  // Message submission processing
  Future<void> _handleSubmitted(SubmitData data, {bool addUserMessage = true}) async {
    setState(() {
      _isCancelled = false;
    });
    final files = data.files.map((file) => platformFileToFile(file)).toList();

    if (addUserMessage && data.text.isNotEmpty) {
      _addUserMessage(data.text, files);
    }

    try {
      final generalSetting = ProviderManager.settingsProvider.generalSetting;
      final maxLoops = generalSetting.maxLoops;

      while (await _checkNeedToolCall()) {
        if (_currentLoop > maxLoops) {
          Logger.root.warning('reach max loops: $maxLoops');
          break;
        }

        if (_runFunctionEvents.isNotEmpty) {
          // Processes function calls in sequential order
          while (_runFunctionEvents.isNotEmpty) {
            final event = _runFunctionEvents.first;

            // Requests user authorization
            final approved = await _showFunctionApprovalDialog(event);

            if (approved) {
              setState(() {
                _isRunningFunction = true;
              });

              await _sendToolCallAndProcessResponse(event.name, event.arguments);
              setState(() {
                _isRunningFunction = false;
              });
              _runFunctionEvents.removeAt(0);
            } else {
              setState(() {
                _runFunctionEvents.clear();
              });
              final msgId = Uuid().v4();
              _messages.add(
                ChatMessage(messageId: msgId, content: 'call function rejected', role: MessageRole.assistant, parentMessageId: _parentMessageId),
              );
              _parentMessageId = msgId;
              break;
            }
          }
        }

        if (_skipNextLlmResponse) {
          _skipNextLlmResponse = false;
          break;
        }

        await _processLLMResponse();
        _currentLoop++;
      }
      await _updateChat();
    } catch (e, stackTrace) {
      _handleError(e, stackTrace);
      await _updateChat();
    }

    setState(() {
      _isLoading = false;
    });
    // Auto focus input on desktop when response completes
    if (!kIsMobile) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _inputAreaKey.currentState?.requestFocus();
      });
    }
  }

  void _addUserMessage(String text, List<File> files) {
    setState(() {
      _isLoading = true;
      _isComposing = false;
      final msgId = Uuid().v4();
      _messages.add(
        ChatMessage(
          messageId: msgId,
          parentMessageId: _parentMessageId,
          content: text.replaceAll('\n', '\n\n'),
          role: MessageRole.user,
          files: files,
        ),
      );
      _parentMessageId = msgId;
    });
  }

  Future<String> _getSystemPrompt() async {
    // return ProviderManager.settingsProvider.generalSetting.systemPrompt;

    final promptGenerator = SystemPromptGenerator();

    var tools = <Map<String, dynamic>>[];
    for (var entry in ProviderManager.mcpServerProvider.tools.entries) {
      if (ProviderManager.serverStateProvider.isEnabled(entry.key)) {
        tools.addAll(entry.value);
      }
    }

    return promptGenerator.generatePrompt(tools: tools);
  }

  bool _hasEnabledMcpTools() {
    for (final entry in ProviderManager.mcpServerProvider.tools.entries) {
      if (ProviderManager.serverStateProvider.isEnabled(entry.key) && entry.value.isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  bool _selectedProviderHasApiKey() {
    final model = ProviderManager.chatModelProvider.currentModel;
    try {
      final setting = ProviderManager.settingsProvider.apiSettings.firstWhere((element) => element.providerId == model.providerId);
      if (model.providerId == 'ollama' || model.providerId == 'echo') return true;
      return setting.apiKey.trim().isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  String _toolSafeEchoInjection(String value) {
    if (value.isEmpty) return value;
    return value.replaceAll(
      'You have NO tools and NO external functions. Do NOT output <function>, <tool_call>, or any XML/function syntax — ever.',
      'You may use the tools explicitly provided in this request. Do not invent tools.',
    );
  }

  Future<void> _processLLMResponse() async {
    setState(() {
      _isWaiting = true;
    });

    List<ChatMessage> messageList = _prepareMessageList();

    final modelSetting = ProviderManager.settingsProvider.modelSetting;
    final generalSetting = ProviderManager.settingsProvider.generalSetting;

    // Limit the number of messages
    final maxMessages = generalSetting.maxMessages;
    if (messageList.length > maxMessages) {
      // Maintains only the most recent messages up to maxMessages limit
      messageList = messageList.sublist(messageList.length - maxMessages);
    }

    // Converts assistant's function call results to user role for proper context
    for (var message in messageList) {
      if (message.role == MessageRole.assistant && message.content?.contains('done="true"') == true) {
        messageList[messageList.indexOf(message)] = message.copyWith(content: message.content?.replaceAll('done="true"', ''));
      }
      if (message.role == MessageRole.assistant && message.content?.startsWith('<call_function_result') == true) {
        messageList[messageList.indexOf(message)] = message.copyWith(
          role: MessageRole.user,
          content: message.content
              ?.replaceAll('<call_function_result name="', 'tool result: ')
              .replaceAll('">', '')
              .replaceAll('</call_function_result>', ''),
        );
      }
    }

    var messageList0 = messageMerge(messageList);

    if (messageList0.isNotEmpty && messageList0.last.role == MessageRole.assistant) {
      messageList0.add(ChatMessage(content: 'continue', role: MessageRole.user));
    }

    final systemPrompt = await _getSystemPrompt();

    // Fetch Echo context for routing decision only (sidecar injects memory itself on the Echo path)
    final userMsg =
        messageList0
            .lastWhere(
              (m) => m.role == MessageRole.user,
              orElse: () => ChatMessage(role: MessageRole.user, content: ''),
            )
            .content ??
        '';
    final echoUserId = await EchoClient().userId;
    final echoCtx = await EchoClient().fetchContext(userMsg);
    _lastUserMessage = userMsg;
    _lastModelUsed = ProviderManager.chatModelProvider.currentModel.name;

    Logger.root.info('Start processing LLM response: $messageList0');

    // Route to local model if Echo recommends it, unless active MCP tools need ChatMCP's tool loop.
    final hasEnabledMcpTools = _hasEnabledMcpTools();
    final useLocalModel = echoCtx != null && echoCtx.recommendedModel == 'local' && echoCtx.loraId != null && !hasEnabledMcpTools;
    final useEchoToolProxy = hasEnabledMcpTools && !_selectedProviderHasApiKey();
    final activeLlmClient = useLocalModel || useEchoToolProxy ? OpenAIClient(apiKey: 'local', baseUrl: EchoClient().baseUrl + '/v1') : _llmClient!;
    final activeModel = useLocalModel || useEchoToolProxy ? 'shadow' : ProviderManager.chatModelProvider.currentModel.name;
    if (useLocalModel) _lastModelUsed = 'local';
    if (useEchoToolProxy) _lastModelUsed = 'echo_tool_proxy';

    // Echo local path: sidecar owns memory and no-tools guard.
    // Echo tool proxy path: send only the tool prompt; Echo injects tool-safe memory server-side.
    // Direct LLM path: prepend Echo's memory context, but make it tool-safe when tools are enabled.
    final echoInjection = echoCtx?.systemInjection ?? '';
    final safeEchoInjection = hasEnabledMcpTools ? _toolSafeEchoInjection(echoInjection) : echoInjection;
    final activeSystemPrompt = useLocalModel
        ? ''
        : useEchoToolProxy
        ? systemPrompt
        : (safeEchoInjection.isNotEmpty ? '$safeEchoInjection\n\n$systemPrompt' : systemPrompt);

    final stream = activeLlmClient.chatStreamCompletion(
      CompletionRequest(
        model: activeModel,
        messages: [
          ChatMessage(content: activeSystemPrompt, role: MessageRole.system),
          ...messageList0,
        ],
        modelSetting: modelSetting,
        userId: echoUserId,
      ),
    );

    _initializeAssistantResponse();
    await _processResponseStream(stream);
    Logger.root.info('End processing LLM response');

    // Echo /save: only needed when NOT routing through Echo (Echo auto-saves in its streaming handler)
    _lastAssistantMessage = _currentResponse;
    if (!useLocalModel && !useEchoToolProxy && _lastUserMessage.isNotEmpty && _lastAssistantMessage.isNotEmpty) {
      await EchoClient().savePair(
        userMessage: _lastUserMessage,
        assistantMessage: _lastAssistantMessage,
        modelUsed: _lastModelUsed,
        engagementSignal: 'continue',
      );
    }
    unawaited(Future<void>.delayed(const Duration(milliseconds: 700), () => EchoLoopState().refresh()));
  }

  List<ChatMessage> _prepareMessageList() {
    final List<ChatMessage> messageList = _messages
        .map((m) => ChatMessage(role: m.role, content: m.content, toolCallId: m.toolCallId, name: m.name, toolCalls: m.toolCalls, files: m.files))
        .toList();

    _reorderMessages(messageList);
    return messageList;
  }

  List<ChatMessage> messageMerge(List<ChatMessage> messageList) {
    if (messageList.isEmpty) return [];

    final newMessages = [messageList.first];

    for (final message in messageList.sublist(1)) {
      if (newMessages.isNotEmpty && newMessages.last.role == message.role) {
        String content = message.content ?? '';

        newMessages.last = newMessages.last.copyWith(content: '${newMessages.last.content}\n\n$content');
      } else {
        newMessages.add(message);
      }
    }

    if (newMessages.isNotEmpty && newMessages.last.role != MessageRole.user) {
      newMessages.add(ChatMessage(content: 'continue', role: MessageRole.user));
    }

    return newMessages;
  }

  void _reorderMessages(List<ChatMessage> messageList) {
    for (int i = 0; i < messageList.length - 1; i++) {
      if (messageList[i].role == MessageRole.user && messageList[i + 1].role == MessageRole.tool) {
        final temp = messageList[i];
        messageList[i] = messageList[i + 1];
        messageList[i + 1] = temp;
        i++;
      }
    }
  }

  void _initializeAssistantResponse() {
    setState(() {
      _currentResponse = '';
      _messages.add(ChatMessage(content: _currentResponse, role: MessageRole.assistant, parentMessageId: _parentMessageId));
    });
  }

  Future<void> _processResponseStream(Stream<LLMResponse> stream) async {
    bool isFirstChunk = true;
    LLMResponse? lastChunk;
    await for (final chunk in stream) {
      if (isFirstChunk) {
        setState(() {
          _isWaiting = false;
        });
        isFirstChunk = false;
      }
      if (_isCancelled) break;
      _currentResponse += chunk.content ?? '';
      if (_messages.isNotEmpty) {
        _messages.last = _messages.last.copyWith(content: _currentResponse);
      }

      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: _chatPageDebounceTime), () {
        if (mounted) {
          setState(() {});
        }
      });
      lastChunk = chunk;
    }

    if (lastChunk?.tokenUsage != null) {
      _messages.last = _messages.last.copyWith(tokenUsage: lastChunk?.tokenUsage);
    }

    _debounce?.cancel();
    if (mounted) {
      setState(() {});
    }

    _isCancelled = false;
  }

  Future<void> _updateChat() async {
    if (ProviderManager.chatProvider.activeChat == null) {
      await _createNewChat();
    } else {
      await _updateExistingChat();
    }
  }

  Future<void> _createNewChat() async {
    if (_messages.isEmpty) return;

    String title;
    try {
      if (!_selectedProviderHasApiKey()) {
        final userMessage = _messages.isNotEmpty ? _messages.first.content ?? '' : '';
        title = _generateFallbackTitle(userMessage);
      } else {
        title = await _llmClient!.genTitle([
          if (_messages.isNotEmpty) _messages.first,
          if (_messages.length > 1) _messages.last else _messages.first,
        ]);
      }
    } catch (e) {
      Logger.root.warning('Failed to generate title: $e');
      // Creates fallback title from user message if title generation fails
      final userMessage = _messages.isNotEmpty ? _messages.first.content ?? '' : '';
      title = _generateFallbackTitle(userMessage);
    }

    await ProviderManager.chatProvider.createChat(Chat(title: title), _handleParentMessageId(_messages));
    Logger.root.info('Created new chat: $title');
  }

  String _generateFallbackTitle(String userMessage) {
    if (userMessage.isEmpty) {
      return 'new chat';
    }

    // Creates title by truncating first 20 characters of user message
    String title = userMessage.replaceAll('\n', ' ').trim();
    if (title.length > 20) {
      title = '${title.substring(0, 17)}...';
    }

    return title.isEmpty ? 'new chat' : title;
  }

  // Handles parent message ID assignment for conversation thread
  List<ChatMessage> _handleParentMessageId(List<ChatMessage> messages) {
    if (messages.isEmpty) return [];

    // Locates the last user message to establish conversation thread
    int lastUserIndex = messages.lastIndexWhere((m) => m.role == MessageRole.user);
    if (lastUserIndex == -1) return messages;

    // Retrieves conversation thread starting from last user message
    List<ChatMessage> relevantMessages = messages.sublist(lastUserIndex);

    // Resets parent IDs for long threads to maintain proper conversation flow
    if (relevantMessages.length > 2) {
      String secondMessageId = relevantMessages[1].messageId;
      for (int i = 2; i < relevantMessages.length; i++) {
        relevantMessages[i] = relevantMessages[i].copyWith(parentMessageId: secondMessageId);
      }
    }

    return relevantMessages;
  }

  Future<void> _updateExistingChat() async {
    final activeChat = ProviderManager.chatProvider.activeChat!;
    await ProviderManager.chatProvider.updateChat(
      Chat(id: activeChat.id!, title: activeChat.title, createdAt: activeChat.createdAt, updatedAt: DateTime.now()),
    );

    await ProviderManager.chatProvider.addChatMessage(activeChat.id!, _handleParentMessageId(_messages));
  }

  void _handleError(dynamic error, StackTrace stackTrace) {
    Logger.root.severe('Error: $error');
    Logger.root.severe('Stack trace: $stackTrace');

    // Extracts detailed error information for debugging purposes
    if (error is TypeError) {
      Logger.root.severe('Type error: ${error.toString()}');
    }

    // Resets all state variables to their initial values
    _resetState();

    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error_outline, color: AppColors.getErrorIconColor()),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context)!.error),
              ],
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getUserFriendlyErrorMessage(error),
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.getErrorTextColor()),
                  ),
                  const SizedBox(height: 8),
                  Text('error type: ${error.runtimeType}', style: TextStyle(fontSize: 12, color: AppColors.getErrorTextColor().withAlpha(128))),
                  if (error is LLMException)
                    Text(error.toString(), style: TextStyle(fontSize: 12, color: AppColors.getErrorTextColor().withAlpha(128))),
                ],
              ),
            ),
            actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(AppLocalizations.of(context)!.close))],
          );
        },
      );
    }
  }

  // Formats error messages for user display
  String _getUserFriendlyErrorMessage(dynamic error) {
    final errorMap = {
      'connection': AppLocalizations.of(context)!.networkError,
      'timeout': AppLocalizations.of(context)!.timeoutError,
      'permission': AppLocalizations.of(context)!.permissionError,
      'cancelled': AppLocalizations.of(context)!.userCancelledToolCall,
      'No element': AppLocalizations.of(context)!.noElementError,
      'not found': AppLocalizations.of(context)!.notFoundError,
      'invalid': AppLocalizations.of(context)!.invalidError,
      'unauthorized': AppLocalizations.of(context)!.unauthorizedError,
    };

    for (final entry in errorMap.entries) {
      if (error.toString().toLowerCase().contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }
    return AppLocalizations.of(context)!.unknownError;
  }

  // Handles chat export functionality
  Future<void> _handleShare(ShareEvent event) async {
    if (_messages.isEmpty) return;
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      if (kIsMobile) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => ListViewToImageScreen(messages: _messages)));
      } else {
        showDialog(
          context: context,
          builder: (context) => ListViewToImageScreen(messages: _messages),
        );
      }
    }
  }

  bool _isMobile() {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return height > width;
  }

  void _resetState() {
    setState(() {
      _isRunningFunction = false;
      _skipNextLlmResponse = false;
      _runFunctionEvents.clear();
      _isLoading = false;
      _isCancelled = false;
      _isWaiting = false;
      _currentLoop = 0;
    });
    // Auto focus input on desktop when state resets
    if (!kIsMobile) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _inputAreaKey.currentState?.requestFocus();
      });
    }
  }

  void _handleCancel() {
    _resetState();
    setState(() {
      _isCancelled = true;
    });
  }

  bool showModalCodePreview = false;
  void _showMobileCodePreview() {
    if (showModalCodePreview) {
      return;
    }
    setState(() {
      showModalCodePreview = true;
    });

    const txtNoCodePreview = Text('No code preview', style: TextStyle(fontSize: 14, color: Colors.grey));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(color: AppColors.getBottomSheetHandleColor(context), borderRadius: BorderRadius.circular(2)),
                  ),
                  Expanded(
                    child: ProviderManager.chatProvider.artifactEvent != null
                        ? ChatCodePreview(codePreviewEvent: ProviderManager.chatProvider.artifactEvent!)
                        : Center(child: txtNoCodePreview),
                  ),
                ],
              );
            },
          ),
        );
      },
    ).whenComplete(() {
      setState(() {
        showModalCodePreview = false;
      });
      ProviderManager.chatProvider.clearArtifactEvent();
    });
  }

  Widget _buildFunctionRunning() {
    if (_isRunningFunction) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor)),
            ),
            const SizedBox(width: 12),
            Text(
              AppLocalizations.of(context)!.functionRunning,
              style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color?.withAlpha((0.7 * 255).round())),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    if (mobile) {
      return Column(
        children: [
          _buildMessageList(),
          _buildFunctionRunning(),
          InputArea(
            key: _inputAreaKey,
            disabled: _isLoading,
            isComposing: _isComposing,
            onTextChanged: _handleTextChanged,
            onSubmitted: _handleSubmitted,
            onCancel: _handleCancel,
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Column(
            children: [
              _buildMessageList(),
              _buildFunctionRunning(),
              InputArea(
                key: _inputAreaKey,
                disabled: _isLoading,
                isComposing: _isComposing,
                onTextChanged: _handleTextChanged,
                onSubmitted: _handleSubmitted,
                onCancel: _handleCancel,
              ),
            ],
          ),
        ),
        if (!mobile && _showCodePreview && ProviderManager.chatProvider.artifactEvent != null)
          Expanded(flex: 2, child: ChatCodePreview(codePreviewEvent: ProviderManager.chatProvider.artifactEvent!)),
      ],
    );
  }
}
