import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:momnt/models/check_in_duration.dart';
import 'package:momnt/models/check_in_session.dart';
import 'package:momnt/models/check_in_status.dart';
import 'package:momnt/models/venue_model.dart';
import 'package:momnt/services/location_service.dart';
import 'package:provider/provider.dart';

enum CheckOutReason { manual, autoExit, timeout }

/// K-145: varsayımsal konum kontrolü — mekânda mı?
typedef VenuePresenceCheck = Future<bool> Function(CheckInSession session);

/// Varsayılan demo kontrolü: kullanıcı hâlâ mekânda kabul edilir.
Future<bool> hypotheticalIsStillAtVenue(CheckInSession session) async {
  return true;
}

/// Provider / Cubit ile paylaşılabilen check-in yaşam döngüsü (ChangeNotifier).
class CheckInController extends ChangeNotifier {
  CheckInController({
    LocationService locationService = const LocationService(),
    VenuePresenceCheck presenceCheck = hypotheticalIsStillAtVenue,
  })  : _locationService = locationService,
        _presenceCheck = presenceCheck;

  final LocationService _locationService;
  final VenuePresenceCheck _presenceCheck;

  CheckInSession? session;
  String? lastError;
  String? lastNotice;
  int lifetimeCheckInCount = 0;
  Timer? _timeoutTimer;
  Timer? _extendTimer;

  bool get isCheckedIn => session != null;

  bool isCheckedInAt(String venueId) => session?.isAtVenue(venueId) ?? false;

  /// 30 m kuralını uygulayarak check-in başlatır veya aynı mekanda statüyü günceller.
  bool tryCheckIn({
    required Venue venue,
    required CheckInStatus status,
    required double distanceMeters,
    CheckInDuration duration = CheckInDuration.defaultValue,
    DateTime? now,
  }) {
    lastError = null;
    lastNotice = null;

    if (!_locationService.canCheckIn(distanceMeters)) {
      lastError =
          'Check-in için mekana en fazla ${MomntLocationRules.checkInProximityMeters.round()} m uzaklıkta olmalısın.';
      notifyListeners();
      return false;
    }

    final clock = now ?? DateTime.now();
    final isNewSession = session?.isAtVenue(venue.id) != true;
    final checkedInAt =
        isNewSession ? clock : session!.checkedInAt;
    final selectedDuration =
        isNewSession ? duration : session!.duration;
    final expiresAt = isNewSession
        ? selectedDuration.expiresAtFrom(checkedInAt)
        : session!.expiresAt;

    session = CheckInSession(
      venueId: venue.id,
      venueName: venue.name,
      venueLatitude: venue.latitude,
      venueLongitude: venue.longitude,
      status: status,
      checkedInAt: checkedInAt,
      duration: selectedDuration,
      expiresAt: expiresAt,
      autoExtendCount: isNewSession ? 0 : session!.autoExtendCount,
    );
    if (isNewSession) {
      lifetimeCheckInCount += 1;
    }
    _scheduleLifecycle(now: clock);
    notifyListeners();
    return true;
  }

  /// Canlı konum ile 30 m kuralını doğrular, ardından oturumu açar.
  Future<bool> checkInWithLiveLocation({
    required Venue venue,
    required CheckInStatus status,
    CheckInDuration duration = CheckInDuration.defaultValue,
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
        duration: duration,
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

  /// K-145: süre bitimine 5 dk kala mekândaysa oturumu 1 saat uzatır.
  Future<bool> checkAutoExtend({
    DateTime? now,
    bool? stillAtVenue,
  }) async {
    final current = session;
    if (current == null || current.isUnlimited) return false;
    if (!current.isWithinAutoExtendWindow(now: now)) return false;

    final present =
        stillAtVenue ?? await _presenceCheck(current);
    if (session == null) return false;
    if (!present) return false;

    final clock = now ?? DateTime.now();
    session = current.copyWith(
      expiresAt: current.expiresAt!.add(CheckInLifecycleRules.autoExtendBy),
      autoExtendCount: current.autoExtendCount + 1,
    );
    lastNotice = 'Mekânda olduğun için süre 1 saat uzatıldı.';
    _scheduleLifecycle(now: clock);
    notifyListeners();
    return true;
  }

  /// K-147: 1 km otomatik çıkış; süre dolduysa timeout; 5 dk kala uzatma dener.
  Future<void> evaluateSession({
    required double distanceMeters,
    DateTime? now,
    bool? stillAtVenue,
  }) async {
    if (session == null) return;
    if (_locationService.shouldAutoExit(distanceMeters)) {
      checkOut(reason: CheckOutReason.autoExit);
      return;
    }
    if (session!.isExpired(now: now)) {
      checkOut(reason: CheckOutReason.timeout);
      return;
    }
    if (session!.isWithinAutoExtendWindow(now: now)) {
      final atVenue = stillAtVenue ??
          _locationService.canCheckIn(distanceMeters);
      await checkAutoExtend(now: now, stillAtVenue: atVenue);
    }
  }

  /// K-147: kullanıcı 'Check-in'i Bitir' ile oturumu kapatır.
  void endCheckIn() => checkOut(reason: CheckOutReason.manual);

  void checkOut({CheckOutReason reason = CheckOutReason.manual}) {
    if (session == null) return;
    session = null;
    _timeoutTimer?.cancel();
    _extendTimer?.cancel();
    _timeoutTimer = null;
    _extendTimer = null;
    lastNotice = null;
    lastError = switch (reason) {
      CheckOutReason.manual => null,
      CheckOutReason.autoExit =>
        'Mekana 1 km’den fazla uzaklaştığın için check-out yapıldı.',
      CheckOutReason.timeout => 'Check-in süresi doldu.',
    };
    notifyListeners();
  }

  void _scheduleLifecycle({DateTime? now}) {
    _timeoutTimer?.cancel();
    _extendTimer?.cancel();
    final current = session;
    if (current == null || current.isUnlimited || current.expiresAt == null) {
      return;
    }

    final clock = now ?? DateTime.now();
    if (current.isExpired(now: clock)) {
      checkOut(reason: CheckOutReason.timeout);
      return;
    }

    final remaining = current.expiresAt!.difference(clock);
    final untilExtendWindow =
        remaining - CheckInLifecycleRules.autoExtendWindow;
    if (untilExtendWindow > Duration.zero) {
      _extendTimer = Timer(untilExtendWindow, () {
        unawaited(checkAutoExtend());
      });
    }

    _timeoutTimer = Timer(remaining, () {
      final live = session;
      if (live == null || live.isUnlimited) return;
      if (live.isExpired()) {
        checkOut(reason: CheckOutReason.timeout);
      }
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _extendTimer?.cancel();
    super.dispose();
  }
}

class CheckInScope extends StatelessWidget {
  const CheckInScope({
    super.key,
    required this.controller,
    required this.child,
  });

  final CheckInController controller;
  final Widget child;

  static CheckInController of(BuildContext context) {
    return Provider.of<CheckInController>(context);
  }

  static CheckInController read(BuildContext context) {
    return Provider.of<CheckInController>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CheckInController>.value(
      value: controller,
      child: child,
    );
  }
}
