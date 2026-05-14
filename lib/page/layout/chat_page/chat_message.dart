import 'package:chatmcp/provider/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:chatmcp/llm/model.dart';
import 'dart:convert';
import 'package:chatmcp/widgets/collapsible_section.dart';
import 'package:chatmcp/widgets/markdown/markit_widget.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:io' as io;
import 'package:chatmcp/utils/color.dart';
import 'package:chatmcp/utils/platform.dart';
import 'package:chatmcp/echo/echo_orb.dart';
import 'package:chatmcp/echo/echo_theme.dart';
import 'chat_message_action.dart';
import 'package:chatmcp/generated/app_localizations.dart';
import 'chat_loading.dart';

/// Document attachment component is used to display the file attachment in the chat message.
///
/// - [path] The path of the file
/// - [name] The name of the file
/// - [fileType] The type of the file
class FileAttachment extends StatelessWidget {
  final String path;
  final String name;
  final String fileType;

  const FileAttachment({super.key, required this.path, required this.name, required this.fileType});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(color: AppColors.getFileAttachmentBackgroundColor(context), borderRadius: BorderRadius.circular(16)),
      child: fileType.startsWith('image') ? _buildImagePreview(context) : _buildFilePreview(),
    );
  }

  Widget _buildImagePreview(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6, maxHeight: 300),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          io.File(path),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.getFileAttachmentBackgroundColor(context), borderRadius: BorderRadius.circular(8)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.broken_image, color: AppColors.getImageErrorIconColor(context), size: 32),
                  Text(l10n.brokenImage),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilePreview() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.attach_file, size: 16),
        const SizedBox(width: 4),
        Flexible(
          child: Text(name, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis, maxLines: 1),
        ),
      ],
    );
  }
}

/// Message long press menu is used to display the long press menu in the chat message.
///
/// - [message] The message
/// - [onRetry] The function to retry the message
class MessageLongPressMenu extends StatelessWidget {
  final ChatMessage message;
  final Function(ChatMessage) onRetry;

  const MessageLongPressMenu({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.copy_outlined),
          title: Text(l10n.copy),
          onTap: () {
            Clipboard.setData(ClipboardData(text: message.content ?? ''));
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.copied), duration: const Duration(seconds: 2)));
          },
        ),
        if (message.role != MessageRole.user)
          ListTile(
            leading: const Icon(Icons.refresh),
            title: Text(l10n.retry),
            onTap: () {
              Navigator.pop(context);
              onRetry(message);
            },
          ),
      ],
    );
  }
}

/// Chat UI message is used to display the chat message in the chat page.
///
/// - [messages] The list of messages
/// - [onRetry] The function to retry the message
/// - [onSwitch] The function to switch the message
class ChatUIMessage extends StatelessWidget {
  final List<ChatMessage> messages;
  final Function(ChatMessage) onRetry;
  final Function(String messageId) onSwitch;

  const ChatUIMessage({super.key, required this.messages, required this.onRetry, required this.onSwitch});

  List<ChatMessage> _filterMessages(List<ChatMessage> messages) {
    if (messages.length <= 1) return messages;
    return messages.where((m) => m.role != MessageRole.assistant || (m.role == MessageRole.assistant && m.content != '')).toList();
  }

  BubblePosition _getMessagePosition(int index, int total) {
    if (total == 1) return BubblePosition.single;
    if (index == 0) return BubblePosition.first;
    if (index == total - 1) return BubblePosition.last;
    return BubblePosition.middle;
  }

  Widget _buildMessageGroup(BuildContext context, List<ChatMessage> messages, bool isUser) {
    final filteredMessages = _filterMessages(messages);
    if (filteredMessages.isEmpty) return const SizedBox();

    if (filteredMessages.length == 1) {
      return ChatMessageContent(
        key: ValueKey(filteredMessages[0].messageId),
        message: filteredMessages[0],
        onRetry: onRetry,
        position: BubblePosition.single,
      );
    }

    // Mobile Echo: each bubble is independent â€” no group container
    if (kIsMobile) {
      return Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: List.generate(filteredMessages.length, (index) {
          final pos = index == 0
              ? BubblePosition.first
              : index == filteredMessages.length - 1
              ? BubblePosition.last
              : BubblePosition.middle;
          return ChatMessageContent(
            key: ValueKey(filteredMessages[index].messageId),
            message: filteredMessages[index],
            onRetry: onRetry,
            position: pos,
          );
        }),
      );
    }

