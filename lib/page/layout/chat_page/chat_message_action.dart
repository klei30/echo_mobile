import 'package:flutter/material.dart';
import 'package:chatmcp/llm/model.dart';
import 'package:flutter/services.dart';
import 'package:chatmcp/utils/color.dart';
import 'package:chatmcp/generated/app_localizations.dart';
import 'package:chatmcp/echo/echo_client.dart';

class MessageActions extends StatefulWidget {
  final List<ChatMessage> messages;
  final Function(ChatMessage) onRetry;
  final Function(String messageId) onSwitch;
  final bool isUser;

  const MessageActions({super.key, required this.messages, required this.onRetry, required this.onSwitch, this.isUser = false});

  @override
  State<MessageActions> createState() => _MessageActionsState();
}

class _MessageActionsState extends State<MessageActions> {
  int _thumbState = 0; // 0=none, 1=thumbs_up, -1=thumbs_down

  void _sendFeedback(String signal) {
    final content = widget.messages.last.content ?? '';
    if (content.isEmpty) return;
    EchoClient().sendFeedback(assistantMessage: content, signal: signal);
  }

  @override
  Widget build(BuildContext context) {
    var t = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Copy button
          IconButton(
            iconSize: 14,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
            icon: const Icon(Icons.copy_outlined),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: widget.messages.map((m) => m.content ?? '').join('\n')));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.copiedToClipboard), duration: const Duration(seconds: 2)));
            },
          ),
          // Thumbs up/down — only for assistant messages, sends Echo feedback
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
          // Retry button
          if (!widget.isUser)
            IconButton(
              iconSize: 14,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              icon: const Icon(Icons.refresh),
              onPressed: () => widget.onRetry(widget.messages.last),
              tooltip: t.retry,
            ),
          // Branch switch
          if (!widget.isUser && widget.messages.first.brotherMessageIds != null && widget.messages.first.brotherMessageIds!.isNotEmpty)
            _buildBranchSwitchWidget(widget.messages),
        ],
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
