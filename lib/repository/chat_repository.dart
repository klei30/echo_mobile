import 'package:chatmcp/dao/chat.dart';
import 'package:chatmcp/llm/model.dart';
import 'package:chatmcp/config/pagination_config.dart';

class ChatListResult {
  final List<Chat> chats;
  final int total;
  final bool hasMore;

  ChatListResult({required this.chats, required this.total, required this.hasMore});
}

abstract class ChatRepository {
  Future<ChatListResult> getChats({
    int page = 1, // 页码从 1 开始，符合常规分页概念
    int pageSize = PaginationConfig.defaultPageSize,
    String? searchKeyword,
  });
  Future<Chat?> getChatById(int id);
  Future<Chat> createChat(Chat chat, List<ChatMessage> messages);
  Future<void> updateChat(Chat chat);
  Future<void> deleteChat(int id);
  Future<void> addChatMessage(int chatId, List<ChatMessage> messages);
  Future<List<ChatMessage>> getChatMessages(int chatId);

  @Deprecated('Use getChats() instead')
  Future<List<Chat>> getAllChats() async {
    final result = await getChats(pageSize: PaginationConfig.maxPageSize);
    return result.chats;
  }
}
