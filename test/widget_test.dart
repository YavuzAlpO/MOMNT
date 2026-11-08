import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momnt/main.dart';
import 'package:momnt/models/check_in_duration.dart';
import 'package:momnt/models/check_in_status.dart';
import 'package:momnt/models/venue_model.dart';
import 'package:momnt/screens/home_tab_screen.dart';
import 'package:momnt/screens/map_tab_screen.dart';
import 'package:momnt/screens/messages_tab_screen.dart';
import 'package:momnt/screens/profile_tab_screen.dart';
import 'package:momnt/screens/requests_tab_screen.dart';
import 'package:momnt/services/demo_social_data.dart';
import 'package:momnt/services/location_service.dart';
import 'package:momnt/services/venue_service.dart';
import 'package:momnt/state/check_in_controller.dart';
import 'package:momnt/state/messages_controller.dart';
import 'package:momnt/widgets/active_check_in_card.dart';
import 'package:momnt/widgets/check_in_sheet.dart';
import 'package:provider/provider.dart';

const _venue = Venue(
  id: 'moda-kahve',
  name: 'Moda Kahve',
  category: 'Kafe',
  latitude: 40.9875,
  longitude: 29.0258,
  activeUsersCount: 24,
);

void main() {
  testWidgets('alt menü rozeti toplam okunmamış mesaj sayısını gösterir', (
    tester,
  ) async {
    final first = demoMutualFollows[0];
    final second = demoMutualFollows[1];
    final messages = MessagesController(
      contacts: demoMutualFollows,
      initialConversations: [
        ChatConversation(contact: first, unreadCount: 98),
        ChatConversation(contact: second, unreadCount: 3, isArchived: true),
      ],
    );
    addTearDown(messages.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: messages,
        child: const MaterialApp(home: MainNavigationScreen()),
      ),
    );

    final badge = find.byType(Badge);
    expect(find.descendant(of: badge, matching: find.text('99+')), findsOne);

    messages.openConversation(first.id);
    await tester.pump();
    expect(find.descendant(of: badge, matching: find.text('3')), findsOne);

    messages.markAllRead();
    await tester.pump();
    expect(badge, findsNothing);
  });

  testWidgets('sekmeler ilk ziyarette yüklenir ve arama durumu korunur', (
    tester,
  ) async {
    await tester.pumpWidget(const MomntApp());
    expect(find.byType(MapTabScreen), findsOneWidget);
    for (final screen in [
      HomeTabScreen,
      RequestsTabScreen,
      MessagesTabScreen,
      ProfileTabScreen,
    ]) {
      expect(find.byType(screen, skipOffstage: false), findsNothing);
    }

    await tester.tap(find.text('Mesajlar'));
    await tester.pumpAndSettle();
    final search = find.byKey(const Key('conversation-search'));
    await tester.enterText(search, 'Mert');

    await tester.tap(find.text('Harita'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mesajlar'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(search).controller!.text, 'Mert');
  });

  testWidgets('komşu sekme sürüklerken görünür ve bırakınca yerine oturur', (
    tester,
  ) async {
    const swipe = Offset(-520, 0);
    const content = Offset(650, 350);
    double? page() =>
        tester.widget<PageView>(find.byType(PageView)).controller!.page;

    final reportError = FlutterError.onError;
    FlutterError.onError = (details) {
      // The widget test HTTP client returns 400 for demo images.
      final error = details.exception;
      if (error is NetworkImageLoadException && error.statusCode == 400) return;
      reportError?.call(details);
    };

    try {
      await tester.pumpWidget(const MomntApp());
      expect(page(), 1);

      final gesture = await tester.startGesture(const Offset(120, 350));
      await gesture.moveBy(const Offset(180, 0));
      await tester.pump();
      expect(page(), allOf(greaterThan(0.5), lessThan(1)));
      expect(tester.getRect(find.byType(HomeTabScreen)).right, greaterThan(0));
      expect(tester.getRect(find.byType(MapTabScreen)).left, greaterThan(0));
      await gesture.moveBy(const Offset(340, 0));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(page(), 0);

      final stories = find.byKey(const Key('home-stories-area'));
      await tester.dragFrom(
        tester.getCenter(stories),
        const Offset(-180, 0),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pumpAndSettle();
      expect(page(), 0);

      for (final index in [1, 2, 3]) {
        await tester.dragFrom(content, swipe, kind: PointerDeviceKind.mouse);
        await tester.pumpAndSettle();
        expect(page(), index);
      }

      await tester.dragFrom(content, swipe);
      await tester.pumpAndSettle();
      expect(page(), 3);
    } finally {
      FlutterError.onError = reportError;
    }
  });

  testWidgets('check-in sheet statü ve süre seçimini döner', (tester) async {
    CheckInSelection? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () async {
                selected = await showCheckInSheet(
                  context: context,
                  venueName: 'Moda Kahve',
                );
              },
              child: const Text('open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Kahve içiyorum'), findsOneWidget);
    expect(find.text('1 saat'), findsOneWidget);
    expect(find.text('2 saat'), findsOneWidget);
    expect(find.text('30 dk'), findsOneWidget);
    expect(find.text('4 saat'), findsOneWidget);

    await tester.tap(find.text('Çalışıyorum'));
    await tester.tap(find.text('2 saat'));
    await tester.tap(find.text("Check-in'i Başlat"));
    await tester.pumpAndSettle();

    expect(selected?.status, CheckInStatus.working);
    expect(selected?.duration, CheckInDuration.twoHours);
  });

  testWidgets('aktif kart geri sayım ve bitir butonunu gösterir', (
    tester,
  ) async {
    final controller = CheckInController();
    controller.tryCheckIn(
      venue: _venue,
      status: CheckInStatus.socializing,
      distanceMeters: 18,
      now: DateTime.now(),
    );

    await tester.pumpWidget(
      CheckInScope(
        controller: controller,
        child: MaterialApp(
          home: Scaffold(
            body: ActiveCheckInCard(
              session: controller.session!,
              onCheckOut: controller.endCheckIn,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Moda Kahve'), findsOneWidget);
    expect(find.text('Sosyalleşiyorum'), findsOneWidget);
    expect(find.textContaining('Kalan süre'), findsOneWidget);
    expect(find.text("Check-in'i Bitir"), findsOneWidget);

    await tester.tap(find.text("Check-in'i Bitir"));
    await tester.pump();
    expect(controller.session, isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('4 saat seçiminde geri sayım gösterilir', (tester) async {
    final controller = CheckInController();
    controller.tryCheckIn(
      venue: _venue,
      status: CheckInStatus.working,
      distanceMeters: 18,
      duration: CheckInDuration.fourHours,
    );

    await tester.pumpWidget(
      CheckInScope(
        controller: controller,
        child: MaterialApp(
          home: Scaffold(body: ActiveCheckInCard(session: controller.session!)),
        ),
      ),
    );

    expect(find.textContaining('Kalan süre'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('düzenlemede mevcut süre seçilir ve değişiklik kaydedilir', (
    tester,
  ) async {
    CheckInSelection? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              selected = await showCheckInSheet(
                context: context,
                venueName: _venue.name,
                initialStatus: CheckInStatus.working,
                initialDuration: CheckInDuration.twoHours,
                isEditing: true,
              );
            },
            child: const Text('Düzenle'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Düzenle'));
    await tester.pumpAndSettle();
    final selectedChip = find.widgetWithText(ChoiceChip, '2 saat');
    expect(tester.widget<ChoiceChip>(selectedChip).selected, isTrue);
    await tester.tap(find.text('1 saat'));
    final save = find.text('Değişiklikleri Kaydet');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(selected?.status, CheckInStatus.working);
    expect(selected?.duration, CheckInDuration.oneHour);
  });

  test('20 km dışındaki mock mekan keşif listesine girmez', () {
    const service = VenueService();
    final nearby = service.discoverWithinRadius(
      userLatitude: 41.0369,
      userLongitude: 28.9850,
    );

    expect(nearby.length, 4);
    expect(nearby.every((item) => item.venue.id != 'uzak-depo'), isTrue);
    expect(
      nearby.every(
        (item) =>
            item.distanceMeters <= MomntLocationRules.discoveryRadiusMeters,
      ),
      isTrue,
    );
    expect(nearby.first.venue.id, 'moda-kahve');
    expect(nearby.first.venue.activeUsersCount, 24);
    expect(
      const LocationService().canCheckIn(nearby.first.distanceMeters),
      isTrue,
    );
  });
}
