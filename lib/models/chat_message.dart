import 'package:momnt/models/chat_attachment.dart';

class StoryReply {
  const StoryReply({required this.imageUrl, required this.caption});

  final String imageUrl;
  final String caption;
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.createdAt,
    required this.isMine,
    this.readAt,
    this.attachment,
    this.storyReply,
  });

  final String id;
  final String text;
  final DateTime createdAt;
  final bool isMine;

  /// Gelen mesajda bizim; giden mesajda karşı tarafın okuma zamanı.
  final DateTime? readAt;
  final ChatAttachment? attachment;
  final StoryReply? storyReply;

  String get previewText {
    if (storyReply != null) return 'Hikâye yanıtı: $text';
    return text.isNotEmpty ? text : attachment?.previewText ?? '';
  }

  ChatMessage markRead(DateTime time) => ChatMessage(
    id: id,
    text: text,
    createdAt: createdAt,
    isMine: isMine,
    readAt: readAt ?? time,
    attachment: attachment,
    storyReply: storyReply,
  );

  ChatMessage withAttachment(ChatAttachment next) => ChatMessage(
    id: id,
    text: text,
    createdAt: createdAt,
    isMine: isMine,
    readAt: readAt,
    attachment: next,
    storyReply: storyReply,
  );
}
