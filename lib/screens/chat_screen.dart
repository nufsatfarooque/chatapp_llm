import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:llm_chat_local/models/chat_session.dart';
import '../models/chat_message.dart';
import '../providers/chat_providers.dart';
import '../widgets/chat_bubble.dart';
import 'package:uuid/uuid.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String sessionId;
  const ChatScreen({super.key, required this.sessionId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _uuid = const Uuid();

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    // reload messages from storage on open
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(messagesForSessionProvider(widget.sessionId).notifier).reload(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(messagesForSessionProvider(widget.sessionId));
    final isTyping = ref.watch(assistantTypingProvider);

    // Scroll after every frame so latest message is visible
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Scaffold(
      backgroundColor: Colors.grey.shade900, // dark background
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 185, 61, 61),
        title: Text(_getSessionTitle(widget.sessionId)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () async {
              await ref.read(chatSessionsProvider.notifier).deleteSession(widget.sessionId);
              Navigator.of(context).pop();
            },
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: messages.length + (isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= messages.length) {
                  // typing indicator bubble
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('Typing...', style: TextStyle(color: Colors.white70)),
                    ),
                  );
                }
                final m = messages[index];
                return ChatBubble(
                  message: m,
                  scrollController: _scrollController, // pass controller to bubble
                );
              },
            ),
          ),
          const Divider(height: 1, color: Colors.grey),
          _buildInput(),
        ],
      ),
    );
  }

  String _getSessionTitle(String id) {
    final sessions = ref.read(chatSessionsProvider);
    final s = sessions.firstWhere((e) => e.id == id, orElse: () => ChatSession(id: id, title: 'Chat'));
    return s.title;
  }

  Widget _buildInput() {
    final isTyping = ref.watch(assistantTypingProvider);
    return SafeArea(
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.send,
              onSubmitted: (v) => _send(),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Type your message',
                hintStyle: TextStyle(color: Colors.white54),
              ),
            ),
          ),
          isTyping
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: _send,
                ),
        ],
      ),
    );
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    ref.read(chatControllerProvider).sendMessage(widget.sessionId, text).catchError((e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $e')),
      );
    });
  }
}
