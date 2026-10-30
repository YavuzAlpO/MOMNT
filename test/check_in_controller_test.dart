import 'package:flutter_test/flutter_test.dart';
import 'package:momnt/models/check_in_status.dart';
import 'package:momnt/models/venue_model.dart';
import 'package:momnt/services/location_service.dart';
import 'package:momnt/state/check_in_controller.dart';

const _venue = Venue(
  id: 'moda-kahve',
  name: 'Moda Kahve',
  category: 'Kafe',
  latitude: 40.9875,
  longitude: 29.0258,
  activeUsersCount: 24,
);

void main() {
  test('30 m içindeki check-in oturumu ve statüyü kaydeder', () {
    final controller = CheckInController();
    final ok = controller.tryCheckIn(
      venue: _venue,
      status: CheckInStatus.working,
      distanceMeters: 18,
    );

    expect(ok, isTrue);
    expect(controller.isCheckedInAt('moda-kahve'), isTrue);
    expect(controller.session!.status, CheckInStatus.working);
    expect(controller.lifetimeCheckInCount, 1);
  });

  test('aynı mekanda statü değişince yeni check-in sayılmaz', () {
    final controller = CheckInController();
    controller.tryCheckIn(
      venue: _venue,
      status: CheckInStatus.drinkingCoffee,
      distanceMeters: 10,
    );
    controller.updateStatus(CheckInStatus.socializing);

    expect(controller.session!.status, CheckInStatus.socializing);
    expect(controller.lifetimeCheckInCount, 1);
  });

  test('30 m dışındaki check-in reddedilir', () {
    final controller = CheckInController();
    final ok = controller.tryCheckIn(
      venue: _venue,
      status: CheckInStatus.drinkingCoffee,
      distanceMeters: MomntLocationRules.checkInProximityMeters + 1,
    );

    expect(ok, isFalse);
    expect(controller.session, isNull);
    expect(controller.lastError, isNotNull);
  });

  test('1 km uzaklaşma otomatik check-out yapar', () {
    final controller = CheckInController();
    controller.tryCheckIn(
      venue: _venue,
      status: CheckInStatus.drinkingCoffee,
      distanceMeters: 12,
    );

    controller.evaluateSession(
      distanceMeters: MomntLocationRules.autoExitDistanceMeters + 1,
    );

    expect(controller.session, isNull);
    expect(controller.lastError, contains('1 km'));
  });

  test('4 saat dolunca oturum kapanır', () {
    final controller = CheckInController();
    final started = DateTime(2026, 10, 30, 10);
    controller.tryCheckIn(
      venue: _venue,
      status: CheckInStatus.working,
      distanceMeters: 12,
      now: started,
    );

    controller.evaluateSession(
      distanceMeters: 12,
      now: started.add(MomntLocationRules.sessionTimeout),
    );

    expect(controller.session, isNull);
    expect(controller.lastError, contains('4 saat'));
  });
}