    return Container(
      decoration: BoxDecoration(color: AppColors.getMessageBubbleBackgroundColor(context, isUser), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: List.generate(
          filteredMessages.length,
          (index) => Padding(
            padding: EdgeInsets.only(bottom: index == filteredMessages.length - 1 ? 0 : 1),
            child: ChatMessageContent(
              key: ValueKey(filteredMessages[index].messageId),
              message: filteredMessages[index],
              onRetry: onRetry,
              position: _getMessagePosition(index, filteredMessages.length),
              useTransparentBackground: true,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) return const SizedBox();

    final firstMsg = messages.first;
    final isUser = firstMsg.role == MessageRole.user;

    // Mobile Echo layout: EchoOrb for AI, no user avatar, clean margins
    if (kIsMobile) {
      // AI messages: bubble stays constrained, action strip is full-width outside
      if (!isUser) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const EchoOrb(size: 28, rings: 1),
                  const SizedBox(width: 8),
                  Flexible(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 278),
                      child: _buildMessageGroup(context, messages, false),
                    ),
                  ),
                ],
              ),
              if (messages.last.role != MessageRole.loading)
                MessageActions(messages: messages, onRetry: onRetry, onSwitch: onSwitch, isUser: false),
            ],
          ),
        );
      }
      // User messages: keep compact column inside constraint
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 278),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildMessageGroup(context, messages, true),
                    if (messages.last.role != MessageRole.loading)
                      MessageActions(messages: messages, onRetry: onRetry, onSwitch: onSwitch, isUser: true),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        final showAssistantAvatar = settings.generalSetting.showAssistantAvatar;
        final showUserAvatar = settings.generalSetting.showUserAvatar;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser && showAssistantAvatar) ...[SizedBox(width: 40, child: ChatAvatar(isUser: false)), const SizedBox(width: 8)],
              Flexible(
                child: Column(
                  crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    _buildMessageGroup(context, messages, isUser),
                    if (messages.last.role != MessageRole.loading)
                      MessageActions(messages: messages, onRetry: onRetry, onSwitch: onSwitch, isUser: isUser),
                  ],
                ),
              ),
              if (isUser && showUserAvatar) ...[const SizedBox(width: 8), SizedBox(width: 40, child: ChatAvatar(isUser: true))],
            ],
          ),
        );
      },
    );
  }
}

/// Chat message content is used to display the chat message content in the chat message.
///
/// - [message] The message
/// - [onRetry] The function to retry the message
/// - [position] The position of the message
/// - [useTransparentBackground] Whether to use transparent background
class ChatMessageContent extends StatelessWidget {
  final ChatMessage message;
  final Function(ChatMessage) onRetry;
  final BubblePosition position;
  final bool useTransparentBackground;

  const ChatMessageContent({
    super.key,
    required this.message,
    required this.onRetry,
    this.position = BubblePosition.single,
    this.useTransparentBackground = false,
  });

  Widget _buildMessage(BuildContext context) {
    final messages = <Widget>[];

    if (message.role == MessageRole.loading) {
      messages.add(const ChatLoading());
    }

    if (message.files != null && message.files!.isNotEmpty) {
      messages.add(
        Container(
          margin: const EdgeInsets.fromLTRB(0, 8, 0, 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: message.files!.map((file) => FileAttachment(path: file.path!, name: file.name, fileType: file.fileType)).toList(),
          ),
        ),
      );
    }
    final bubbleKey = message.messageId;
    if ((message.role == MessageRole.user || message.role == MessageRole.assistant) && message.content != null) {
      messages.add(
        MessageBubble(
          key: ValueKey('${bubbleKey}_content'),
          message: message,
          position: position,
          useTransparentBackground: useTransparentBackground,
        ),
      );
    }

    if (message.toolCalls != null && message.toolCalls!.isNotEmpty) {
      messages.add(
        MessageBubble(
          key: ValueKey('${bubbleKey}_tool_calls'),
          message: message,
          position: position,
          useTransparentBackground: useTransparentBackground,
        ),
      );
    }

    if (message.role == MessageRole.tool && message.toolCallId != null) {
      messages.add(
        MessageBubble(
          key: ValueKey('${bubbleKey}_tool_result'),
          message: message,
          position: position,
          useTransparentBackground: useTransparentBackground,
        ),
      );
    }

    return Column(crossAxisAlignment: message.role == MessageRole.user ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: messages);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          builder: (context) => MessageLongPressMenu(message: message, onRetry: onRetry),
        );
      },
      child: _buildMessage(context),
    );
  }
}

