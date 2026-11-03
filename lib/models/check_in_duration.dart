/// K-036: kullanıcının seçtiği check-in süresi. Varsayılan 1 saat.
enum CheckInDuration {
  oneHour,
  threeHours,
  oneDay,
  unlimited;

  static const CheckInDuration defaultValue = oneHour;

  String get label => switch (this) {
        oneHour => '1 saat',
        threeHours => '3 saat',
        oneDay => '1 gün',
        unlimited => 'Süresiz',
      };

  Duration? get length => switch (this) {
        oneHour => const Duration(hours: 1),
        threeHours => const Duration(hours: 3),
        oneDay => const Duration(days: 1),
        unlimited => null,
      };

  bool get isUnlimited => this == CheckInDuration.unlimited;

  DateTime? expiresAtFrom(DateTime start) {
    final length = this.length;
    if (length == null) return null;
    return start.add(length);
  }
}
