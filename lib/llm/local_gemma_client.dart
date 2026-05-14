import 'package:chatmcp/echo/local_gemma_service.dart';
import 'package:chatmcp/llm/base_llm_client.dart';
import 'package:chatmcp/llm/model.dart';

class LocalGemmaClient extends BaseLLMClient {
  LocalGemmaClient();

  @override
  Future<LLMResponse> chatCompletion(CompletionRequest request) async {
    final buffer = StringBuffer();
    await for (final chunk in chatStreamCompletion(request)) {
      if (chunk.content != null) buffer.write(chunk.content);
    }
    return LLMResponse(content: buffer.toString());
  }

  @override
  Stream<LLMResponse> chatStreamCompletion(CompletionRequest request) async* {
    final prompt = _fitPrompt(_toPrompt(request.messages));
    final requestedMaxTokens = request.modelSetting?.maxTokens ?? 512;
    final maxTokens = requestedMaxTokens.clamp(96, 384).toInt();
    final temperature = request.modelSetting?.temperature ?? 0.7;

    await for (final token in LocalGemmaService().generate(
      prompt: prompt,
      maxTokens: maxTokens,
      temperature: temperature,
    )) {
      yield LLMResponse(content: token);
    }
  }

  @override
  Future<List<String>> models() async => const ['gemma_on_device'];

  String _toPrompt(List<ChatMessage> messages) {
    final buffer = StringBuffer();
    for (final message in messages) {
      final content = message.content?.trim();
      if (content == null || content.isEmpty) continue;

      final role = switch (message.role) {
        MessageRole.system => 'System',
        MessageRole.user => 'User',
        MessageRole.assistant => 'Assistant',
        MessageRole.tool => 'Tool',
        MessageRole.function => 'Tool',
        MessageRole.error => 'System',
        MessageRole.loading => 'System',
      };
      buffer.writeln('$role: $content');
    }
    buffer.write('Assistant:');
    return buffer.toString();
  }

  String _fitPrompt(String prompt) {
    // LiteRT-LM Gemma 4 E2B is initialized with a 2048-token window on
    // Android. Keep the text budget conservative because Dart does not have
    // the model tokenizer here, and system + output tokens share the limit.
    const maxChars = 3200;
    if (prompt.length <= maxChars) return prompt;

    final firstUser = prompt.indexOf('\nUser:');
    final systemHead = firstUser > 0 ? prompt.substring(0, firstUser).trimRight() : '';
    final assistantMarker = prompt.lastIndexOf('\nAssistant:');
    final lastUserMarker = prompt.lastIndexOf('\nUser:');
    final tailStart = lastUserMarker >= 0
        ? lastUserMarker
        : assistantMarker >= 0
            ? assistantMarker
            : (prompt.length - maxChars).clamp(0, prompt.length).toInt();
    final tail = prompt.substring(tailStart).trimLeft();
    final systemBudget = systemHead.isEmpty ? 0 : 1200;
    final clippedSystem = systemHead.length <= systemBudget ? systemHead : systemHead.substring(0, systemBudget).trimRight();
    final notice = 'System: Older Echo context and conversation turns were shortened for the on-device model.';
    final tailBudget = maxChars - clippedSystem.length - notice.length - 4;
    final clippedTail = tail.length <= tailBudget ? tail : tail.substring(tail.length - tailBudget).trimLeft();

    return [
      if (clippedSystem.isNotEmpty) clippedSystem,
      notice,
      clippedTail,
    ].join('\n\n');
  }
}
