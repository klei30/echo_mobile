import 'package:flutter/material.dart';
import 'package:chatmcp/llm/model.dart';
import 'package:flutter/services.dart';
import 'package:chatmcp/utils/color.dart';
import 'package:chatmcp/generated/app_localizations.dart';
import 'package:chatmcp/echo/echo_client.dart';
import 'package:chatmcp/echo/echo_loop_state.dart';
import 'package:chatmcp/echo/echo_theme.dart';
import 'package:chatmcp/page/echo_tabs/shadow_tournament_screen.dart';

class MessageActions extends StatefulWidget {
  final List<ChatMessage> messages;
  final Function(ChatMessage) onRetry;
  final Function(String messageId) onSwitch;
  final bool isUser;

  const MessageActions({
    super.key,
    required this.messages,
    required this.onRetry,
    required this.onSwitch,
    this.isUser = false,
  });

  @override
  State<MessageActions> createState() => _MessageActionsState();
}

class _MessageActionsState extends State<MessageActions> {
  int _thumbState = 0; // 0=none, 1=thumbs_up, -1=thumbs_down

  void _sendFeedback(String signal) {
    final content = widget.messages.last.content ?? '';
    if (content.isEmpty) return;
    EchoClient().sendFeedback(assistantMessage: content, signal: signal);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: EchoColors.bgCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          signal == 'not_true' || signal == 'thumbs_down'
              ? 'Correction saved. Echo will adjust.'
              : 'Signal saved. Echo updated the loop.',
          style: const TextStyle(fontSize: 12.5, color: EchoColors.textMuted),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                iconSize: 14,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                icon: const Icon(Icons.copy_outlined),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: widget.messages.map((m) => m.content ?? '').join('\n')));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(t.copiedToClipboard), duration: const Duration(seconds: 2)),
                  );
                },
              ),
              if (!widget.isUser) ...[
                IconButton(
                  iconSize: 14,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                  icon: Icon(
                    _thumbState == 1 ? Icons.thumb_up : Icons.thumb_up_outlined,
                    color: _thumbState == 1 ? Colors.green : null,
                  ),
                  tooltip: 'Good response',
                  onPressed: () {
                    setState(() => _thumbState = _thumbState == 1 ? 0 : 1);
                    if (_thumbState == 1) _sendFeedback('thumbs_up');
                  },
                ),
                IconButton(
                  iconSize: 14,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                  icon: Icon(
                    _thumbState == -1 ? Icons.thumb_down : Icons.thumb_down_outlined,
                    color: _thumbState == -1 ? Colors.red : null,
                  ),
                  tooltip: 'Bad response',
                  onPressed: () {
                    setState(() => _thumbState = _thumbState == -1 ? 0 : -1);
                    if (_thumbState == -1) _sendFeedback('thumbs_down');
                  },
                ),
              ],
              if (!widget.isUser)
                IconButton(
                  iconSize: 14,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                  icon: const Icon(Icons.refresh),
                  onPressed: () => widget.onRetry(widget.messages.last),
                  tooltip: t.retry,
                ),
              if (!widget.isUser &&
                  widget.messages.first.brotherMessageIds != null &&
                  widget.messages.first.brotherMessageIds!.isNotEmpty)
                _buildBranchSwitchWidget(widget.messages),
            ],
          ),
          if (!widget.isUser) _buildLoopChips(context),
        ],
      ),
    );
  }

  Widget _buildLoopChips(BuildContext context) {
    final content = widget.messages.last.content ?? '';
    if (content.isEmpty) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: EchoLoopState(),
      builder: (context, _) {
        final priority = EchoLoopState().todayPriority;
        final action = priority?['action'] is Map
            ? Map<String, dynamic>.from(priority!['action'] as Map)
            : <String, dynamic>{};
        final payload = action['payload'] is Map
            ? Map<String, dynamic>.from(action['payload'] as Map)
            : <String, dynamic>{};
        final priorityPrompt = payload['prompt'] as String?;
        final fallbackPrompt = EchoClient().lastUserMessage;
        final prompt = priorityPrompt?.isNotEmpty == true
            ? priorityPrompt!
            : (fallbackPrompt?.isNotEmpty == true
                ? fallbackPrompt!
                : content.substring(0, content.length.clamp(0, 500)));

        return Padding(
          padding: const EdgeInsets.only(top: 2, bottom: 2),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _loopChip(
                context,
                Icons.military_tech_rounded,
                'Send clones',
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ShadowTournamentScreen(initialPrompt: prompt),
                  ),
                ),
                filled: action['type'] == 'run_tournament',
              ),
              _loopChip(context, Icons.check_circle_outline_rounded, 'This helped', () => _sendFeedback('helped')),
              _loopChip(context, Icons.cancel_outlined, 'Not true', () => _sendFeedback('not_true')),
              _loopChip(context, Icons.bookmark_add_outlined, 'Save signal', () => _sendFeedback('saved_signal')),
              _loopChip(context, Icons.bolt_outlined, 'Turn into rep', () => _sendFeedback('practice_request')),
            ],
          ),
        );
      },
    );
  }

  Widget _loopChip(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool filled = false,
  }) {
    final color = filled ? EchoColors.amber : AppColors.getThemeColor(context);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: filled ? 0.18 : 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: filled ? 0.45 : 0.16)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBranchSwitchWidget(List<ChatMessage> messages) {
    int index = messages.first.brotherMessageIds!.indexOf(messages.first.messageId) + 1;
    int length = messages.first.brotherMessageIds!.length;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          iconSize: 14,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
          icon: Icon(Icons.arrow_back_ios, size: 12, color: index == 1 ? AppColors.getMessageBranchDisabledColor() : null),
          onPressed: index == 1
              ? null
              : () {
                  widget.onSwitch(messages.first.brotherMessageIds![index - 2]);
                },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text('$index/$length', style: TextStyle(fontSize: 12, color: AppColors.getMessageBranchIndicatorTextColor())),
        ),
        IconButton(
          iconSize: 14,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
          icon: Icon(Icons.arrow_forward_ios, size: 12, color: index == length ? AppColors.getMessageBranchDisabledColor() : null),
          onPressed: index == length
              ? null
              : () {
                  widget.onSwitch(messages.first.brotherMessageIds![index]);
                },
        ),
      ],
    );
  }
}
