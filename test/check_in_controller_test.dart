import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
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

class _SessionLocation extends LocationService {
  Position activePosition = _position(_venue.latitude);
  int checks = 0;

  static Position _position(double latitude, {DateTime? timestamp}) => Position(
    latitude: latitude,
    longitude: _venue.longitude,
    timestamp: timestamp ?? DateTime.now(),
    accuracy: 5,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );

  @override
  Future<Position> getCurrentPosition() async => _position(_venue.latitude);

  @override
  Future<Position> getActiveCheckInPosition() async {
    checks++;
    return activePosition;
  }
}

void main() {
  testWidgets('canlı oturum uzaklaşınca konum kontrolünden otomatik kapanır', (
    tester,
  ) async {
    final location = _SessionLocation();
    final controller = CheckInController(locationService: location);
    try {
      expect(
        await controller.checkInWithLiveLocation(
          venue: _venue,
          status: CheckInStatus.working,
        ),
        isTrue,
      );
      await tester.pump(CheckInLifecycleRules.locationCheckInterval);
      expect(location.checks, 1);
      expect(controller.isCheckedIn, isTrue);

      controller.setForeground(false);
      location.activePosition = _SessionLocation._position(
        _venue.latitude + .02,
      );
      await tester.pump(CheckInLifecycleRules.locationCheckInterval);
      expect(location.checks, 1);
      controller.setForeground(true);
      await tester.pump();
      expect(controller.isCheckedIn, isFalse);
      expect(controller.lastError, contains('1 km'));
      await tester.pump(CheckInLifecycleRules.locationCheckInterval);
      expect(location.checks, 2);
    } finally {
      controller.dispose();
    }
  });

  test(
    'otomatik uzatma eski konumu reddeder ve yeni ölçümü kullanır',
    () async {
      final location = _SessionLocation()
        ..activePosition = _SessionLocation._position(
          _venue.latitude,
          timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
        );
      final controller = CheckInController(locationService: location);
      addTearDown(controller.dispose);
      final started = DateTime.now().subtract(const Duration(minutes: 56));
      controller.tryCheckIn(
        venue: _venue,
        status: CheckInStatus.working,
        distanceMeters: 10,
        now: started,
      );

      expect(await controller.checkAutoExtend(), isFalse);
      expect(
        controller.session!.expiresAt,
        started.add(const Duration(hours: 1)),
      );
      location.activePosition = _SessionLocation._position(_venue.latitude);
      expect(await controller.checkAutoExtend(), isTrue);
      expect(
        controller.session!.expiresAt,
        started.add(const Duration(hours: 2)),
      );
      expect(location.checks, 2);
    },
  );

  test('aynı mekanın check-in akışı da yeni süreyi mevcut oturuma uygular', () {
    final controller = CheckInController();
    addTearDown(controller.dispose);
    final started = DateTime.now();
    controller.tryCheckIn(
      venue: _venue,
      status: CheckInStatus.working,
      distanceMeters: 10,
      now: started,
    );
    final saved = started.add(const Duration(minutes: 10));
    expect(
      controller.tryCheckIn(
        venue: _venue,
        status: CheckInStatus.socializing,
        distanceMeters: 10,
        duration: CheckInDuration.twoHours,
        now: saved,
      ),
      isTrue,
    );
    expect(controller.session!.expiresAt, saved.add(const Duration(hours: 2)));
    expect(controller.session!.checkedInAt, started);
    expect(controller.session!.duration, CheckInDuration.twoHours);
    expect(controller.lifetimeCheckInCount, 1);
  });

  test('süresi dolmuş oturum süre düzenlenerek yeniden açılamaz', () {
    final controller = CheckInController();
    addTearDown(controller.dispose);
    final started = DateTime.now();
    controller.tryCheckIn(
      venue: _venue,
      status: CheckInStatus.working,
      distanceMeters: 10,
      now: started,
    );
    expect(
      controller.updateStatus(
        CheckInStatus.socializing,
        duration: CheckInDuration.twoHours,
        now: started.add(const Duration(hours: 1)),
      ),
      isFalse,
    );
    expect(controller.session, isNull);
    expect(controller.lifetimeCheckInCount, 1);
  });

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
    expect(
      controller.session!.expiresAt,
      started.add(const Duration(hours: 1)),
    );
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

  test('tam 1 km açık kalır ve eşik aşılınca check-out yapılır', () async {
    final controller = CheckInController();
    controller.tryCheckIn(
      venue: _venue,
      status: CheckInStatus.drinkingCoffee,
      distanceMeters: 12,
    );

    await controller.evaluateSession(
      distanceMeters: MomntLocationRules.autoExitDistanceMeters,
    );
    expect(controller.isCheckedIn, isTrue);
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
    final controller = CheckInController(presenceCheck: (_) async => false);
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
      duration: CheckInDuration.fourHours,
    );

    controller.endCheckIn();

    expect(controller.session, isNull);
    controller.dispose();
  });

  testWidgets('dört saatlik oturum zamanlayıcıyla kendiliğinden kapanır', (
    tester,
  ) async {
    final controller = CheckInController();
    addTearDown(controller.dispose);
    controller.tryCheckIn(
      venue: _venue,
      status: CheckInStatus.working,
      distanceMeters: 12,
      duration: CheckInDuration.fourHours,
    );

    const step = Duration(milliseconds: 1);
    await tester.pump(MomntLocationRules.sessionTimeout - step);
    expect(controller.isCheckedIn, isTrue);
    await tester.pump(step);
    expect(controller.isCheckedIn, isFalse);
    expect(controller.lastError, 'Check-in süresi doldu.');
  });

  test('statü düzenlenirken süre de değişir ve sayaç o andan başlar', () {
    final controller = CheckInController();
    addTearDown(controller.dispose);
    final started = DateTime.now();
    controller.tryCheckIn(
      venue: _venue,
      status: CheckInStatus.working,
      distanceMeters: 12,
      now: started,
    );
    final edited = started.add(const Duration(minutes: 20));
    controller.updateStatus(
      CheckInStatus.socializing,
      duration: CheckInDuration.twoHours,
      now: edited,
    );

    expect(controller.session!.status, CheckInStatus.socializing);
    expect(controller.session!.duration, CheckInDuration.twoHours);
    expect(controller.session!.expiresAt, edited.add(const Duration(hours: 2)));
    expect(controller.session!.checkedInAt, started);
    expect(controller.lifetimeCheckInCount, 1);

    final expiry = controller.session!.expiresAt;
    controller.updateStatus(
      CheckInStatus.working,
      duration: CheckInDuration.twoHours,
      now: edited.add(const Duration(minutes: 10)),
    );
    expect(controller.session!.expiresAt, expiry);
  });

  test('süre düzenleme toplam 4 saat sınırını sıfırlamaz', () {
    final controller = CheckInController();
    addTearDown(controller.dispose);
    final started = DateTime.now();
    controller.tryCheckIn(
      venue: _venue,
      status: CheckInStatus.working,
      distanceMeters: 12,
      duration: CheckInDuration.twoHours,
      now: started,
    );
    controller.updateStatus(
      CheckInStatus.working,
      duration: CheckInDuration.fourHours,
      now: started.add(const Duration(hours: 1)),
    );
    expect(
      controller.session!.expiresAt,
      started.add(MomntLocationRules.sessionTimeout),
    );
  });
}
