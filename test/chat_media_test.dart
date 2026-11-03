import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momnt/models/chat_attachment.dart';
import 'package:momnt/models/chat_message.dart';
import 'package:momnt/models/mutual_follow_profile.dart';
import 'package:momnt/screens/chat_screen.dart';
import 'package:momnt/services/chat_media_service.dart';
import 'package:momnt/state/messages_controller.dart';
import 'package:provider/provider.dart';

class _Media extends ChatMediaService {
  ChatAttachment? next;
  ChatAttachment? cameraPhoto;
  bool cameraDenied = false;
  int captures = 0;
  bool denied = false;
  bool disposed = false;
  int starts = 0;
  int stops = 0;
  int pauses = 0;
  int resumes = 0;
  bool pauseFails = false;
  int cancels = 0;
  ChatAttachmentKind? pickedKind;

  @override
  Future<ChatAttachment?> takePhoto(BuildContext context) async {
    captures++;
    if (cameraDenied) throw const ChatMediaException('Kamera izni reddedildi');
    return cameraPhoto;
  }

  @override
  Future<ChatAttachment?> pick(ChatAttachmentKind kind) async {
    pickedKind = kind;
    return next;
  }

  @override
  Future<void> startRecording() async {
    starts++;
    if (denied) throw const ChatMediaException('Mikrofon izni reddedildi');
  }

  @override
  Future<ChatAttachment?> stopRecording() async {
    stops++;
    return ChatAttachment(
      kind: ChatAttachmentKind.audio,
      name: 'Ses kaydı.webm',
      bytes: Uint8List.fromList([1, 2, 3]),
      mimeType: 'audio/webm',
      duration: const Duration(seconds: 12),
    );
  }

  @override
  Future<void> pauseRecording() async {
    if (pauseFails) throw const ChatMediaException('Kayıt duraklatılamadı');
    pauses++;
  }

  @override
  Future<void> resumeRecording() async {
    resumes++;
  }

  @override
  Future<void> cancelRecording() async {
    cancels++;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

Future<MessagesController> _start(
  WidgetTester tester,
  _Media media, {
  List<ChatMessage> incoming = const [],
}) async {
  final controller = MessagesController(
    contacts: const [
      MutualFollowProfile(id: 'mert', name: 'Mert', username: '@mert'),
    ],
    initialConversations: [
      ChatConversation(
        contact: const MutualFollowProfile(
          id: 'mert',
          name: 'Mert',
          username: '@mert',
        ),
        messages: incoming,
      ),
    ],
  )..openConversation('mert');
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: controller,
      child: MaterialApp(
        home: ChatScreen(contactId: 'mert', mediaService: media),
      ),
    ),
  );
  return controller;
}

