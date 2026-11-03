import 'package:momnt/models/chat_attachment.dart';

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.createdAt,
    required this.isMine,
    this.readAt,
    this.attachment,
  });

  final String id;
  final String text;
  final DateTime createdAt;
  final bool isMine;

  /// Gelen mesajda bizim; giden mesajda karşı tarafın okuma zamanı.
  final DateTime? readAt;
  final ChatAttachment? attachment;
  String get previewText =>
      text.isNotEmpty ? text : attachment?.previewText ?? '';

  ChatMessage markRead(DateTime time) => ChatMessage(
    id: id,
    text: text,
    createdAt: createdAt,
    isMine: isMine,
    readAt: readAt ?? time,
    attachment: attachment,
  );

  ChatMessage withAttachment(ChatAttachment next) => ChatMessage(
    id: id,
    text: text,
    createdAt: createdAt,
    isMine: isMine,
    readAt: readAt,
    attachment: next,
  );
}
