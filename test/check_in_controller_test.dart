import 'package:flutter_test/flutter_test.dart';
import 'package:momnt/models/check_in_duration.dart';
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
  test('30 m içindeki check-in oturumu varsayılan 1 saat sürer', () {
    final controller = CheckInController();
    final started = DateTime(2026, 11, 3, 18);
    final ok = controller.tryCheckIn(
      venue: _venue,
      status: CheckInStatus.working,
      distanceMeters: 18,
      now: started,
    );

    expect(ok, isTrue);
    expect(controller.session!.duration, CheckInDuration.oneHour);
    expect(controller.session!.expiresAt, started.add(const Duration(hours: 1)));
    expect(controller.lifetimeCheckInCount, 1);
    controller.dispose();
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
    controller.dispose();
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
    controller.dispose();
  });

  test('1 km uzaklaşma otomatik check-out yapar', () async {
    final controller = CheckInController();
    controller.tryCheckIn(
      venue: _venue,
      status: CheckInStatus.drinkingCoffee,
      distanceMeters: 12,
    );

    await controller.evaluateSession(
      distanceMeters: MomntLocationRules.autoExitDistanceMeters + 1,
    );

    expect(controller.session, isNull);
    expect(controller.lastError, contains('1 km'));
    controller.dispose();
  });

  test('seçilen süre dolunca oturum kapanır', () async {
    final controller = CheckInController();
    final started = DateTime(2026, 11, 3, 18);
    controller.tryCheckIn(
      venue: _venue,
      status: CheckInStatus.working,
      distanceMeters: 12,
      now: started,
    );

    await controller.evaluateSession(
      distanceMeters: 12,
      now: started.add(const Duration(hours: 1)),
    );

    expect(controller.session, isNull);
    expect(controller.lastError, contains('süresi doldu'));
    controller.dispose();
  });

  test('süre bitimine 5 dk kala mekândaysa 1 saat uzar', () async {
    final controller = CheckInController();
    final started = DateTime(2026, 11, 3, 18);
    controller.tryCheckIn(
      venue: _venue,
      status: CheckInStatus.drinkingCoffee,
      distanceMeters: 12,
      now: started,
    );

    final extended = await controller.checkAutoExtend(
      now: started.add(const Duration(minutes: 55)),
      stillAtVenue: true,
    );

    expect(extended, isTrue);
    expect(
      controller.session!.expiresAt,
      started.add(const Duration(hours: 2)),
    );
    expect(controller.session!.autoExtendCount, 1);
    expect(controller.lastNotice, contains('1 saat'));
    controller.dispose();
  });

  test('5 dk kala mekânda değilse süre uzamaz', () async {
    final controller = CheckInController(
      presenceCheck: (_) async => false,
    );
    final started = DateTime(2026, 11, 3, 18);
    controller.tryCheckIn(
      venue: _venue,
      status: CheckInStatus.working,
      distanceMeters: 12,
      now: started,
    );

    final extended = await controller.checkAutoExtend(
      now: started.add(const Duration(minutes: 55)),
      stillAtVenue: false,
    );

    expect(extended, isFalse);
    expect(
      controller.session!.expiresAt,
      started.add(const Duration(hours: 1)),
    );
    controller.dispose();
  });

  test('manuel Check-in Bitir oturumu kapatır', () {
    final controller = CheckInController();
    controller.tryCheckIn(
      venue: _venue,
      status: CheckInStatus.socializing,
      distanceMeters: 10,
      duration: CheckInDuration.unlimited,
    );

    controller.endCheckIn();

    expect(controller.session, isNull);
    controller.dispose();
  });

  test('süresiz oturum zaman aşımına düşmez', () async {
    final controller = CheckInController();
    final started = DateTime(2026, 11, 3, 18);
    controller.tryCheckIn(
      venue: _venue,
      status: CheckInStatus.working,
      distanceMeters: 12,
      duration: CheckInDuration.unlimited,
      now: started,
    );

    await controller.evaluateSession(
      distanceMeters: 12,
      now: started.add(const Duration(days: 2)),
    );

    expect(controller.isCheckedIn, isTrue);
    expect(controller.session!.isUnlimited, isTrue);
    controller.dispose();
  });
}
