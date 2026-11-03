import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momnt/models/chat_attachment.dart';
import 'package:momnt/models/chat_message.dart';
import 'package:momnt/models/mutual_follow_profile.dart';
import 'package:momnt/screens/messages_tab_screen.dart';
import 'package:momnt/state/messages_controller.dart';
import 'package:provider/provider.dart';

const _mert = MutualFollowProfile(
  id: 'mert-yilmaz',
  name: 'Mert Yılmaz',
  username: '@mert',
);
const _selin = MutualFollowProfile(
  id: 'selin-kaya',
  name: 'Selin Kaya',
  username: '@selin',
);

Future<MessagesController> _start(WidgetTester tester) async {
  final controller = MessagesController.demo(contacts: const [_mert, _selin]);
  await tester.pumpWidget(
    ChangeNotifierProvider<MessagesController>(
      create: (_) => controller,
      child: const MaterialApp(home: Scaffold(body: MessagesTabScreen())),
    ),
  );
  return controller;
}

Future<void> _action(WidgetTester tester, String id, String label) async {
  await tester.tap(find.byKey(ValueKey('conversation-options-$id')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'sabitlenen eski sohbet yeni mesajlardan önce kalır; sabitleme geri alınır',
    (tester) async {
      final controller = await _start(tester);
      await _action(tester, _selin.id, 'Sabitle');
      expect(controller.conversations.first.contact.id, _selin.id);
      expect(find.byTooltip('Sabitlenmiş sohbet'), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(ValueKey('conversation-${_selin.id}'))).dy,
        lessThan(
          tester
              .getTopLeft(find.byKey(ValueKey('conversation-${_mert.id}')))
              .dy,
        ),
      );
      controller.sendMessage(_mert.id, 'Daha yeni mesaj');
      await tester.pumpAndSettle();
      expect(controller.conversations.first.contact.id, _selin.id);
      expect(controller.conversation(_selin.id)!.messages.length, 1);
      await _action(tester, _selin.id, 'Sabitlemeyi kaldır');
      expect(controller.conversations.first.contact.id, _mert.id);
      expect(find.byTooltip('Sabitlenmiş sohbet'), findsNothing);
    },
  );

  testWidgets(
    'arşivle, arşivde sohbet açıp gönder ve arşivden çıkar mesajları korur',
    (tester) async {
      final controller = await _start(tester);
      await _action(tester, _selin.id, 'Sabitle');
      await _action(tester, _selin.id, 'Arşivle');
      expect(find.byKey(ValueKey('conversation-${_selin.id}')), findsNothing);
      expect(controller.archivedConversations.single.contact.id, _selin.id);
      await tester.tap(find.byKey(const Key('archived-conversations')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('conversation-${_selin.id}')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('chat-input')),
        'Arşivdeki mesaj',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Arşivdeki mesaj'), findsOneWidget);
      expect(controller.conversation(_selin.id)!.isArchived, isTrue);
      expect(controller.conversation(_selin.id)!.isPinned, isTrue);
      await _action(tester, _selin.id, 'Arşivden çıkar');
      expect(find.text('Arşivlenmiş sohbetin yok.'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Arşivdeki mesaj'), findsOneWidget);
      expect(controller.conversations.first.contact.id, _selin.id);
      expect(controller.conversation(_selin.id)!.messages.length, 2);
    },
  );

  testWidgets(
    'basılı tutarak tüm sohbetler arşivlenebilir ve ana listede boş durum görünür',
    (tester) async {
      final controller = await _start(tester);
      await tester.longPress(find.byKey(ValueKey('conversation-${_mert.id}')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Arşivle'));
      await tester.pumpAndSettle();
      expect(controller.conversation(_mert.id)!.unreadCount, 1);
      await _action(tester, _selin.id, 'Arşivle');
      expect(controller.conversations, isEmpty);
      expect(find.byKey(const Key('archived-conversations')), findsOneWidget);
      expect(find.textContaining('Sohbetlerine arşivlenmiş'), findsOneWidget);
      await tester.tap(find.byKey(const Key('archived-conversations')));
      await tester.pumpAndSettle();
      expect(controller.archivedConversations.length, 2);
      await _action(tester, _mert.id, 'Arşivden çıkar');
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey('conversation-${_mert.id}')), findsOneWidget);
      expect(find.byKey(ValueKey('conversation-${_selin.id}')), findsNothing);
      expect(controller.conversation(_mert.id)!.unreadCount, 1);
    },
  );

  test('okuma, gönderme ve tek seferlik fotoğraf tüketimi arşiv ve sabitlemeyi sıfırlamaz', () {
    final photo = ChatAttachment(
      kind: ChatAttachmentKind.image,
      name: 'foto.jpg',
      bytes: Uint8List.fromList([1, 2, 3]),
      mimeType: 'image/jpeg',
      photoVisibility: PhotoVisibility.viewOnce,
    );
    final controller = MessagesController(
      contacts: const [_mert],
      initialConversations: [
        ChatConversation(
          contact: _mert,
          isPinned: true,
          isArchived: true,
          unreadCount: 1,
          messages: [
            ChatMessage(
              id: 'photo',
              text: '',
              isMine: false,
              createdAt: DateTime.now(),
              attachment: photo,
            ),
          ],
        ),
      ],
    );
    addTearDown(controller.dispose);
    controller.setDraft(_mert.id, 'Taslak korunmalı');
    controller.openConversation(_mert.id);
    expect(controller.conversation(_mert.id)!.unreadCount, 0);
    expect(controller.claimViewOncePhoto(_mert.id, 'photo'), same(photo));
    expect(controller.conversation(_mert.id)!.isArchived, isTrue);
    expect(controller.conversation(_mert.id)!.isPinned, isTrue);
    expect(controller.draft(_mert.id), 'Taslak korunmalı');
    controller.sendMessage(_mert.id, 'Mesaj');
    expect(controller.conversations, isEmpty);
    expect(controller.archivedConversations.single.isPinned, isTrue);
    controller.setArchived(_mert.id, false);
    expect(controller.conversations.single.isPinned, isTrue);
    expect(
      controller.conversation(_mert.id)!.messages.first.attachment!.bytes,
      isEmpty,
    );
    expect(controller.conversation(_mert.id)!.messages.last.text, 'Mesaj');
  });
}
