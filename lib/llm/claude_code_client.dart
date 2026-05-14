import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';

import 'base_llm_client.dart';
import 'model.dart';

/// Claude Code client backed by the `claude` CLI.
///
/// This client shells out to the Claude Code SDK CLI, so it works without
/// directly using Anthropic HTTP APIs. It expects the `claude` binary to be
/// available on PATH (or via a configured absolute path), and that the user
/// has already authenticated per Claude Code SDK docs.
///
/// Non-goals:
/// - Tool calling is not wired, as Claude Code has its own tool system
///   (Read/Write/Bash). We ignore `tools` in requests.
class ClaudeCodeClient extends BaseLLMClient {
  /// Path or name of the Claude Code CLI executable. Defaults to `claude`.
  final String executable;

  ClaudeCodeClient({String? executablePath}) : executable = (executablePath == null || executablePath.isEmpty) ? 'claude' : executablePath;

  @override
  Future<LLMResponse> chatCompletion(CompletionRequest request) async {
    final prompt = _buildPromptFromMessages(request.messages);

    // Use JSON output for reliable parsing
    final args = <String>['-p', prompt, '--output-format', 'json'];

    try {
      final result = await Process.run(executable, args, runInShell: true);

      if (result.exitCode != 0) {
        throw Exception(
          result.stderr is String && (result.stderr as String).isNotEmpty ? result.stderr : 'Claude Code CLI exited with ${result.exitCode}',
        );
      }

      final output = result.stdout is String ? result.stdout as String : utf8.decode((result.stdout as List<int>));
      final content = _parseClaudeCodeJsonOutput(output);
      return LLMResponse(content: content);
    } catch (e) {
      // Surface a structured error via BaseLLMClient.handleError contract
      throw await handleError(e, 'Claude Code', executable, jsonEncode({'args': args}));
    }
  }

  @override
  Stream<LLMResponse> chatStreamCompletion(CompletionRequest request) async* {
    final prompt = _buildPromptFromMessages(request.messages);

    // Stream JSON lines so we can emit partial updates when possible.
    final args = <String>['-p', prompt, '--output-format', 'stream-json'];

    Process? process;
    try {
      process = await Process.start(executable, args, runInShell: true);

      final stdoutLines = process.stdout.transform(utf8.decoder).transform(const LineSplitter());
      final stderrBuffer = StringBuffer();

      // Drain stderr to help debugging on failure
      unawaited(process.stderr.transform(utf8.decoder).forEach(stderrBuffer.write));

      String aggregated = '';

      await for (final line in stdoutLines) {
        // Expecting JSONL objects, one per line
        try {
          final obj = jsonDecode(line);
          final type = obj['type'];
          if (type == 'assistant') {
            final contentPiece = _extractTextFromAssistantMessage(obj['message']);
            if (contentPiece.isNotEmpty) {
              aggregated += contentPiece;
              yield LLMResponse(content: contentPiece);
            }
          } else if (type == 'result') {
            // Final result line; emit any missing content if stream lacked assistant pieces
            final resultText = (obj['result'] ?? '').toString();
            if (aggregated.isEmpty && resultText.isNotEmpty) {
              yield LLMResponse(content: resultText);
            }
          }
        } catch (_) {
          // If a line isn't valid JSON, ignore it; CLI may print logs in verbose modes
          continue;
        }
      }

      final exitCode = await process.exitCode;
      if (exitCode != 0) {
        throw Exception(stderrBuffer.isNotEmpty ? stderrBuffer.toString() : 'Claude Code CLI exited with $exitCode');
      }
    } catch (e) {
      throw await handleError(e, 'Claude Code', executable, jsonEncode({'args': args}));
    } finally {
      // Ensure process is killed if still alive
      if (process != null) {
        try {
          process.kill(ProcessSignal.sigterm);
        } catch (_) {}
      }
    }
  }

  @override
  Future<List<String>> models() async {
    // Claude Code CLI does not expose a model listing endpoint.
    // Return a common set; users can customize in settings.
    return <String>['claude-3-7-sonnet', 'claude-3-opus', 'claude-3-5-sonnet', 'claude-3-5-haiku'];
  }

  String _buildPromptFromMessages(List<ChatMessage> messages) {
    // Keep recent context small to avoid overly long shell args.
    const int maxMessages = 12;
    final recent = messages.length <= maxMessages ? messages : messages.sublist(messages.length - maxMessages);

    final buffer = StringBuffer();
    for (final m in recent) {
      final content = (m.content ?? '').trim();
      if (content.isEmpty) continue;
      switch (m.role) {
        case MessageRole.system:
          buffer.writeln('System: $content');
          break;
        case MessageRole.user:
          buffer.writeln('User: $content');
          break;
        case MessageRole.assistant:
          buffer.writeln('Assistant: $content');
          break;
        default:
          // Ignore tool/function/error/loading in prompt for Claude Code
          break;
      }
    }
    return buffer.toString().trim();
  }

  /// Parse JSON output from `claude -p --output-format json`.
  /// The CLI typically prints a single JSON object. If multiple JSONL lines
  /// are present, prefer the final `result` type; otherwise accumulate
  /// assistant messages.
  String _parseClaudeCodeJsonOutput(String output) {
    output = output.trim();
    if (output.isEmpty) return '';

    // Try strict JSON first
    try {
      final obj = jsonDecode(output);
      final type = obj is Map<String, dynamic> ? obj['type'] : null;
      if (type == 'result') {
        return (obj['result'] ?? '').toString();
      }
      if (type == 'assistant') {
        return _extractTextFromAssistantMessage(obj['message']);
      }
      // Some versions might output a flat object with `result`
      if (obj is Map<String, dynamic> && obj.containsKey('result')) {
        return (obj['result'] ?? '').toString();
      }
    } catch (_) {
      // Fall through to JSONL mode
    }

    // Fallback: parse line-by-line as JSONL
    String aggregated = '';
    for (final line in const LineSplitter().convert(output)) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      try {
        final obj = jsonDecode(trimmed);
        final type = obj['type'];
        if (type == 'assistant') {
          aggregated += _extractTextFromAssistantMessage(obj['message']);
        } else if (type == 'result') {
          if (aggregated.isEmpty) {
            aggregated = (obj['result'] ?? '').toString();
          }
        }
      } catch (_) {
        continue;
      }
    }
    return aggregated;
  }

  /// Extract plain text from an Anthropic SDK `Message` object
  /// produced by Claude Code CLI JSON messages.
  String _extractTextFromAssistantMessage(dynamic messageObj) {
    if (messageObj == null) return '';
    try {
      final content = messageObj['content'];
      if (content is List) {
        final texts = <String>[];
        for (final part in content) {
          if (part is Map<String, dynamic>) {
            final type = part['type'];
            if (type == 'text' && part['text'] is String) {
              texts.add(part['text'] as String);
            }
          }
        }
        return texts.join('');
      }
    } catch (e) {
      Logger.root.fine('Failed to parse assistant message content: $e');
    }
    return '';
  }
}