Future<void> _pick(WidgetTester tester, String type) async {
  await tester.tap(find.byKey(const Key('chat-attach')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(type));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'duraklat ve devam aynı kaydı sürdürür; duraklatılmış kayıt bitirilebilir',
    (tester) async {
      final media = _Media();
      final controller = await _start(tester, media);
      await tester.tap(find.byKey(const Key('chat-mic')));
      await tester.pumpAndSettle();
      expect(
        tester.getCenter(find.byTooltip('Kaydı duraklat')).dx,
        lessThan(tester.getCenter(find.byTooltip('Kaydı durdur')).dx),
      );
      await tester.tap(find.byTooltip('Kaydı duraklat'));
      await tester.pumpAndSettle();
      expect(media.pauses, 1);
      expect(find.textContaining('Duraklatıldı'), findsOneWidget);
      final pausedText = tester
          .widget<Text>(find.textContaining('Duraklatıldı'))
          .data;
      await tester.pump(const Duration(seconds: 3));
      expect(find.text(pausedText!), findsOneWidget);
      await tester.tap(find.byTooltip('Kayda devam et'));
      await tester.pumpAndSettle();
      expect(media.resumes, 1);
      expect(media.starts, 1);
      expect(find.textContaining('Duraklatıldı'), findsNothing);
      await tester.tap(find.byTooltip('Kaydı duraklat'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Kaydı durdur'));
      await tester.pumpAndSettle();
      expect(media.stops, 1);
      expect(controller.conversation('mert')!.messages, isEmpty);
      await tester.tap(find.byKey(const Key('chat-send')));
      await tester.pumpAndSettle();
      expect(
        controller.conversation('mert')!.messages.single.attachment!.kind,
        ChatAttachmentKind.audio,
      );
    },
  );

  testWidgets(
    'duraklatma hatasında kayıt durumu korunur; iptal yeni kaydı sıfırlar',
    (tester) async {
      final media = _Media()..pauseFails = true;
      final controller = await _start(tester, media);
      await tester.tap(find.byKey(const Key('chat-mic')));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Kaydı duraklat'));
      await tester.pumpAndSettle();
      expect(find.text('Kayıt duraklatılamadı'), findsOneWidget);
      expect(find.byTooltip('Kaydı duraklat'), findsOneWidget);
      expect(find.byTooltip('Kayda devam et'), findsNothing);
      ScaffoldMessenger.of(tester.element(find.byType(ChatScreen)))
          .removeCurrentSnackBar();
      await tester.pumpAndSettle();
      media.pauseFails = false;
      await tester.tap(find.byTooltip('Kaydı duraklat'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Kaydı iptal et'));
      await tester.pumpAndSettle();
      expect(media.cancels, 1);
      expect(controller.conversation('mert')!.messages, isEmpty);
      await tester.tap(find.byKey(const Key('chat-mic')));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Kaydı duraklat'), findsOneWidget);
      expect(find.byTooltip('Kayda devam et'), findsNothing);
      await tester.tap(find.byTooltip('Kaydı iptal et'));
      await tester.pumpAndSettle();
    },
  );

  ChatAttachment photo() => ChatAttachment(
    kind: ChatAttachmentKind.image,
    name: 'kamera.png',
    mimeType: 'image/png',
    bytes: base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
    ),
  );

  testWidgets(
    'kamera fotoğrafı tek seferlik seçilip gönderilebilir; gönderici açamaz',
    (tester) async {
      final media = _Media()..cameraPhoto = photo();
      final controller = await _start(tester, media);
      final input = tester.widget<TextField>(
        find.byKey(const Key('chat-input')),
      );
      expect(input.decoration!.suffixIcon, isA<IconButton>());
      await tester.tap(find.byKey(const Key('chat-camera')));
      await tester.pumpAndSettle();
      expect(media.captures, 1);
      expect(controller.conversation('mert')!.messages, isEmpty);
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Kalıcı'))
            .selected,
        isTrue,
      );
      await tester.tap(find.text('Tek seferlik'));
      await tester.pump();
      await tester.tap(find.byKey(const Key('chat-send')));
      await tester.pumpAndSettle();
      final message = controller.conversation('mert')!.messages.single;
      expect(message.attachment!.isViewOnce, isTrue);
      expect(find.byType(Image), findsNothing);
      expect(find.text('Gönderen tekrar açamaz'), findsOneWidget);
      expect(controller.claimViewOncePhoto('mert', message.id), isNull);
      expect(message.attachment!.openedAt, isNull);
    },
  );

  testWidgets('kalıcı kamera fotoğrafı tekrar açılabilir', (tester) async {
    final media = _Media()..cameraPhoto = photo();
    final controller = await _start(tester, media);
    await tester.tap(find.byKey(const Key('chat-camera')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chat-send')));
    await tester.pumpAndSettle();
    expect(
      controller.conversation('mert')!.messages.single.attachment!.isViewOnce,
      isFalse,
    );
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byType(Image));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('Kaydet'), findsOneWidget);
      await tester.tap(find.text('Kapat'));
      await tester.pumpAndSettle();
    }
  });

  testWidgets(
    'alıcı tek seferlik fotoğrafı yalnız bir kez açar; gövde ve kaydetme kaldırılır',
    (tester) async {
      final attachment = photo().withPhotoVisibility(PhotoVisibility.viewOnce);
      final controller = await _start(
        tester,
        _Media(),
        incoming: [
          ChatMessage(
            id: 'incoming-once',
            text: '',
            createdAt: DateTime.now(),
            isMine: false,
            attachment: attachment,
          ),
        ],
      );
      expect(
        controller.conversation('mert')!.messages.single.attachment!.bytes,
        isNotEmpty,
      );
      expect(find.byType(Image), findsNothing);
      await tester.tap(find.text('Tek seferlik fotoğraf'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(find.text('Kaydet'), findsNothing);
      final consumed = controller
          .conversation('mert')!
          .messages
          .single
          .attachment!;
      expect(consumed.bytes, isEmpty);
      expect(consumed.openedAt, isNotNull);
      expect(controller.claimViewOncePhoto('mert', 'incoming-once'), isNull);
      await tester.tap(find.text('Kapat'));
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsNothing);
      expect(find.text('Fotoğraf açıldı'), findsOneWidget);
      controller.openConversation('mert');
      expect(
        controller.conversation('mert')!.messages.single.attachment!.openedAt,
        consumed.openedAt,
      );
    },
  );

  testWidgets('kamera iptali veya izin reddi taslağı göndermez ve korur', (
    tester,
  ) async {
    final media = _Media();
    final controller = await _start(tester, media);
    await tester.enterText(find.byKey(const Key('chat-input')), 'Taslak');
    await tester.tap(find.byKey(const Key('chat-camera')));
    await tester.pumpAndSettle();
    expect(controller.conversation('mert')!.messages, isEmpty);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('chat-input')))
          .controller!
          .text,
      'Taslak',
    );
    media.cameraDenied = true;
    await tester.tap(find.byKey(const Key('chat-camera')));
    await tester.pumpAndSettle();
    expect(find.text('Kamera izni reddedildi'), findsOneWidget);
    expect(controller.conversation('mert')!.messages, isEmpty);
  });

  testWidgets(
    'belge önizlenir, kaldırılabilir ve açıklamayla mevcut sohbete eklenir',
    (tester) async {
      final media = _Media()
        ..next = ChatAttachment(
          kind: ChatAttachmentKind.document,
          name: 'belge.pdf',
          bytes: Uint8List.fromList([37, 80, 68, 70]),
          mimeType: 'application/pdf',
        );
      final controller = await _start(tester, media);
      await _pick(tester, 'Belge');
      expect(media.pickedKind, ChatAttachmentKind.document);
      expect(find.text('belge.pdf'), findsOneWidget);
      expect(controller.conversation('mert')!.messages, isEmpty);
      await tester.tap(find.byTooltip('Eki kaldır'));
      await tester.pump();
      expect(find.text('belge.pdf'), findsNothing);
      await _pick(tester, 'Belge');
      await tester.enterText(
        find.byKey(const Key('chat-input')),
        'Dosyam burada',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('chat-send')));
      await tester.pumpAndSettle();
      final message = controller.conversation('mert')!.messages.single;
      expect(message.text, 'Dosyam burada');
      expect(message.attachment, same(media.next));
      expect(message.markRead(DateTime.now()).attachment, same(media.next));
      expect(find.byTooltip('Eki kaldır'), findsNothing);
    },
  );

  testWidgets('fotoğraf seçimi görsel önizleme ve ek olarak gönderme sağlar', (
    tester,
  ) async {
    final media = _Media()
      ..next = ChatAttachment(
        kind: ChatAttachmentKind.image,
        name: 'foto.png',
        mimeType: 'image/png',
        bytes: base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
        ),
      );
    final controller = await _start(tester, media);
    await _pick(tester, 'Fotoğraf');
    expect(media.pickedKind, ChatAttachmentKind.image);
    expect(find.byType(Image), findsOneWidget);
    expect(controller.conversation('mert')!.messages, isEmpty);
    await tester.tap(find.byKey(const Key('chat-send')));
    await tester.pumpAndSettle();
    expect(
      controller.conversation('mert')!.messages.single.previewText,
      'Fotoğraf',
    );
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets(
    'dosya seçimi iptal edilince metin korunur ve mesaj oluşturulmaz',
    (tester) async {
      final controller = await _start(tester, _Media());
      await tester.enterText(find.byKey(const Key('chat-input')), 'Taslak');
      await _pick(tester, 'Belge');
      expect(controller.conversation('mert')!.messages, isEmpty);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('chat-input')))
            .controller!
            .text,
        'Taslak',
      );
    },
  );

  testWidgets(
    'ses kaydı durdurulduktan sonra onayla gönderilir; iptal göndermez',
    (tester) async {
      final media = _Media();
      final controller = await _start(tester, media);
      await tester.tap(find.byKey(const Key('chat-mic')));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Kaydı durdur'), findsOneWidget);
      await tester.tap(find.byTooltip('Kaydı iptal et'));
      await tester.pumpAndSettle();
      expect(media.cancels, 1);
      expect(controller.conversation('mert')!.messages, isEmpty);
      await tester.tap(find.byKey(const Key('chat-mic')));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Kaydı durdur'));
      await tester.pumpAndSettle();
      expect(media.stops, 1);
      expect(find.byTooltip('Ses kaydını dinle'), findsOneWidget);
      expect(controller.conversation('mert')!.messages, isEmpty);
      await tester.tap(find.byKey(const Key('chat-send')));
      await tester.pumpAndSettle();
      final message = controller.conversation('mert')!.messages.single;
      expect(message.attachment!.kind, ChatAttachmentKind.audio);
      expect(message.attachment!.duration, const Duration(seconds: 12));
      expect(message.previewText, 'Ses kaydı');
    },
  );

  testWidgets(
    'mikrofon izni reddi hata gösterir; sohbet kapanınca kaynaklar bırakılır',
    (tester) async {
      final media = _Media()..denied = true;
      final controller = await _start(tester, media);
      await tester.tap(find.byKey(const Key('chat-mic')));
      await tester.pumpAndSettle();
      expect(find.text('Mikrofon izni reddedildi'), findsOneWidget);
      expect(find.byTooltip('Kaydı durdur'), findsNothing);
      expect(controller.conversation('mert')!.messages, isEmpty);
      media.denied = false;
      ScaffoldMessenger.of(tester.element(find.byType(ChatScreen)))
          .removeCurrentSnackBar();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('chat-mic')));
      await tester.pumpAndSettle();
      expect(media.starts, 2);
      expect(find.byTooltip('Kaydı durdur'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(media.disposed, isTrue);
    },
  );
}
