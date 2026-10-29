import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momnt/main.dart';
import 'package:momnt/services/location_service.dart';
import 'package:momnt/services/venue_service.dart';

void main() {
  testWidgets('MOMNT kabuk, harita kartı ve check-in modalı', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('Ana Sayfa'), findsOneWidget);
    expect(find.text('Harita'), findsOneWidget);
    expect(find.text('İstekler'), findsOneWidget);
    expect(find.text('Mesajlar'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);
    expect(find.text('Moda Kahve'), findsWidgets);
    expect(find.text('24 kişi'), findsWidgets);
    expect(find.text('30 m içinde'), findsWidgets);

    await tester.tap(find.text('Harita'));
    await tester.pumpAndSettle();
    expect(find.text('Mekân ara'), findsOneWidget);
    expect(find.text('Check-in Yap'), findsWidgets);

    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('map-venue-card')),
        matching: find.text('Check-in Yap'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text("Just Chillin'"), findsOneWidget);
    expect(find.text('With My Crew'), findsOneWidget);
    expect(find.text('Open to Meet'), findsOneWidget);
    expect(find.text("Check-in'i Başlat"), findsOneWidget);
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
