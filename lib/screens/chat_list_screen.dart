import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_providers.dart';
import 'chat_screen.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedSessionId;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    final sessions = ref.read(chatSessionsProvider);
    if (sessions.isNotEmpty) {
      _selectedSessionId = sessions.first.id;
    }

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(chatSessionsProvider);

    // Sort sessions by latest update
    final sortedSessions = [...sessions];
    sortedSessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
      ),
      body: Row(
        children: [
          // Left panel (chat list)
          Container(
            width: 300,
            color: isDark ? Colors.grey[900] : Colors.grey[100],
            child: Column(
              children: [
                // New Chat Button
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add_comment_rounded),
                    label: const Text('New Chat'),
                    onPressed: () async {
                      final id =
                          await ref.read(chatControllerProvider).createNewSession();
                      ref.read(activeSessionIdProvider.notifier).state = id;
                      setState(() {
                        _selectedSessionId = id;
                      });
                    },
                  ),
                ),
                const Divider(height: 1),

                // Chat list
                Expanded(
                  child: ListView.builder(
                    itemCount: sortedSessions.length,
                    itemBuilder: (context, index) {
                      final s = sortedSessions[index];
                      final isSelected = s.id == _selectedSessionId;

                      // Use staggered animation delay
                      final intervalStart = (index / sortedSessions.length).clamp(0.0, 1.0);
                      final animation = CurvedAnimation(
                        parent: _animationController,
                        curve: Interval(
                          intervalStart,
                          1.0,
                          curve: Curves.easeOutBack,
                        ),
                      );

                      return AnimatedBuilder(
                        animation: animation,
                        builder: (context, child) {
                          final offsetY = 50 * (1 - animation.value);
                          final opacity = animation.value;
                          return Transform.translate(
                            offset: Offset(0, offsetY),
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 400),
                              opacity: opacity,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? theme.colorScheme.primary.withOpacity(0.2)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ListTile(
                                  selected: isSelected,
                                  leading: const Icon(Icons.chat_bubble_outline_rounded),
                                  title: Text(
                                    s.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color:
                                            isDark ? Colors.white : Colors.black),
                                  ),
                                  subtitle: Text(
                                    'Updated: ${s.updatedAt.toLocal()}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[700],
                                    ),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _selectedSessionId = s.id;
                                    });
                                  },
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete),
                                    color: isDark
                                        ? Colors.red[300]
                                        : Colors.red,
                                    onPressed: () async {
                                      await ref
                                          .read(chatSessionsProvider.notifier)
                                          .deleteSession(s.id);
                                      if (_selectedSessionId == s.id) {
                                        _selectedSessionId =
                                            sortedSessions.isNotEmpty
                                                ? sortedSessions.first.id
                                                : null;
                                      }
                                      setState(() {});
                                    },
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const VerticalDivider(width: 1),

          // Right panel (chat area)
          Expanded(
            child: _selectedSessionId != null
                ? ChatScreen(sessionId: _selectedSessionId!)
                : Center(
                    child: Text(
                      'Select or create a chat',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontSize: 16,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
