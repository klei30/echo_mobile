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
    final maxTokens = request.modelSetting?.maxTokens ?? 512;
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
    const maxChars = 6200;
    if (prompt.length <= maxChars) return prompt;

    final assistantMarker = prompt.lastIndexOf('Assistant:');
    final tail = assistantMarker >= 0 ? prompt.substring(assistantMarker) : 'Assistant:';
    final headBudget = maxChars - tail.length - 80;
    if (headBudget <= 0) return tail;

    return '${prompt.substring(0, headBudget).trimRight()}\n\nSystem: Older context was shortened for the on-device model.\n$tail';
  }
}
