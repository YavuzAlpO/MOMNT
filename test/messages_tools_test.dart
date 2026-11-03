import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momnt/models/chat_attachment.dart';
import 'package:momnt/models/chat_message.dart';
import 'package:momnt/models/mutual_follow_profile.dart';
import 'package:momnt/screens/chat_screen.dart';
import 'package:momnt/screens/messages_tab_screen.dart';
import 'package:momnt/state/messages_controller.dart';
import 'package:provider/provider.dart';

const _contacts = [
  MutualFollowProfile(id: 'mert', name: 'Mert Yılmaz', username: '@mertyilmaz'),
  MutualFollowProfile(id: 'selin', name: 'Selin Kaya', username: '@selinkaya'),
  MutualFollowProfile(id: 'deniz', name: 'Deniz Akın', username: '@denizakin'),
];

MessagesController _controller() {
  final now = DateTime.now();
  return MessagesController(
    contacts: _contacts,
    initialConversations: [
      for (final contact in _contacts)
        ChatConversation(
          contact: contact,
          unreadCount: 1,
          isArchived: contact.id == 'deniz',
          messages: [
            ChatMessage(
              id: 'incoming-${contact.id}',
              text: contact.id == 'mert'
                  ? 'Eski buluşma mesajı'
                  : 'Kahve içelim mi?',
              createdAt: now.subtract(const Duration(minutes: 10)),
              isMine: false,
              attachment: contact.id != 'deniz'
                  ? null
                  : ChatAttachment(
                      kind: ChatAttachmentKind.image,
                      name: 'foto.jpg',
                      bytes: Uint8List.fromList([1, 2]),
                      mimeType: 'image/jpeg',
                      photoVisibility: PhotoVisibility.viewOnce,
                    ),
            ),
            ChatMessage(
              id: 'outgoing-${contact.id}',
              text: 'Son mesaj',
              createdAt: now,
              isMine: true,
            ),
          ],
        ),
    ],
  );
}

Future<MessagesController> _start(WidgetTester tester) async {
  final controller = _controller();
  await tester.pumpWidget(
    ChangeNotifierProvider<MessagesController>(
      create: (_) => controller,
      child: const MaterialApp(home: Scaffold(body: MessagesTabScreen())),
    ),
  );
  return controller;
}

