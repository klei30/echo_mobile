import 'package:chatmcp/llm/openai_client.dart';

class CopilotClient extends OpenAIClient {
  CopilotClient({required super.apiKey}) : super(baseUrl: 'https://api.githubcopilot.com');
}
