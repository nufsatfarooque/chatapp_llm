import 'package:hive_flutter/hive_flutter.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';

/// StorageService abstracts Hive storage for chat sessions and messages.
/// Works seamlessly on mobile, desktop, and web (no path_provider needed).
class StorageService {
  static const String sessionsBoxName = 'chat_sessions';
  static const String messagesBoxName = 'chat_messages';

  static Box<ChatSession>? _sessionsBox;
  static Box<ChatMessage>? _messagesBox;

  /// Initializes Hive safely across all platforms.
  static Future<void> registerAdaptersAndOpenBoxes() async {
    // Initialize Hive for web & mobile
    await Hive.initFlutter();

    // Register adapters if not already registered
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ChatMessageAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(ChatSessionAdapter());
    }

    // Open boxes (create if not exist)
    _sessionsBox ??= await Hive.openBox<ChatSession>(sessionsBoxName);
    _messagesBox ??= await Hive.openBox<ChatMessage>(messagesBoxName);
  }

  /// Returns all chat sessions ordered by `updatedAt` descending.
  static List<ChatSession> getAllSessions() {
    if (_sessionsBox == null || !_sessionsBox!.isOpen) return [];

    final sessions = _sessionsBox!.values.toList();
    sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sessions;
  }

  /// Inserts or updates a session.
  static Future<void> upsertSession(ChatSession session) async {
    if (_sessionsBox == null) return;
    await _sessionsBox!.put(session.id, session);
  }

  /// Deletes a session and its messages.
  static Future<void> deleteSession(String sessionId) async {
    if (_sessionsBox == null || _messagesBox == null) return;

    // Delete messages of this session
    final msgs = _messagesBox!.values
        .where((m) => m.sessionId == sessionId)
        .toList();

    for (final m in msgs) {
      await m.delete();
    }

    // Delete session
    await _sessionsBox!.delete(sessionId);
  }

  /// Adds a new message and updates session timestamp.
  static Future<void> addMessage(ChatMessage message) async {
    if (_messagesBox == null || _sessionsBox == null) return;

    await _messagesBox!.put(message.id, message);

    // Update session timestamp
    final session = _sessionsBox!.get(message.sessionId);
    if (session != null) {
      session.updatedAt = DateTime.now();
      await session.save();
    }
  }

  /// Retrieves all messages for a session (ordered by timestamp ascending).
  static List<ChatMessage> getMessagesForSession(String sessionId) {
    if (_messagesBox == null || !_messagesBox!.isOpen) return [];

    final msgs = _messagesBox!.values
        .where((m) => m.sessionId == sessionId)
        .toList();
    msgs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return msgs;
  }
}