/// Bubble position is used to determine the position of the bubble in the chat message.
///
/// - [first] The first bubble
/// - [middle] The middle bubble
/// - [last] The last bubble
/// - [single] The single bubble
enum BubblePosition { first, middle, last, single }

/// Message bubble is used to display the message bubble in the chat message.
///
/// - [message] The message
/// - [position] The position of the message
/// - [useTransparentBackground] Whether to use transparent background
class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final BubblePosition position;
  final bool useTransparentBackground;

  const MessageBubble({super.key, required this.message, this.position = BubblePosition.single, this.useTransparentBackground = false});

  BorderRadius _getBorderRadius() {
    const double radius = 16.0;

    switch (position) {
      case BubblePosition.first:
        return const BorderRadius.only(topLeft: Radius.circular(radius), topRight: Radius.circular(radius));
      case BubblePosition.middle:
        return BorderRadius.zero;
      case BubblePosition.last:
        return const BorderRadius.only(bottomLeft: Radius.circular(radius), bottomRight: Radius.circular(radius));
      case BubblePosition.single:
        return const BorderRadius.all(Radius.circular(radius));
    }
  }

  EdgeInsets _getMargin() {
    switch (position) {
      case BubblePosition.first:
        return EdgeInsets.zero;
      case BubblePosition.middle:
        return EdgeInsets.zero;
      case BubblePosition.last:
        return const EdgeInsets.only(bottom: 8);
      case BubblePosition.single:
        return const EdgeInsets.only(bottom: 8);
    }
  }

  EdgeInsets _getPadding() {
    const double horizontal = 16.0;
    const double verticalNormal = 10.0;

    switch (position) {
      case BubblePosition.first:
        return const EdgeInsets.only(left: horizontal, right: horizontal, top: verticalNormal, bottom: 0);
      case BubblePosition.middle:
        return const EdgeInsets.symmetric(horizontal: horizontal, vertical: 0);
      case BubblePosition.last:
        return const EdgeInsets.only(left: horizontal, right: horizontal, top: 0, bottom: verticalNormal);
      case BubblePosition.single:
        return const EdgeInsets.symmetric(horizontal: horizontal, vertical: verticalNormal);
    }
  }

  BorderRadius _getEchoBorderRadius(bool isUser) {
    if (isUser) {
      return switch (position) {
        BubblePosition.single => const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(3),
        ),
        BubblePosition.first => const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        BubblePosition.middle => const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(3),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(3),
        ),
        BubblePosition.last => const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(3),
        ),
      };
    }
    return switch (position) {
      BubblePosition.single => const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
        bottomLeft: Radius.circular(3),
        bottomRight: Radius.circular(16),
      ),
      BubblePosition.first => const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
        bottomLeft: Radius.circular(16),
        bottomRight: Radius.circular(16),
      ),
      BubblePosition.middle => const BorderRadius.only(
        topLeft: Radius.circular(3),
        topRight: Radius.circular(16),
        bottomLeft: Radius.circular(3),
        bottomRight: Radius.circular(16),
      ),
      BubblePosition.last => const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
        bottomLeft: Radius.circular(3),
        bottomRight: Radius.circular(16),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;

    // â”€â”€ Mobile Echo styling â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    if (kIsMobile) {
      // Loading indicator
      if (message.role == MessageRole.loading) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: EchoColors.bgChatAI,
            border: Border.all(color: EchoColors.borderCard),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(3),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: const ChatLoading(),
        );
      }
      // Tool call/result â€” quiet pill
      if ((message.toolCalls != null && message.toolCalls!.isNotEmpty) || message.role == MessageRole.tool) {
        final label = message.role == MessageRole.tool ? 'done' : (message.toolCalls![0]['function']['name'] as String).replaceAll('_', ' ');
        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: EchoColors.softSurface,
            border: Border.all(color: EchoColors.borderSubtle),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(message.role == MessageRole.tool ? Icons.check_circle_outline : Icons.build_outlined, size: 13, color: EchoColors.textMuted),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 11.5, color: EchoColors.textMuted)),
            ],
          ),
        );
      }
      if (message.content == null || message.content!.isEmpty) return const SizedBox.shrink();
      return Container(
        margin: _getMargin(),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isUser ? EchoColors.bgChatUser : EchoColors.bgChatAI,
          border: Border.all(color: isUser ? EchoColors.bgChatUser : EchoColors.borderCard),
          borderRadius: _getEchoBorderRadius(isUser),
        ),
        child: isUser
            ? DefaultTextStyle(
                style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.45),
                child: Markit(data: message.content!.trim()),
              )
            : Markit(data: message.content!.trim()),
      );
    }

    // â”€â”€ Desktop styling â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    Widget child = const Text('');
    if (message.content != null) {
      if (message.role == MessageRole.user) {
        child = Markit(data: (message.content!).trim());
      } else {
        child = Markit(data: (message.content!).trim());
        if (message.tokenUsage != null) {
          child = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              child,
              const SizedBox(height: 4),
              ExpansionTile(
                title: const Text('Token Usage', style: TextStyle(fontSize: 12)),
                controlAffinity: ListTileControlAffinity.leading,
                children: <Widget>[ListTile(title: Markit(data: message.tokenUsage!.toMarkdown()))],
              ),
            ],
          );
        }
      }
    }
    return Container(
      margin: _getMargin(),
      padding: _getPadding(),
      decoration: BoxDecoration(
        color: useTransparentBackground ? Colors.transparent : AppColors.getMessageBubbleBackgroundColor(context, message.role == MessageRole.user),
        borderRadius: _getBorderRadius(),
      ),
      child: child,
    );
  }
}

