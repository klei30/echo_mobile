import 'package:chatmcp/dao/chat.dart';
import 'package:chatmcp/dao/chat_message.dart';
import 'package:chatmcp/echo/auth_service.dart';
import 'package:chatmcp/llm/model.dart';
import 'package:chatmcp/repository/chat_repository.dart';
import 'package:chatmcp/config/pagination_config.dart';

class LocalChatRepository implements ChatRepository {
  final ChatDao _chatDao = ChatDao();
  final ChatMessageDao _chatMessageDao = ChatMessageDao();

  String get _uid => AuthService().userId ?? 'anonymous';

  String _where(String? extra) =>
      extra != null ? '($extra) AND userId = ?' : 'userId = ?';

  List<Object?> _args(List<Object?>? extra) => [...(extra ?? []), _uid];

  @override
  Future<ChatListResult> getChats({
    int page = 1,
    int pageSize = PaginationConfig.defaultPageSize,
    String? searchKeyword,
  }) async {
    final offset = (page - 1) * pageSize;

    String? extraWhere;
    List<Object?>? extraArgs;

    if (searchKeyword != null && searchKeyword.isNotEmpty) {
      extraWhere = 'title LIKE ?';
      extraArgs = ['%$searchKeyword%'];
    }

    final whereClause = _where(extraWhere);
    final whereArgs = _args(extraArgs);

    final allChats = await _chatDao.query(where: whereClause, whereArgs: whereArgs);
    final total = allChats.length;

    final chats = await _chatDao.query(
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'updatedAt DESC',
      limit: pageSize,
      offset: offset,
    );

    final hasMore = offset + pageSize < total;

    return ChatListResult(chats: chats, total: total, hasMore: hasMore);
  }

  @override
  Future<List<Chat>> getAllChats() async {
    return await _chatDao.query(
      where: 'userId = ?',
      whereArgs: [_uid],
      orderBy: 'updatedAt DESC',
    );
  }

  @override
  Future<Chat?> getChatById(int id) async {
    final results = await _chatDao.query(
      where: 'id = ? AND userId = ?',
      whereArgs: [id, _uid],
    );
    return results.isEmpty ? null : results.first;
  }

  @override
  Future<Chat> createChat(Chat chat, List<ChatMessage> messages) async {
    final uid = _uid;
    final stamped = Chat(
      title: chat.title,
      userId: uid,
      createdAt: chat.createdAt,
      updatedAt: chat.updatedAt,
    );
    final chatId = await _chatDao.insert(stamped);
    final newChat = Chat(
      id: chatId,
      title: chat.title,
      userId: uid,
      createdAt: chat.createdAt,
      updatedAt: chat.updatedAt,
    );

    if (messages.isNotEmpty) {
      await addChatMessage(chatId, messages);
    }

    return newChat;
  }

  @override
  Future<void> updateChat(Chat chat) async {
    if (chat.id != null) {
      await _chatDao.update(chat, chat.id.toString());
    }
  }

  @override
  Future<void> deleteChat(int id) async {
    await _chatMessageDao.deleteMessages(id);
    await _chatDao.delete(id.toString());
  }

  @override
  Future<void> addChatMessage(int chatId, List<ChatMessage> messages) async {
    for (final message in messages) {
      if (message.role == MessageRole.error) {
        continue;
      }
      final existingMessages = await _chatMessageDao.query(where: 'messageId = ?', whereArgs: [message.messageId]);
      if (existingMessages.isNotEmpty) {
        continue;
      }
      await _chatMessageDao.insert(message.toDb(chatId));
    }
  }

  @override
  Future<List<ChatMessage>> getChatMessages(int chatId) async {
    final chatMessages = await _chatMessageDao.query(
      where: 'chatId = ?',
      whereArgs: [chatId],
      orderBy: 'createdAt ASC',
    );
    return chatMessages.map((e) => ChatMessage.fromDb(e)).toList();
  }

  /// Claims all chats with no userId for the currently logged-in user.
  /// Called once on login/startup so legacy chats aren't lost.
  Future<void> adoptOrphanChats() async {
    final db = await _chatDao.database;
    await db.rawUpdate('UPDATE chat SET userId = ? WHERE userId IS NULL', [_uid]);
  }
}
