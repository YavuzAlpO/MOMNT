import 'package:momnt/models/check_in_status.dart';

/// Aktif check-in oturumu: mekan + statü + başlangıç zamanı.
class CheckInSession {
  const CheckInSession({
    required this.venueId,
    required this.venueName,
    required this.venueLatitude,
    required this.venueLongitude,
    required this.status,
    required this.checkedInAt,
  });

  final String venueId;
  final String venueName;
  final double venueLatitude;
  final double venueLongitude;
  final CheckInStatus status;
  final DateTime checkedInAt;

  bool isAtVenue(String venueId) => this.venueId == venueId;

  CheckInSession copyWith({CheckInStatus? status}) {
    return CheckInSession(
      venueId: venueId,
      venueName: venueName,
      venueLatitude: venueLatitude,
      venueLongitude: venueLongitude,
      status: status ?? this.status,
      checkedInAt: checkedInAt,
    );
  }
}
