import 'package:momnt/services/location_service.dart';

/// K-036: kullanıcının seçtiği check-in süresi. Varsayılan 1 saat.
enum CheckInDuration {
  halfHour,
  oneHour,
  twoHours,
  fourHours;

  static const CheckInDuration defaultValue = oneHour;

  String get label => switch (this) {
    halfHour => '30 dk',
    oneHour => '1 saat',
    twoHours => '2 saat',
    fourHours => '4 saat',
  };

  Duration get length => switch (this) {
    halfHour => const Duration(minutes: 30),
    oneHour => const Duration(hours: 1),
    twoHours => const Duration(hours: 2),
    fourHours => MomntLocationRules.sessionTimeout,
  };

  DateTime expiresAtFrom(DateTime start) => start.add(length);
}
