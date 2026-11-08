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

typedef VenuePresenceCheck = Future<bool> Function(CheckInSession session);

/// Provider / Cubit ile paylaşılabilen check-in yaşam döngüsü (ChangeNotifier).
class CheckInController extends ChangeNotifier {
  CheckInController({
    LocationService locationService = const LocationService(),
    VenuePresenceCheck? presenceCheck,
  }) : _locationService = locationService,
       _presenceCheck = presenceCheck;

  final LocationService _locationService;
  final VenuePresenceCheck? _presenceCheck;

  CheckInSession? session;
  String? lastError;
  String? lastNotice;
  int lifetimeCheckInCount = 0;
  Timer? _timeoutTimer;
  Timer? _extendTimer;
  Timer? _locationTimer;
  bool _tracksLiveLocation = false;
  bool _foreground = true;
  bool _checkingLocation = false;
  bool _disposed = false;

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
    if (isCheckedInAt(venue.id)) {
      return updateStatus(status, duration: duration, now: clock);
    }
    _stopLocationMonitoring();
    final isNewSession = session?.isAtVenue(venue.id) != true;
    final checkedInAt = isNewSession ? clock : session!.checkedInAt;
    final selectedDuration = isNewSession ? duration : session!.duration;
    final expiresAt = isNewSession
        ? _limitedExpiry(
            selectedDuration.expiresAtFrom(checkedInAt),
            checkedInAt,
          )
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
    if (_disposed) return false;
    final previous = session;
    lastError = null;
    try {
      final position = await _locationService.getCurrentPosition();
      if (_disposed || !identical(session, previous)) return false;
      final distance = _locationService.distanceBetweenMeters(
        startLatitude: position.latitude,
        startLongitude: position.longitude,
        endLatitude: venue.latitude,
        endLongitude: venue.longitude,
      );
      final started = tryCheckIn(
        venue: venue,
        status: status,
        distanceMeters: distance,
        duration: duration,
      );
      if (started && session != null && !_disposed) {
        _tracksLiveLocation = true;
        _startLocationTimer();
      }
      return started;
    } on LocationServiceDisabledException {
      if (_disposed || !identical(session, previous)) return false;
      lastError = 'Konum servisi kapalı. Lütfen cihaz ayarlarından aç.';
      notifyListeners();
      return false;
    } on LocationPermissionException catch (error) {
      if (_disposed || !identical(session, previous)) return false;
      lastError = error.message;
      notifyListeners();
      return false;
    } catch (error) {
      if (_disposed || !identical(session, previous)) return false;
      lastError = 'Konum alınamadı: $error';
      notifyListeners();
      return false;
    }
  }

  /// Süre değiştiğinde yeni süre şimdi başlar; toplam oturum 4 saati aşmaz.
  /// Yalnızca statü değiştiğinde mevcut bitiş zamanı korunur.
  bool updateStatus(
    CheckInStatus status, {
    CheckInDuration? duration,
    DateTime? now,
    CheckInSession? expectedSession,
  }) {
    final current = session;
    if (current == null) return false;
    if (expectedSession != null &&
        (current.venueId != expectedSession.venueId ||
            current.checkedInAt != expectedSession.checkedInAt)) {
      return false;
    }
    final clock = now ?? DateTime.now();
    if (current.isExpired(now: clock)) {
      checkOut(reason: CheckOutReason.timeout);
      return false;
    }
    final durationChanged = duration != null && duration != current.duration;
    session = current.copyWith(
      status: status,
      duration: duration,
      expiresAt: durationChanged
          ? _limitedExpiry(duration.expiresAtFrom(clock), current.checkedInAt)
          : current.expiresAt,
      autoExtendCount: durationChanged ? 0 : current.autoExtendCount,
    );
    lastNotice = null;
    _scheduleLifecycle(now: clock);
    notifyListeners();
    return true;
  }

  DateTime _limitedExpiry(DateTime? requested, DateTime checkedInAt) {
    final deadline = checkedInAt.add(MomntLocationRules.sessionTimeout);
    return requested == null || requested.isAfter(deadline)
        ? deadline
        : requested;
  }

  /// Süre bitimine 5 dk kala güncel konum doğrulanırsa oturumu uzatır.
  Future<bool> checkAutoExtend({DateTime? now, bool? stillAtVenue}) async {
    final current = session;
    if (current == null) return false;
    if (!current.isWithinAutoExtendWindow(now: now)) return false;

    final present =
        stillAtVenue ??
        await (_presenceCheck?.call(current) ?? _isStillAtVenue(current));
    if (!identical(session, current)) return false;
    if (!present) return false;

    final clock = now ?? DateTime.now();
    final expiresAt = _limitedExpiry(
      current.expiresAt!.add(CheckInLifecycleRules.autoExtendBy),
      current.checkedInAt,
    );
    if (!expiresAt.isAfter(current.expiresAt!) ||
        current.isExpired(now: clock)) {
      return false;
    }
    session = current.copyWith(
      expiresAt: expiresAt,
      autoExtendCount: current.autoExtendCount + 1,
    );
    final added = expiresAt.difference(current.expiresAt!);
    lastNotice = added == CheckInLifecycleRules.autoExtendBy
        ? 'Mekânda olduğun için süre 1 saat uzatıldı.'
        : 'Süre 4 saatlik üst sınıra kadar uzatıldı.';
    _scheduleLifecycle(now: clock);
    notifyListeners();
    return true;
  }

  void setForeground(bool foreground) {
    _foreground = foreground;
    if (!foreground) {
      _locationTimer?.cancel();
      _locationTimer = null;
      return;
    }
    _startLocationTimer();
    unawaited(refreshActiveCheckIn());
  }

  void _startLocationTimer() {
    if (!_foreground || !_tracksLiveLocation || _locationTimer != null) return;
    _locationTimer = Timer.periodic(
      CheckInLifecycleRules.locationCheckInterval,
      (_) => unawaited(refreshActiveCheckIn()),
    );
  }

  void _stopLocationMonitoring() {
    _tracksLiveLocation = false;
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  Future<void> refreshActiveCheckIn() async {
    final current = session;
    if (current == null || _disposed) return;
    if (current.isExpired() ||
        _locationService.isSessionTimedOut(current.checkedInAt)) {
      checkOut(reason: CheckOutReason.timeout);
      return;
    }
    if (!_foreground || !_tracksLiveLocation || _checkingLocation) return;

    _checkingLocation = true;
    try {
      final position = await _freshPosition();
      if (!identical(session, current) || !_foreground) return;
      if (position == null) return;
      final distance = _distanceToVenue(current, position);
      await evaluateSession(
        distanceMeters: distance,
        stillAtVenue: _locationService.canCheckIn(distance + position.accuracy),
      );
    } finally {
      _checkingLocation = false;
    }
  }

  Future<Position?> _freshPosition() async {
    try {
      final position = await _locationService.getActiveCheckInPosition();
      if (DateTime.now().difference(position.timestamp).abs() >
              CheckInLifecycleRules.maxPositionAge ||
          !position.accuracy.isFinite ||
          position.accuracy <= 0 ||
          !position.latitude.isFinite ||
          !position.longitude.isFinite) {
        return null;
      }
      return position;
    } catch (_) {
      // Konum doğrulanamadığında oturumun mevcut bitişi geçerlidir.
      return null;
    }
  }

  Future<bool> _isStillAtVenue(CheckInSession current) async {
    if (!_foreground) return false;
    final position = await _freshPosition();
    return position != null &&
        _foreground &&
        _locationService.canCheckIn(
          _distanceToVenue(current, position) + position.accuracy,
        );
  }

  double _distanceToVenue(CheckInSession current, Position position) {
    return _locationService.distanceBetweenMeters(
      startLatitude: position.latitude,
      startLongitude: position.longitude,
      endLatitude: current.venueLatitude,
      endLongitude: current.venueLongitude,
    );
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
      final atVenue =
          stillAtVenue ?? _locationService.canCheckIn(distanceMeters);
      await checkAutoExtend(now: now, stillAtVenue: atVenue);
    }
  }

  /// K-147: kullanıcı 'Check-in'i Bitir' ile oturumu kapatır.
  void endCheckIn() => checkOut(reason: CheckOutReason.manual);

  void checkOut({CheckOutReason reason = CheckOutReason.manual}) {
    if (session == null) return;
    session = null;
    _stopLocationMonitoring();
    _timeoutTimer?.cancel();
    _extendTimer?.cancel();
    _timeoutTimer = null;
    _extendTimer = null;
    lastNotice = null;
    lastError = switch (reason) {
      CheckOutReason.manual => null,
      CheckOutReason.autoExit =>
        'Mekândan ${(MomntLocationRules.autoExitDistanceMeters / 1000).round()} km’den fazla uzaklaştığın için check-in kapandı.',
      CheckOutReason.timeout => 'Check-in süresi doldu.',
    };
    notifyListeners();
  }

  void _scheduleLifecycle({DateTime? now}) {
    _timeoutTimer?.cancel();
    _extendTimer?.cancel();
    final current = session;
    if (current == null || current.expiresAt == null) {
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
    final hardDeadline = current.checkedInAt.add(
      MomntLocationRules.sessionTimeout,
    );
    if (untilExtendWindow > Duration.zero &&
        current.expiresAt!.isBefore(hardDeadline)) {
      _extendTimer = Timer(untilExtendWindow, () {
        if (_tracksLiveLocation) {
          unawaited(refreshActiveCheckIn());
        } else {
          unawaited(checkAutoExtend());
        }
      });
    }

    _timeoutTimer = Timer(
      remaining,
      () => checkOut(reason: CheckOutReason.timeout),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    session = null;
    _stopLocationMonitoring();
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
