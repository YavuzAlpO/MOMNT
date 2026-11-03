String formatDistance(double meters) {
  if (meters < 1000) {
    return '${meters.round()} m';
  }
  return '${(meters / 1000).toStringAsFixed(1)} km';
}

String formatCountdown(Duration remaining) {
  if (remaining.isNegative) {
    remaining = Duration.zero;
  }
  final hours = remaining.inHours;
  final minutes = remaining.inMinutes.remainder(60);
  final seconds = remaining.inSeconds.remainder(60);
  final hh = hours.toString().padLeft(2, '0');
  final mm = minutes.toString().padLeft(2, '0');
  final ss = seconds.toString().padLeft(2, '0');
  return '$hh:$mm:$ss';
}
