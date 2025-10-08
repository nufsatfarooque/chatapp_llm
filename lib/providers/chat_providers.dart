import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_session.dart';
import '../models/chat_message.dart';
import '../services/storage_service.dart';
import '../services/llm_service.dart';

final uuid = const Uuid();

/// App theme mode provider
enum AppThemeMode { light, dark }
final themeProvider = StateProvider<AppThemeMode>((ref) => AppThemeMode.light);

/// LLM service provider (singleton)
final llmServiceProvider = Provider((ref) => LLMService());

/// All chat sessions provider (reads from storage)
final chatSessionsProvider = StateNotifierProvider<ChatSessionsNotifier, List<ChatSession>>(
  (ref) => ChatSessionsNotifier(),
);

class ChatSessionsNotifier extends StateNotifier<List<ChatSession>> {
  ChatSessionsNotifier() : super(StorageService.getAllSessions());

  Future<void> refresh() async {
    state = StorageService.getAllSessions();
  }

  Future<void> deleteSession(String id) async {
    await StorageService.deleteSession(id);
    await refresh();
  }

  Future<void> upsertSession(ChatSession s) async {
    await StorageService.upsertSession(s);
    await refresh();
  }
}

/// Active session id provider. null when no session selected.
final activeSessionIdProvider = StateProvider<String?>((ref) => null);

/// Messages for active session (streamed & persistent)
final messagesForSessionProvider = StateNotifierProvider.family<MessagesNotifier, List<ChatMessage>, String>(
  (ref, sessionId) => MessagesNotifier(sessionId),
);

class MessagesNotifier extends StateNotifier<List<ChatMessage>> {
  final String sessionId;
  MessagesNotifier(this.sessionId) : super(StorageService.getMessagesForSession(sessionId));

  Future<void> reload() async {
    state = StorageService.getMessagesForSession(sessionId);
  }

  Future<void> addMessage(ChatMessage msg) async {
    await StorageService.addMessage(msg);
    state = [...state, msg];
  }
}

/// Stream state provider to reflect "assistant is typing"
final assistantTypingProvider = StateProvider<bool>((ref) => false);

/// Sends a user message, streams LLM response, persists both messages, and updates session title.
/// This is the main orchestration provider.
final chatControllerProvider = Provider((ref) {
  final llm = ref.read(llmServiceProvider);
  return ChatController(ref, llm);
});

class ChatController {
  final Ref ref;
  final LLMService llm;
  final int contextWindow;

  ChatController(this.ref, this.llm, {this.contextWindow = 8});

  /// Send user input and stream assistant reply incrementally.
  /// Creates messages, persists user message immediately, then streams assistant.
  Future<void> sendMessage(String sessionId, String userText) async {
    final userMsg = ChatMessage(
      id: uuid.v4(),
      sessionId: sessionId,
      role: MessageRole.user,
      content: userText,
    );
    // persist user message
    await StorageService.addMessage(userMsg);
    // update local provider
    ref.read(messagesForSessionProvider(sessionId).notifier).addMessage(userMsg);

    // Prepare last N messages for stateless LLM context
    final allMsgs = StorageService.getMessagesForSession(sessionId);
    final lastN = allMsgs.length <= contextWindow ? allMsgs : allMsgs.sublist(allMsgs.length - contextWindow);

    // Create an empty assistant message in storage to append streamed content
    final assistantId = uuid.v4();
    var assistantMsg = ChatMessage(
      id: assistantId,
      sessionId: sessionId,
      role: MessageRole.assistant,
      content: '',
    );
    await StorageService.addMessage(assistantMsg);
    ref.read(messagesForSessionProvider(sessionId).notifier).addMessage(assistantMsg);

    // Indicate assistant is typing
    ref.read(assistantTypingProvider.notifier).state = true;

    try {
      // Stream tokens from LLM
      final stream = llm.streamChatCompletion(messages: lastN);
      final buffer = StringBuffer();
      await for (final token in stream) {
        buffer.write(token);
        // update assistant message content incrementally in storage and provider
        assistantMsg.content = buffer.toString();
        // persist update by replacing object in box
        await StorageService.addMessage(assistantMsg);
        // notify UI
        await ref.read(messagesForSessionProvider(sessionId).notifier).reload();
      }

      // finished streaming
      ref.read(assistantTypingProvider.notifier).state = false;

      // If session title is default, auto-name session based on assistant's first line/title
      final sessionBox = StorageService.getAllSessions().firstWhere((s) => s.id == sessionId, orElse: () => ChatSession(id: sessionId, title: 'Chat'));
      if (sessionBox.title.startsWith('Chat')) {
        final firstLine = assistantMsg.content.split('\n').first.trim();
        sessionBox.title = firstLine.length > 0 ? (firstLine.length > 40 ? '${firstLine.substring(0, 40)}...' : firstLine) : sessionBox.title;
        await StorageService.upsertSession(sessionBox);
        ref.read(chatSessionsProvider.notifier).refresh();
      }
    } catch (e) {
      ref.read(assistantTypingProvider.notifier).state = false;
      // on error, append error text to assistant message
      assistantMsg.content += '\n\n[Error: ${e.toString()}]';
      await StorageService.addMessage(assistantMsg);
      await ref.read(messagesForSessionProvider(sessionId).notifier).reload();
      rethrow;
    }
  }

  /// Creates a new session and returns its id.
  Future<String> createNewSession() async {
    final id = uuid.v4();
    final session = ChatSession(id: id, title: 'Chat ${DateTime.now().toIso8601String()}');
    await StorageService.upsertSession(session);
    await ref.read(chatSessionsProvider.notifier).refresh();
    return id;
  }
}
