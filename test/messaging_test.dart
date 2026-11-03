import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momnt/models/mutual_follow_profile.dart';
import 'package:momnt/screens/messages_tab_screen.dart';
import 'package:momnt/state/messages_controller.dart';
import 'package:provider/provider.dart';

const _contacts = [
  MutualFollowProfile(
    id: 'mert-yilmaz',
    name: 'Mert Yılmaz',
    username: '@mert',
  ),
  MutualFollowProfile(id: 'selin-kaya', name: 'Selin Kaya', username: '@selin'),
  MutualFollowProfile(id: 'deniz', name: 'Deniz Akın', username: '@deniz'),
];

Future<MessagesController> _start(WidgetTester tester) async {
  final controller = MessagesController.demo(contacts: _contacts);
  await tester.pumpWidget(
    ChangeNotifierProvider<MessagesController>(
      create: (_) => controller,
      child: const MaterialApp(home: Scaffold(body: MessagesTabScreen())),
    ),
  );
  return controller;
}

Future<void> _open(WidgetTester tester, String id) async {
  await tester.tap(find.byKey(ValueKey('conversation-$id')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'yalnız açılan sohbet okunur, okuma zamanı korunur ve giden mesaj görülmüş sayılmaz',
    (tester) async {
      final messages = await _start(tester);
      await _open(tester, 'selin-kaya');
      expect(messages.conversation('mert-yilmaz')!.unreadCount, 1);
      expect(
        messages.conversation('mert-yilmaz')!.messages.first.readAt,
        isNull,
      );
      await tester.pageBack();
      await tester.pumpAndSettle();

      await _open(tester, 'mert-yilmaz');
      final readAt = messages
          .conversation('mert-yilmaz')!
          .messages
          .first
          .readAt;
      expect(readAt, isNotNull);
      expect(messages.conversation('mert-yilmaz')!.unreadCount, 0);
      expect(find.text('Okundu'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('chat-input')), 'Yeni mesaj');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(
        messages.conversation('mert-yilmaz')!.messages.last.readAt,
        isNull,
      );
      expect(find.text('Görüldü'), findsNothing);
      expect(find.text('Cihazda'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await _open(tester, 'mert-yilmaz');
      expect(
        messages.conversation('mert-yilmaz')!.messages.first.readAt,
        readAt,
      );
      expect(
        messages.conversation('mert-yilmaz')!.messages.last.readAt,
        isNull,
      );
    },
  );

  testWidgets(
    'Enter gönderir, Shift+Enter alt satır açar ve boş Enter göndermez',
    (tester) async {
      final messages = await _start(tester);
      await _open(tester, 'mert-yilmaz');
      final input = find.byKey(const Key('chat-input'));
      await tester.enterText(input, 'Enter mesajı');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(
        messages.conversation('mert-yilmaz')!.messages.last.text,
        'Enter mesajı',
      );
      expect(tester.widget<TextField>(input).controller!.text, isEmpty);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(messages.conversation('mert-yilmaz')!.messages.length, 2);

      await tester.enterText(input, 'İlk satır');
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();
      expect(tester.widget<TextField>(input).controller!.text, 'İlk satır\n');
      expect(messages.conversation('mert-yilmaz')!.messages.length, 2);
      await tester.sendKeyEvent(LogicalKeyboardKey.numpadEnter);
      await tester.pumpAndSettle();
      expect(
        messages.conversation('mert-yilmaz')!.messages.last.text,
        'İlk satır',
      );
    },
  );

  testWidgets('telefon klavyesindeki gönder eylemi mesajı bir kez gönderir', (
    tester,
  ) async {
    final messages = await _start(tester);
    await _open(tester, 'mert-yilmaz');
    await tester.enterText(
      find.byKey(const Key('chat-input')),
      'Telefondan mesaj',
    );
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();
    expect(messages.conversation('mert-yilmaz')!.messages.length, 2);
    expect(
      messages.conversation('mert-yilmaz')!.messages.last.text,
      'Telefondan mesaj',
    );
  });

  testWidgets(
    'sohbet açılır, mesaj gönderilir ve geri dönünce listede korunur',
    (tester) async {
      final messages = await _start(tester);
      expect(messages.conversation('mert-yilmaz')!.unreadCount, 1);
      await _open(tester, 'mert-yilmaz');
      expect(messages.conversation('mert-yilmaz')!.unreadCount, 0);
      expect(find.textContaining('karşı tarafa iletilmez'), findsOneWidget);
      expect(
        tester.widget<IconButton>(find.byKey(const Key('chat-send'))).onPressed,
        isNull,
      );

      await tester.enterText(
        find.byKey(const Key('chat-input')),
        '   Selam Mert!   ',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('chat-send')));
      await tester.pumpAndSettle();
      expect(find.text('Selam Mert!'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('chat-input')))
            .controller!
            .text,
        isEmpty,
      );
      expect(
        messages.conversation('mert-yilmaz')!.messages.last.isMine,
        isTrue,
      );
      expect(messages.conversation('selin-kaya')!.messages.length, 1);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Selam Mert!'), findsOneWidget);
      expect(messages.conversations.first.contact.id, 'mert-yilmaz');
      await _open(tester, 'mert-yilmaz');
      expect(find.text('Selam Mert!'), findsOneWidget);
    },
  );

  testWidgets('yeni kişiye sohbet ve taslak kişiye özel korunur', (
    tester,
  ) async {
    final messages = await _start(tester);
    await tester.tap(find.byTooltip('Yeni sohbet'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deniz Akın'));
    await tester.pumpAndSettle();
    expect(find.text('Sohbeti ilk mesajınla başlat.'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('chat-input')),
      'Akşam görüşelim mi?',
    );
    await tester.pageBack();
    await tester.pumpAndSettle();

    await _open(tester, 'selin-kaya');
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('chat-input')))
          .controller!
          .text,
      isEmpty,
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    await _open(tester, 'deniz');
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('chat-input')))
          .controller!
          .text,
      'Akşam görüşelim mi?',
    );
    await tester.tap(find.byKey(const Key('chat-send')));
    await tester.pumpAndSettle();
    expect(messages.conversation('deniz')!.messages.length, 1);
    expect(messages.draft('deniz'), isEmpty);
    expect(messages.conversation('selin-kaya')!.messages.length, 1);
  });

  testWidgets('dar ekranda uzun mesaj ve boş mesaj kontrolü', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final messages = await _start(tester);
    await _open(tester, 'mert-yilmaz');
    await tester.enterText(find.byKey(const Key('chat-input')), ' \n  ');
    await tester.pump();
    expect(
      tester.widget<IconButton>(find.byKey(const Key('chat-send'))).onPressed,
      isNull,
    );
    expect(messages.sendMessage('mert-yilmaz', ' \n '), isFalse);
    final longText = List.filled(40, 'Uzun mesaj').join(' ');
    await tester.enterText(find.byKey(const Key('chat-input')), longText);
    await tester.pump();
    await tester.tap(find.byKey(const Key('chat-send')));
    await tester.pumpAndSettle();
    expect(messages.conversation('mert-yilmaz')!.messages.length, 2);
    expect(find.text(longText), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
