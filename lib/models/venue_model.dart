class Venue {
  const Venue({
    required this.id,
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.activeUsersCount,
    this.address = '',
    this.hours = '',
    this.rating = 0,
    this.friendsHereCount = 0,
  });

  final String id;
  final String name;
  final String category;
  final double latitude;
  final double longitude;
  final int activeUsersCount;
  final String address;
  final String hours;
  final double rating;
  final int friendsHereCount;

  String get ratingLabel => '${rating.toStringAsFixed(1).replaceAll('.', ',')} ★';
}
