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

  String _where(String? extra) => extra != null ? '($extra) AND userId = ?' : 'userId = ?';

  List<Object?> _args(List<Object?>? extra) => [...(extra ?? []), _uid];

  @override
  Future<ChatListResult> getChats({int page = 1, int pageSize = PaginationConfig.defaultPageSize, String? searchKeyword}) async {
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

    final chats = await _chatDao.query(where: whereClause, whereArgs: whereArgs, orderBy: 'updatedAt DESC', limit: pageSize, offset: offset);

    final hasMore = offset + pageSize < total;

    return ChatListResult(chats: chats, total: total, hasMore: hasMore);
  }

  @override
  Future<List<Chat>> getAllChats() async {
    return await _chatDao.query(where: 'userId = ?', whereArgs: [_uid], orderBy: 'updatedAt DESC');
  }

  @override
  Future<Chat?> getChatById(int id) async {
    final results = await _chatDao.query(where: 'id = ? AND userId = ?', whereArgs: [id, _uid]);
    return results.isEmpty ? null : results.first;
  }

  @override
  Future<Chat> createChat(Chat chat, List<ChatMessage> messages) async {
    final uid = _uid;
    final stamped = Chat(title: chat.title, userId: uid, createdAt: chat.createdAt, updatedAt: chat.updatedAt);
    final chatId = await _chatDao.insert(stamped);
    final newChat = Chat(id: chatId, title: chat.title, userId: uid, createdAt: chat.createdAt, updatedAt: chat.updatedAt);

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
    final chatMessages = await _chatMessageDao.query(where: 'chatId = ?', whereArgs: [chatId], orderBy: 'createdAt ASC');
    return chatMessages.map((e) => ChatMessage.fromDb(e)).toList();
  }

  /// Import conversation history from the Echo backend.
  /// Pairs are grouped by date → one Chat per date. MessageIds are deterministic
  /// so re-running this after logout/login never creates duplicates.
  Future<void> importHistory(List<Map<String, dynamic>> pairs) async {
    if (pairs.isEmpty) return;
    final Map<String, List<Map<String, dynamic>>> byDate = {};
    for (final pair in pairs) {
      final created = pair['created_at'] as String? ?? '';
      final date = created.length >= 10 ? created.substring(0, 10) : 'history';
      byDate.putIfAbsent(date, () => []).add(pair);
    }
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    for (final entry in byDate.entries) {
      final date = entry.key;
      final datePairs = entry.value;
      String title = date;
      try {
        final dt = DateTime.parse(date);
        title = '${months[dt.month - 1]} ${dt.day}';
      } catch (_) {}
      // Reuse existing chat with same title+userId, or create a new one
      final existing = await _chatDao.query(where: 'title = ? AND userId = ?', whereArgs: [title, _uid]);
      int chatId;
      if (existing.isNotEmpty) {
        chatId = existing.first.id!;
      } else {
        DateTime? chatTime;
        try {
          chatTime = DateTime.parse(datePairs.last['created_at'] as String);
        } catch (_) {}
        final newChat = Chat(title: title, userId: _uid, createdAt: chatTime, updatedAt: chatTime);
        chatId = await _chatDao.insert(newChat);
      }
      final msgs = <ChatMessage>[];
      for (final p in datePairs.reversed) {
        final userText = p['user_msg'] as String? ?? '';
        final asstText = p['assistant_msg'] as String? ?? '';
        final ts = p['created_at'] as String? ?? '';
        msgs.add(ChatMessage(role: MessageRole.user, content: userText, messageId: 'echo_u_${ts}_${userText.hashCode.abs()}'));
        msgs.add(ChatMessage(role: MessageRole.assistant, content: asstText, messageId: 'echo_a_${ts}_${asstText.hashCode.abs()}'));
      }
      await addChatMessage(chatId, msgs);
    }
  }

  /// Claims all chats with no userId (or stamped 'anonymous' from a race condition)
  /// for the currently logged-in user. Called once on startup after AuthService init.
  Future<void> adoptOrphanChats() async {
    final db = await _chatDao.database;
    await db.rawUpdate('UPDATE chat SET userId = ? WHERE userId IS NULL OR userId = ?', [_uid, 'anonymous']);
  }
}
