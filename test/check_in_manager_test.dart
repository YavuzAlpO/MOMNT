import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:momnt/models/check_in_duration.dart';
import 'package:momnt/models/check_in_status.dart';
import 'package:momnt/services/location_service.dart';
import 'package:momnt/services/venue_service.dart';
import 'package:momnt/state/check_in_controller.dart';
import 'package:momnt/widgets/check_in_manager_sheet.dart';

class _Location extends LocationService {
  int calls = 0;
  bool denied = false;
  bool moved = false;

  @override
  Future<Position> getCurrentPosition() async {
    calls++;
    if (denied) {
      throw const LocationPermissionException('Konum izni reddedildi');
    }
    return Position(
      latitude: moved && calls > 1 ? 41.01 : 41,
      longitude: 29,
      timestamp: DateTime.now(),
      accuracy: 1,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }
}

Future<CheckInController> _open(
  WidgetTester tester,
  _Location location, {
  bool active = false,
}) async {
  final controller = CheckInController(locationService: location);
  if (active) {
    controller.tryCheckIn(
      venue: const VenueService()
          .discoverWithinRadius(userLatitude: 41, userLongitude: 29)
          .first
          .venue,
      status: CheckInStatus.working,
      distanceMeters: 10,
    );
  }
  // .value provider'ını kullanan CheckInScope controller'ı dispose etmez.
  await tester.pumpWidget(
    CheckInScope(
      controller: controller,
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => CheckInManagerSheet(locationService: location),
              ),
              child: const Text('+'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('+'));
  await tester.pumpAndSettle();
  return controller;
}

Future<void> _tap(WidgetTester tester, String label) async {
  final finder = find.text(label);
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _cleanup(WidgetTester tester, CheckInController controller) async {
  await tester.pumpWidget(const SizedBox.shrink());
  controller.dispose();
}

void main() {
  testWidgets('+ yönetimi konumla check-in başlatır, düzenler ve bitirir', (
    tester,
  ) async {
    final location = _Location();
    final controller = await _open(tester, location);
    expect(location.calls, 1);
    expect(find.text('Uzak Depo'), findsNothing);
    await _tap(tester, 'Moda Kahve');
    await _tap(tester, '30 dk');
    await _tap(tester, "Check-in'i Başlat");
    expect(location.calls, 2);
    expect(controller.session!.duration, CheckInDuration.halfHour);
    expect(find.text('Check-in yönetimi'), findsOneWidget);
    final original = controller.session!;
    await _tap(tester, 'Statüyü değiştir');
    await _tap(tester, 'Çalışıyorum');
    await _tap(tester, 'Değişiklikleri Kaydet');
    expect(controller.session!.status, CheckInStatus.working);
    expect(controller.session!.checkedInAt, original.checkedInAt);
    expect(controller.session!.expiresAt, original.expiresAt);
    expect(controller.lifetimeCheckInCount, 1);
    await _tap(tester, "Check-in'i Bitir");
    expect(controller.session, isNull);
    await _cleanup(tester, controller);
  });

  testWidgets('konum izni yoksa check-in başlamaz', (tester) async {
    final location = _Location()..denied = true;
    final controller = await _open(tester, location);
    expect(find.text('Konum izni reddedildi'), findsOneWidget);
    expect(find.text('Moda Kahve'), findsNothing);
    expect(controller.session, isNull);
    await _cleanup(tester, controller);
  });

  testWidgets('kaydetmeden önce uzaklaşılırsa güncel 30 m kontrolü reddeder', (
    tester,
  ) async {
    final location = _Location()..moved = true;
    final controller = await _open(tester, location);
    await _tap(tester, 'Moda Kahve');
    await _tap(tester, "Check-in'i Başlat");
    expect(location.calls, 2);
    expect(controller.session, isNull);
    expect(controller.lastError, contains('30 m'));
    await _cleanup(tester, controller);
  });

  testWidgets('aktif oturum yönetimi yeniden konum izni istemeden açılır', (
    tester,
  ) async {
    final location = _Location()..denied = true;
    final controller = await _open(tester, location, active: true);
    expect(find.text('Check-in yönetimi'), findsOneWidget);
    expect(location.calls, 0);
    expect(controller.lifetimeCheckInCount, 1);
    await _cleanup(tester, controller);
  });
}
