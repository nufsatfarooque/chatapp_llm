import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_providers.dart';
import 'chat_screen.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  String? _selectedSessionId;

  @override
  void initState() {
    super.initState();
    final sessions = ref.read(chatSessionsProvider);
    if (sessions.isNotEmpty) {
      _selectedSessionId = sessions.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(chatSessionsProvider);

    // Sort sessions by updatedAt descending (latest first)
    final sortedSessions = [...sessions];
    sortedSessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        /*actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: () {
              final cur = ref.read(themeProvider);
              ref.read(themeProvider.notifier).state =
                  cur == AppThemeMode.light
                      ? AppThemeMode.dark
                      : AppThemeMode.light;
            },
          ),
        ],*/
      ),
      body: Row(
        children: [
          // Left chat list panel
          Container(
            width: 300,
            color: isDark ? Colors.grey[900] : Colors.grey[100],
            child: Column(
              children: [
                // New Chat Button at the very top
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
                      return ListTile(
                        selected: isSelected,
                        selectedTileColor: theme.colorScheme.primary.withOpacity(0.2),
                        leading: const Icon(Icons.chat_bubble_outline_rounded),
                        title: Text(
                          s.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: isDark ? Colors.white : Colors.black),
                        ),
                        subtitle: Text(
                          'Updated: ${s.updatedAt.toLocal()}',
                          style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey[400] : Colors.grey[700]),
                        ),
                        onTap: () {
                          setState(() {
                            _selectedSessionId = s.id;
                          });
                        },
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          color: isDark ? Colors.red[300] : Colors.red,
                          onPressed: () async {
                            await ref.read(chatSessionsProvider.notifier).deleteSession(s.id);
                            if (_selectedSessionId == s.id) {
                              _selectedSessionId = sortedSessions.isNotEmpty
                                  ? sortedSessions.first.id
                                  : null;
                            }
                            setState(() {});
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          // Right chat panel
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
