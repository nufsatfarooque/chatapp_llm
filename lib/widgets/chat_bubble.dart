import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import 'typing_markdown.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final ScrollController? scrollController;

  const ChatBubble({super.key, required this.message, this.scrollController});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    final bgColor = isUser ? Colors.pinkAccent.shade100 : Colors.grey.shade900;
    final textColor = isUser ? Colors.black87 : Colors.white70;

    // Auto-scroll on new messages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController != null && scrollController!.hasClients) {
        scrollController!.animateTo(
          scrollController!.position.maxScrollExtent + 200,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    // Main chat bubble
    final bubble = Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: isUser
            ? SelectableText(
                message.content,
                style: TextStyle(color: textColor, fontSize: 16),
              )
            : MarkdownSelectable(
                text: message.content,
                style: TextStyle(color: textColor, fontSize: 16),
              ),
      ),
    );

    // Animate entry: user slides right, LLM slides left
    return bubble
        .animate()
        .fadeIn(duration: 400.ms, curve: Curves.easeOut)
        .slide(
          begin: Offset(isUser ? 0.3 : -0.3, 0),
          duration: 500.ms,
          curve: Curves.easeOutCubic,
        );
  }
}
