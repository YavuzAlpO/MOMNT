import 'dart:typed_data';

enum ChatAttachmentKind { image, document, audio }

enum PhotoVisibility { persistent, viewOnce }

class ChatAttachment {
  const ChatAttachment({
    required this.kind,
    required this.name,
    required this.bytes,
    required this.mimeType,
    this.duration,
    this.photoVisibility = PhotoVisibility.persistent,
    this.openedAt,
  });

  static const maxBytes = 20 * 1024 * 1024;
  final ChatAttachmentKind kind;
  final String name;
  final Uint8List bytes;
  final String mimeType;
  final Duration? duration;
  final PhotoVisibility photoVisibility;
  final DateTime? openedAt;
  bool get isViewOnce =>
      kind == ChatAttachmentKind.image &&
      photoVisibility == PhotoVisibility.viewOnce;

  ChatAttachment withPhotoVisibility(PhotoVisibility visibility) =>
      ChatAttachment(
        kind: kind,
        name: name,
        bytes: bytes,
        mimeType: mimeType,
        duration: duration,
        photoVisibility: visibility,
      );

  /// Oturum kaydındaki fotoğraf verisini ilk açılışta bırakır.
  ChatAttachment consumed(DateTime time) => ChatAttachment(
    kind: kind,
    name: name,
    bytes: Uint8List(0),
    mimeType: mimeType,
    duration: duration,
    photoVisibility: photoVisibility,
    openedAt: time,
  );

  String get previewText => switch (kind) {
    ChatAttachmentKind.image =>
      isViewOnce
          ? (openedAt == null ? 'Tek seferlik fotoğraf' : 'Fotoğraf açıldı')
          : 'Fotoğraf',
    ChatAttachmentKind.document => 'Belge: $name',
    ChatAttachmentKind.audio => 'Ses kaydı',
  };
}
