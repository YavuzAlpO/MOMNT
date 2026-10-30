import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momnt/models/check_in_status.dart';
import 'package:momnt/models/venue_model.dart';
import 'package:momnt/services/location_service.dart';
import 'package:momnt/services/venue_service.dart';
import 'package:momnt/state/check_in_controller.dart';
import 'package:momnt/widgets/active_check_in_card.dart';
import 'package:momnt/widgets/check_in_sheet.dart';

const _venue = Venue(
  id: 'moda-kahve',
  name: 'Moda Kahve',
  category: 'Kafe',
  latitude: 40.9875,
  longitude: 29.0258,
  activeUsersCount: 24,
);

void main() {
  testWidgets('check-in sheet örnek statüleri sunar ve seçimi döner', (
    tester,
  ) async {
    CheckInStatus? selected;

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
    expect(find.text('Çalışıyorum'), findsOneWidget);
    expect(find.text('Sosyalleşiyorum'), findsOneWidget);
    expect(find.text('Tanışmaya açığım'), findsOneWidget);

    await tester.tap(find.text('Çalışıyorum'));
    await tester.tap(find.text("Check-in'i Başlat"));
    await tester.pumpAndSettle();

    expect(selected, CheckInStatus.working);
  });

  testWidgets('aktif check-in kartı mekan ve statüyü gösterir', (tester) async {
    final controller = CheckInController();
    controller.tryCheckIn(
      venue: _venue,
      status: CheckInStatus.socializing,
      distanceMeters: 18,
    );

    await tester.pumpWidget(
      CheckInScope(
        controller: controller,
        child: MaterialApp(
          home: Scaffold(
            body: ActiveCheckInCard(session: controller.session!),
          ),
        ),
      ),
    );

    expect(find.text('Moda Kahve'), findsOneWidget);
    expect(find.text('Sosyalleşiyorum'), findsOneWidget);
    expect(find.text('Şu an buradasın'), findsOneWidget);
    controller.dispose();
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
