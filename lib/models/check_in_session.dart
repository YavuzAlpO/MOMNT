import 'package:momnt/models/check_in_duration.dart';
import 'package:momnt/models/check_in_status.dart';
import 'package:momnt/services/location_service.dart';

/// Aktif check-in oturumu: mekan + statü + süre.
class CheckInSession {
  const CheckInSession({
    required this.venueId,
    required this.venueName,
    required this.venueLatitude,
    required this.venueLongitude,
    required this.status,
    required this.checkedInAt,
    this.duration = CheckInDuration.defaultValue,
    this.expiresAt,
    this.autoExtendCount = 0,
  });

  final String venueId;
  final String venueName;
  final double venueLatitude;
  final double venueLongitude;
  final CheckInStatus status;
  final DateTime checkedInAt;
  final CheckInDuration duration;
  final DateTime? expiresAt;
  final int autoExtendCount;

  bool isAtVenue(String venueId) => this.venueId == venueId;

  Duration remaining({DateTime? now}) {
    if (expiresAt == null) return Duration.zero;
    return expiresAt!.difference(now ?? DateTime.now());
  }

  bool isExpired({DateTime? now}) {
    if (expiresAt == null) return false;
    return !expiresAt!.isAfter(now ?? DateTime.now());
  }

  bool isWithinAutoExtendWindow({DateTime? now}) {
    if (expiresAt == null) return false;
    final left = remaining(now: now);
    return left > Duration.zero &&
        left <= CheckInLifecycleRules.autoExtendWindow;
  }

  CheckInSession copyWith({
    CheckInStatus? status,
    CheckInDuration? duration,
    DateTime? expiresAt,
    int? autoExtendCount,
  }) {
    return CheckInSession(
      venueId: venueId,
      venueName: venueName,
      venueLatitude: venueLatitude,
      venueLongitude: venueLongitude,
      status: status ?? this.status,
      checkedInAt: checkedInAt,
      duration: duration ?? this.duration,
      expiresAt: expiresAt ?? this.expiresAt,
      autoExtendCount: autoExtendCount ?? this.autoExtendCount,
    );
  }
}
