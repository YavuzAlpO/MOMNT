import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:momnt/models/check_in_session.dart';
import 'package:momnt/models/check_in_status.dart';
import 'package:momnt/models/venue_model.dart';
import 'package:momnt/services/location_service.dart';

enum CheckOutReason { manual, autoExit, timeout }

class CheckInController extends ChangeNotifier {
  CheckInController({
    LocationService locationService = const LocationService(),
  }) : _locationService = locationService;

  final LocationService _locationService;

  CheckInSession? session;
  String? lastError;
  int lifetimeCheckInCount = 0;
  Timer? _timeoutTimer;

  bool get isCheckedIn => session != null;

  bool isCheckedInAt(String venueId) => session?.isAtVenue(venueId) ?? false;

  /// 30 m kuralını uygulayarak check-in başlatır veya aynı mekanda statüyü günceller.
  bool tryCheckIn({
    required Venue venue,
    required CheckInStatus status,
    required double distanceMeters,
    DateTime? now,
  }) {
    lastError = null;

    if (!_locationService.canCheckIn(distanceMeters)) {
      lastError =
          'Check-in için mekana en fazla ${MomntLocationRules.checkInProximityMeters.round()} m uzaklıkta olmalısın.';
      notifyListeners();
      return false;
    }

    final checkedInAt = session?.isAtVenue(venue.id) == true
        ? session!.checkedInAt
        : (now ?? DateTime.now());

    final isNewSession = session?.isAtVenue(venue.id) != true;
    session = CheckInSession(
      venueId: venue.id,
      venueName: venue.name,
      venueLatitude: venue.latitude,
      venueLongitude: venue.longitude,
      status: status,
      checkedInAt: checkedInAt,
    );
    if (isNewSession) {
      lifetimeCheckInCount += 1;
    }
    _scheduleTimeout(now: now);
    notifyListeners();
    return true;
  }

  /// Canlı konum ile 30 m kuralını doğrular, ardından oturumu açar.
  Future<bool> checkInWithLiveLocation({
    required Venue venue,
    required CheckInStatus status,
  }) async {
    lastError = null;
    try {
      final position = await _locationService.getCurrentPosition();
      final distance = _locationService.distanceBetweenMeters(
        startLatitude: position.latitude,
        startLongitude: position.longitude,
        endLatitude: venue.latitude,
        endLongitude: venue.longitude,
      );
      return tryCheckIn(
        venue: venue,
        status: status,
        distanceMeters: distance,
      );
    } on LocationServiceDisabledException {
      lastError = 'Konum servisi kapalı. Lütfen cihaz ayarlarından aç.';
      notifyListeners();
      return false;
    } on LocationPermissionException catch (error) {
      lastError = error.message;
      notifyListeners();
      return false;
    } catch (error) {
      lastError = 'Konum alınamadı: $error';
      notifyListeners();
      return false;
    }
  }

  void updateStatus(CheckInStatus status) {
    if (session == null) return;
    session = session!.copyWith(status: status);
    notifyListeners();
  }

  /// 1 km otomatik çıkış ve 4 saat zaman aşımını uygular.
  void evaluateSession({
    required double distanceMeters,
    DateTime? now,
  }) {
    if (session == null) return;
    if (_locationService.isSessionTimedOut(session!.checkedInAt, now: now)) {
      checkOut(reason: CheckOutReason.timeout);
      return;
    }
    if (_locationService.shouldAutoExit(distanceMeters)) {
      checkOut(reason: CheckOutReason.autoExit);
    }
  }

  void checkOut({CheckOutReason reason = CheckOutReason.manual}) {
    if (session == null) return;
    session = null;
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    lastError = switch (reason) {
      CheckOutReason.manual => null,
      CheckOutReason.autoExit =>
        'Mekana 1 km’den fazla uzaklaştığın için check-out yapıldı.',
      CheckOutReason.timeout =>
        '4 saat dolduğu için check-in oturumu sona erdi.',
    };
    notifyListeners();
  }

  void _scheduleTimeout({DateTime? now}) {
    _timeoutTimer?.cancel();
    final current = session;
    if (current == null) return;
    final remaining = MomntLocationRules.sessionTimeout -
        (now ?? DateTime.now()).difference(current.checkedInAt);
    if (remaining <= Duration.zero) {
      checkOut(reason: CheckOutReason.timeout);
      return;
    }
    _timeoutTimer = Timer(remaining, () {
      checkOut(reason: CheckOutReason.timeout);
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }
}

class CheckInScope extends InheritedNotifier<CheckInController> {
  const CheckInScope({
    super.key,
    required CheckInController controller,
    required super.child,
  }) : super(notifier: controller);

  static CheckInController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<CheckInScope>();
    assert(scope != null, 'CheckInScope bulunamadı.');
    return scope!.notifier!;
  }
}
