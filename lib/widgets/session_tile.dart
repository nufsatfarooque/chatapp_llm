import 'package:flutter/material.dart';
import '../models/chat_session.dart';
import '../services/storage_service.dart';

/// SessionTile shows session title and preview of last message + timestamp.
class SessionTile extends StatelessWidget {
  final ChatSession session;
  final VoidCallback? onTap;
  const SessionTile({super.key, required this.session, this.onTap});

  @override
  Widget build(BuildContext context) {
    final msgs = StorageService.getMessagesForSession(session.id);
    final preview = msgs.isNotEmpty ? msgs.last.content : 'No messages yet';
    final time = session.updatedAt;
    final theme = Theme.of(context);

    return ListTile(
      title: Text(session.title, style: theme.textTheme.titleMedium),
      subtitle: Text(preview, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Text(_formatTime(time), style: theme.textTheme.bodySmall),
      onTap: onTap,
    );
  }

  String _formatTime(DateTime t) {
    final now = DateTime.now();
    if (t.day == now.day && t.month == now.month && t.year == now.year) {
      return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    }
    return '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
  }
}