Future<void> _menu(WidgetTester tester, String label) async {
  await tester.tap(find.byKey(const Key('messages-menu')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

Future<void> _query(WidgetTester tester, String query) async {
  await tester.enterText(find.byKey(const Key('conversation-search')), query);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'arama arşivin üstündedir; ad, kullanıcı adı ve eski mesaj içeriğini bulur',
    (tester) async {
      await _start(tester);
      expect(
        tester.getTopLeft(find.byKey(const Key('conversation-search'))).dy,
        lessThan(
          tester.getTopLeft(find.byKey(const Key('archived-conversations'))).dy,
        ),
      );
      expect(
        tester.getTopLeft(find.byKey(const Key('messages-menu'))).dy,
        lessThan(tester.getTopLeft(find.text('Mesajlar')).dy),
      );
      for (final query in ['yilmaz', '@MERTYILMAZ', 'ESKI BULUSMA']) {
        await _query(tester, query);
        expect(find.byKey(const ValueKey('conversation-mert')), findsOneWidget);
        expect(find.byKey(const ValueKey('conversation-selin')), findsNothing);
      }
      await _query(tester, 'selin');
      expect(find.byKey(const ValueKey('conversation-selin')), findsOneWidget);
      expect(find.byKey(const ValueKey('conversation-mert')), findsNothing);
      await _query(tester, 'eşleşme yok');
      expect(find.text('Aramana uygun sohbet bulunamadı.'), findsOneWidget);
      await tester.tap(find.byTooltip('Aramayı temizle'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('conversation-mert')), findsOneWidget);
      expect(find.byKey(const ValueKey('conversation-selin')), findsOneWidget);
    },
  );

  testWidgets('tümü okundu arama filtresinden bağımsız arşivi de kapsar', (
    tester,
  ) async {
    final controller = await _start(tester);
    await _query(tester, 'mert');
    await _menu(tester, 'Tümünü okundu işaretle');
    for (final contact in _contacts) {
      final chat = controller.conversation(contact.id)!;
      expect(chat.unreadCount, 0);
      expect(chat.messages.first.readAt, isNotNull);
      expect(chat.messages.last.readAt, isNull);
    }
    final attachment = controller
        .conversation('deniz')!
        .messages
        .first
        .attachment!;
    expect(attachment.bytes, isNotEmpty);
    expect(attachment.openedAt, isNull);
    expect(controller.conversation('deniz')!.isArchived, isTrue);
  });

  testWidgets(
    'seçim sohbet açmaz; toplu sabitleme, okundu, arşiv ve geri alma çalışır',
    (tester) async {
      final controller = await _start(tester);
      await _menu(tester, 'Mesaj seç');
      await tester.tap(find.byKey(const ValueKey('conversation-mert')));
      await tester.pump();
      expect(find.byType(ChatScreen), findsNothing);
      expect(find.text('1 seçildi'), findsOneWidget);
      await tester.tap(find.text('Tümünü seç'));
      await tester.pumpAndSettle();
      expect(find.text('2 seçildi'), findsOneWidget);
      await tester.tap(find.byKey(const Key('bulk-pin')));
      await tester.pumpAndSettle();
      expect(controller.conversation('mert')!.isPinned, isTrue);
      expect(controller.conversation('selin')!.isPinned, isTrue);
      expect(controller.conversation('deniz')!.isPinned, isFalse);
      await tester.tap(find.byKey(const Key('bulk-read')));
      await tester.pumpAndSettle();
      expect(controller.conversation('mert')!.unreadCount, 0);
      expect(controller.conversation('deniz')!.unreadCount, 1);
      await tester.tap(find.byKey(const Key('bulk-archive')));
      await tester.pumpAndSettle();
      expect(controller.conversations, isEmpty);
      expect(controller.archivedConversations.length, 3);
      expect(find.byType(Checkbox), findsNothing);
      await tester.tap(find.byKey(const Key('archived-conversations')));
      await tester.pumpAndSettle();
      await _menu(tester, 'Mesaj seç');
      await tester.tap(find.text('Tümünü seç'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('bulk-archive')));
      await tester.pumpAndSettle();
      expect(controller.archivedConversations, isEmpty);
      expect(controller.conversations.length, 3);
      expect(controller.conversation('mert')!.isPinned, isTrue);
    },
  );

  testWidgets(
    'arama değişince gizli seçim temizlenir ve yalnız görünen sohbet işlenir',
    (tester) async {
      final controller = await _start(tester);
      await _menu(tester, 'Mesaj seç');
      await tester.tap(find.byKey(const ValueKey('conversation-mert')));
      await tester.pump();
      await _query(tester, 'selin');
      expect(find.text('0 seçildi'), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(find.byKey(const Key('bulk-archive')))
            .onPressed,
        isNull,
      );
      await tester.tap(find.text('Tümünü seç'));
      await tester.pump();
      await tester.tap(find.byKey(const Key('bulk-archive')));
      await tester.pumpAndSettle();
      expect(controller.conversation('selin')!.isArchived, isTrue);
      expect(controller.conversation('mert')!.isArchived, isFalse);
      expect(controller.conversation('mert')!.unreadCount, 1);
    },
  );

  testWidgets(
    'arşiv araması kendi listesini filtreler ve seçimden çıkış değişiklik yapmaz',
    (tester) async {
      final controller = await _start(tester);
      await tester.tap(find.byKey(const Key('archived-conversations')));
      await tester.pumpAndSettle();
      await _query(tester, 'DENIZ AKIN');
      expect(find.byKey(const ValueKey('conversation-deniz')), findsOneWidget);
      await _menu(tester, 'Mesaj seç');
      await tester.tap(find.byKey(const ValueKey('select-conversation-deniz')));
      await tester.pump();
      await tester.tap(find.byTooltip('Seçimi kapat'));
      await tester.pumpAndSettle();
      expect(controller.conversation('deniz')!.isArchived, isTrue);
      expect(controller.conversation('deniz')!.unreadCount, 1);
      expect(find.byType(Checkbox), findsNothing);
      await _query(tester, 'mert');
      expect(find.text('Aramana uygun sohbet bulunamadı.'), findsOneWidget);
    },
  );
}
