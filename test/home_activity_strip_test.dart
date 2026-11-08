import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momnt/models/check_in_session.dart';
import 'package:momnt/models/check_in_status.dart';
import 'package:momnt/models/mutual_follow_profile.dart';
import 'package:momnt/screens/chat_screen.dart';
import 'package:momnt/state/messages_controller.dart';
import 'package:momnt/widgets/home_activity_strip.dart';
import 'package:momnt/widgets/home_stories.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('hikâye beğenisi korunur ve yanıt sahibinin sohbetine eklenir', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const mert = MutualFollowProfile(
      id: 'mert',
      name: 'Mert',
      username: '@mert',
    );
    final messages = MessagesController(contacts: const [mert]);
    addTearDown(messages.dispose);
    messages.setDraft(mert.id, 'Sohbet taslağı');
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: messages,
        child: const MaterialApp(
          home: Scaffold(
            body: HomeActivityStrip(
              stories: [
                HomeStory(
                  name: 'Mert',
                  contactId: 'mert',
                  avatarUrl: 'https://example.invalid/avatar',
                  imageUrl: 'https://example.invalid/story',
                  caption: 'Moda Kahve',
                ),
                HomeStory(
                  name: 'Ece',
                  avatarUrl: 'https://example.invalid/self-avatar',
                  imageUrl: 'https://example.invalid/self-story',
                  caption: 'Sahil Park',
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Mert'));
    await tester.pumpAndSettle();
    final send = find.byWidgetPredicate(
      (widget) => widget is IconButton && widget.tooltip == 'Yanıtı gönder',
    );
    expect(tester.widget<IconButton>(send).onPressed, isNull);
    await tester.tap(find.byTooltip('Hikâyeyi beğen'));
    await tester.pump();
    expect(find.byTooltip('Beğeniyi kaldır'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '  Çok iyi!  ');
    await tester.pump();
    await tester.tap(send);
    await tester.pumpAndSettle();
    final reply = messages.conversation(mert.id)!.messages.single;
    expect(reply.text, 'Çok iyi!');
    expect(reply.storyReply?.caption, 'Moda Kahve');
    expect(messages.draft(mert.id), 'Sohbet taslağı');
    expect(find.text('Yanıt sohbete eklendi.'), findsOneWidget);

    await tester.tap(find.byTooltip('Sonraki hikâye'));
    await tester.pumpAndSettle();
    expect(send, findsNothing);
    expect(find.byTooltip('Hikâyeyi beğen'), findsNothing);
    await tester.tap(find.byTooltip('Hikâyeyi kapat'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mert'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Beğeniyi kaldır'));
    await tester.pump();
    expect(find.byTooltip('Hikâyeyi beğen'), findsOneWidget);
    await tester.tap(find.byTooltip('Hikâyeyi kapat'));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(HomeActivityStrip));
    Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const ChatScreen(contactId: 'mert')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Hikâye yanıtı'), findsOneWidget);
    expect(find.text('Moda Kahve'), findsOneWidget);
    expect(find.text('Çok iyi!'), findsOneWidget);
  });

  testWidgets('görüntülenen hikâyeler şeridin sonuna taşınır', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HomeActivityStrip(
            stories: [
              HomeStory(
                name: 'Mert',
                avatarUrl: 'https://example.invalid/avatar',
                imageUrl: 'https://example.invalid/story',
                caption: 'Moda Kahve',
              ),
              HomeStory(
                name: 'Selin',
                avatarUrl: 'https://example.invalid/other-avatar',
                imageUrl: 'https://example.invalid/other-story',
                caption: 'Sahil Park',
              ),
              HomeStory(
                name: 'Deniz',
                avatarUrl: 'https://example.invalid/deniz-avatar',
                imageUrl: 'https://example.invalid/deniz-story',
                caption: 'Loft Bar',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('Mert'));
    await tester.pumpAndSettle();
    expect(find.text('Moda Kahve'), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);
    await tester.tap(find.byTooltip('Sonraki hikâye'));
    await tester.pumpAndSettle();
    expect(find.text('Sahil Park'), findsOneWidget);
    expect(find.text('2 / 3'), findsOneWidget);
    await tester.tap(find.byTooltip('Hikâyeyi kapat'));
    await tester.pumpAndSettle();
    expect(find.text('Hikâyeler'), findsOneWidget);
    final deniz = tester.getTopLeft(find.text('Deniz')).dx;
    final mert = tester.getTopLeft(find.text('Mert')).dx;
    final selin = tester.getTopLeft(find.text('Selin')).dx;
    expect(deniz, lessThan(mert));
    expect(mert, lessThan(selin));
  });

  for (final width in [320.0, 1200.0]) {
    testWidgets('check-in ve hikâyeler $width genişlikte yan yana sığar', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var opened = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeActivityStrip(
              mutualFollows: const [
                MutualFollowProfile(id: '1', name: 'Mert', username: '@mert'),
                MutualFollowProfile(id: '2', name: 'Selin', username: '@selin'),
              ],
              session: CheckInSession(
                venueId: 'venue',
                venueName: 'Uzun isimli örnek bir mekân',
                venueLatitude: 41,
                venueLongitude: 29,
                status: CheckInStatus.socializing,
                checkedInAt: DateTime.now(),
                expiresAt: DateTime.now().add(const Duration(hours: 1)),
              ),
              onManageCheckIn: () => opened = true,
            ),
          ),
        ),
      );
      final checkIn = find.byKey(const Key('home-compact-check-in'));
      final stories = find.byKey(const Key('home-stories-area'));
      expect(
        tester.getRect(checkIn).right,
        lessThan(tester.getRect(stories).left),
      );
      expect(tester.getSize(checkIn).height, 128);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('mutual-follow-group')));
      await tester.pump();
      expect(find.text('Takipleştiğin kişiler (2)'), findsOneWidget);
      expect(opened, isFalse);
      await tester.tap(find.byKey(const ValueKey('mutual-follow-group')));
      await tester.pump();
      await tester.tap(checkIn);
      expect(opened, isTrue);
      final previousWidth = tester.getSize(stories).width;
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: HomeActivityStrip())),
      );
      expect(checkIn, findsNothing);
      expect(tester.getSize(stories).width, width);
      expect(tester.getSize(stories).width, greaterThan(previousWidth));
      expect(tester.takeException(), isNull);
    });
  }
}