/// Tool call widget is used to display the tool call in the chat message.
///
/// - [message] The message
class ToolCallWidget extends StatelessWidget {
  final ChatMessage message;

  const ToolCallWidget({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: CollapsibleSection(
        initiallyExpanded: false,
        title: Text(
          l10n.toolCall(message.toolCalls![0]['function']['name']),
          style: TextStyle(fontSize: 12, color: AppColors.getToolCallTextColor(), fontStyle: FontStyle.italic),
        ),
        content: Markit(
          data: (message.toolCalls?.isNotEmpty ?? false)
              ? [
                  '```json',
                  const JsonEncoder.withIndent('  ').convert({
                    "name": message.toolCalls![0]['function']['name'],
                    "arguments": json.decode(message.toolCalls![0]['function']['arguments']),
                  }),
                  '```',
                ].join('\n')
              : '',
        ),
      ),
    );
  }
}

/// Tool result widget is used to display the tool result in the chat message.
///
/// - [message] The message
class ToolResultWidget extends StatelessWidget {
  final ChatMessage message;

  const ToolResultWidget({super.key, required this.message});

  Widget _buildContent(BuildContext context) {
    return SelectableText(message.content ?? '');
  }

  Widget _buildFactory(BuildContext context) {
    switch (message.toolCallId) {
      case 'call_web_search':
        return Markit(data: message.content ?? '');
      case 'call_generate_image':
        try {
          final jsonData = json.decode(message.content ?? '');
          return Markit(data: "```json\n${const JsonEncoder.withIndent('  ').convert(jsonData)}\n```");
        } catch (e) {
          return Markit(data: "```\n${message.content}\n```");
        }
      default:
        return _buildContent(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: CollapsibleSection(
        initiallyExpanded: false,
        title: Text(
          l10n.toolResult(message.toolCallId!.replaceFirst('call_', '')),
          style: TextStyle(fontSize: 12, color: AppColors.getToolCallTextColor(), fontStyle: FontStyle.italic),
        ),
        content: _buildFactory(context),
      ),
    );
  }
}

/// Chat avatar is used to display the chat avatar in the chat message.
///
/// - [isUser] Whether the avatar is for the user
class ChatAvatar extends StatelessWidget {
  final bool isUser;

  const ChatAvatar({super.key, required this.isUser});

  @override
  Widget build(BuildContext context) {
    if (kIsMobile) {
      return isUser ? const SizedBox.shrink() : const EchoOrb(size: 28, rings: 1);
    }
    return CircleAvatar(
      backgroundColor: AppColors.getChatAvatarBackgroundColor(),
      child: Icon(isUser ? Icons.person : Icons.android, color: AppColors.getChatAvatarIconColor()),
    );
  }
}
