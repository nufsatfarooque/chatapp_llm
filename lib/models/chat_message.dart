import 'package:hive/hive.dart';

// part 'chat_message.g.dart'; // not using codegen here but keep for clarity

/// Message roles used in chat.
enum MessageRole { user, assistant, system }

/// A chat message model stored locally.
@HiveType(typeId: 1)
class ChatMessage extends HiveObject {
  @HiveField(0)
  String id; // Unique id (UUID or timestamp-based)

  @HiveField(1)
  String sessionId; // Parent session id

  @HiveField(2)
  MessageRole role;

  @HiveField(3)
  String content;

  @HiveField(4)
  DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Manually written Hive adapter for ChatMessage.
/// If you're using build_runner + hive_generator, you can generate instead.
class ChatMessageAdapter extends TypeAdapter<ChatMessage> {
  @override
  final typeId = 1;

  @override
  ChatMessage read(BinaryReader reader) {
    final id = reader.readString();
    final sessionId = reader.readString();
    final roleIndex = reader.readInt();
    final content = reader.readString();
    final timestampMillis = reader.readInt();
    return ChatMessage(
      id: id,
      sessionId: sessionId,
      role: MessageRole.values[roleIndex],
      content: content,
      timestamp: DateTime.fromMillisecondsSinceEpoch(timestampMillis),
    );
  }

  @override
  void write(BinaryWriter writer, ChatMessage obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.sessionId);
    writer.writeInt(obj.role.index);
    writer.writeString(obj.content);
    writer.writeInt(obj.timestamp.millisecondsSinceEpoch);
  }
}
