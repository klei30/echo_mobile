import 'package:chatmcp/repository/chat_repository.dart';
import 'package:chatmcp/repository/local_chat_repository.dart';
import 'package:chatmcp/repository/remote_chat_repository.dart';

enum RepositoryType { local, remote }

class ChatRepositoryFactory {
  static ChatRepository create(RepositoryType type, {String? baseUrl, String? apiKey}) {
    switch (type) {
      case RepositoryType.local:
        return LocalChatRepository();
      case RepositoryType.remote:
        if (baseUrl == null || apiKey == null) {
          throw ArgumentError('Remote repository requires baseUrl and apiKey');
        }
        return RemoteChatRepository(baseUrl: baseUrl, apiKey: apiKey);
    }
  }
}

class ChatRepositoryProvider {
  static ChatRepository? _instance;
  static RepositoryType _currentType = RepositoryType.local;

  static ChatRepository get instance {
    return _instance ??= ChatRepositoryFactory.create(_currentType);
  }

  static void configure(RepositoryType type, {String? baseUrl, String? apiKey}) {
    _currentType = type;
    _instance = ChatRepositoryFactory.create(type, baseUrl: baseUrl, apiKey: apiKey);
  }

  static void reset() {
    _instance = null;
    _currentType = RepositoryType.local;
  }
}
