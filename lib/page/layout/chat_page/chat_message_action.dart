import 'package:flutter/material.dart';
import 'package:chatmcp/llm/model.dart';
import 'package:flutter/services.dart';
import 'package:chatmcp/utils/color.dart';
import 'package:chatmcp/generated/app_localizations.dart';
import 'package:chatmcp/echo/echo_client.dart';
import 'package:chatmcp/echo/echo_design_system.dart';
import 'package:chatmcp/echo/echo_loop_state.dart';
import 'package:chatmcp/echo/echo_theme.dart';
import 'package:chatmcp/page/echo_tabs/ask_screen.dart';
import 'package:chatmcp/page/echo_tabs/memory_consent_sheet.dart';
import 'package:chatmcp/page/echo_tabs/outcome_capture_sheet.dart';

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: EchoColors.bgCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          signal == 'not_true' || signal == 'thumbs_down' ? 'Correction saved. Echo will adjust.' : 'Outcome saved. Echo updated Today.',
          style: TextStyle(fontSize: 12.5, color: EchoColors.textMuted),
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
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.copiedToClipboard), duration: const Duration(seconds: 2)));
                },
              ),
              if (!widget.isUser) ...[
                IconButton(
                  iconSize: 14,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                  icon: Icon(_thumbState == 1 ? Icons.thumb_up : Icons.thumb_up_outlined, color: _thumbState == 1 ? Colors.green : null),
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
                  icon: Icon(_thumbState == -1 ? Icons.thumb_down : Icons.thumb_down_outlined, color: _thumbState == -1 ? Colors.red : null),
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
              if (!widget.isUser && widget.messages.first.brotherMessageIds != null && widget.messages.first.brotherMessageIds!.isNotEmpty)
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
        final action = priority?['action'] is Map ? Map<String, dynamic>.from(priority!['action'] as Map) : <String, dynamic>{};
        final payload = action['payload'] is Map ? Map<String, dynamic>.from(action['payload'] as Map) : <String, dynamic>{};
        final priorityPrompt = payload['prompt'] as String?;
        final fallbackPrompt = EchoClient().lastUserMessage;
        final prompt = priorityPrompt?.isNotEmpty == true
            ? priorityPrompt!
            : (fallbackPrompt?.isNotEmpty == true ? fallbackPrompt! : content.substring(0, content.length.clamp(0, 500).toInt()));

        final snippet = content.substring(0, content.length.clamp(0, 700).toInt());
        return Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 5),
                child: Text(
                  'TURN THIS INTO ACTION',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: EchoColors.textMuted, letterSpacing: 0.9),
                ),
              ),
              EchoActionStrip(
                items: [
                  EchoActionStripItem(
                    icon: Icons.fitness_center_rounded,
                    label: 'Practice',
                    color: EchoColors.primaryAi,
                    onTap: () => OutcomeCaptureSheet.show(
                      context,
                      title: 'Practice this in real life?',
                      subjectType: 'chat_practice',
                      contextNote: snippet,
                      doneLabel: 'Practiced',
                      skippedLabel: 'Not useful',
                      createProof: true,
                      proofCategory: 'practice',
                      proofTitle: 'Talk practice outcome',
                    ),
                  ),
                  EchoActionStripItem(
                    icon: Icons.lock_outline_rounded,
                    label: 'Remember',
                    color: EchoColors.memory,
                    onTap: () => MemoryConsentSheet.show(context, proposedMemory: snippet, sourceType: 'talk_reply'),
                  ),
                  EchoActionStripItem(
                    icon: Icons.psychology_alt_rounded,
                    label: 'Decide',
                    color: EchoColors.proof,
                    filled: action['type'] == 'run_tournament',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AskScreen(initialQuestion: prompt))),
                  ),
                  EchoActionStripItem(
                    icon: Icons.fact_check_outlined,
                    label: 'Outcome',
                    color: EchoColors.practice,
                    onTap: () => OutcomeCaptureSheet.show(
                      context,
                      title: 'Did this help you take action?',
                      subjectType: 'chat_response',
                      contextNote: snippet,
                    ),
                  ),
                  EchoActionStripItem(
                    icon: Icons.inventory_2_outlined,
                    label: 'Proof',
                    color: EchoColors.opportunity,
                    onTap: () => OutcomeCaptureSheet.show(
                      context,
                      title: 'Save this as proof for You?',
                      subjectType: 'chat_response',
                      contextNote: snippet,
                      doneLabel: 'Add proof',
                      skippedLabel: 'Not proof',
                      createProof: true,
                      proofCategory: 'chat',
                      proofTitle: 'Talk answer saved as proof',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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
