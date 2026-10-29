import 'dart:math';

import 'package:momnt/models/venue_model.dart';
import 'package:momnt/services/location_service.dart';

class NearbyVenue {
  const NearbyVenue({required this.venue, required this.distanceMeters});

  final Venue venue;
  final double distanceMeters;
}

/// Kullanıcı konumuna göre üretilen örnek mekanlar.
class VenueService {
  const VenueService();

  /// Kullanıcının bulunduğu noktaya göre 4 yakın + 1 uzak (20 km dışı) mock mekan.
  List<Venue> mockVenuesNear({
    required double latitude,
    required double longitude,
  }) {
    return [
      _offsetVenue(
        id: 'moda-kahve',
        name: 'Moda Kahve',
        category: 'Kafe',
        originLatitude: latitude,
        originLongitude: longitude,
        northMeters: 18,
        eastMeters: 4,
        activeUsersCount: 24,
      ),
      _offsetVenue(
        id: 'loft-bar',
        name: 'Loft Bar',
        category: 'Bar',
        originLatitude: latitude,
        originLongitude: longitude,
        northMeters: 40,
        eastMeters: 110,
        activeUsersCount: 8,
      ),
      _offsetVenue(
        id: 'sahil-park',
        name: 'Sahil Park',
        category: 'Park',
        originLatitude: latitude,
        originLongitude: longitude,
        northMeters: -1800,
        eastMeters: -1600,
        activeUsersCount: 21,
      ),
      _offsetVenue(
        id: 'sky-lounge',
        name: 'Sky Lounge',
        category: 'Lounge',
        originLatitude: latitude,
        originLongitude: longitude,
        northMeters: 7200,
        eastMeters: 3100,
        activeUsersCount: 34,
      ),
      _offsetVenue(
        id: 'uzak-depo',
        name: 'Uzak Depo',
        category: 'Depo',
        originLatitude: latitude,
        originLongitude: longitude,
        northMeters: 22000,
        eastMeters: 8000,
        activeUsersCount: 2,
      ),
    ];
  }

  /// 20 km keşif yarıçapındaki mekanları mesafeye göre sıralar.
  List<NearbyVenue> discoverWithinRadius({
    required double userLatitude,
    required double userLongitude,
    LocationService locationService = const LocationService(),
  }) {
    final nearby = <NearbyVenue>[];
    for (final venue in mockVenuesNear(
      latitude: userLatitude,
      longitude: userLongitude,
    )) {
      final distanceMeters = locationService.distanceBetweenMeters(
        startLatitude: userLatitude,
        startLongitude: userLongitude,
        endLatitude: venue.latitude,
        endLongitude: venue.longitude,
      );
      if (locationService.isWithinDiscoveryRadius(distanceMeters)) {
        nearby.add(NearbyVenue(venue: venue, distanceMeters: distanceMeters));
      }
    }
    nearby.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    return nearby;
  }

  Venue _offsetVenue({
    required String id,
    required String name,
    required String category,
    required double originLatitude,
    required double originLongitude,
    required double northMeters,
    required double eastMeters,
    required int activeUsersCount,
  }) {
    const metersPerDegreeLatitude = 111320.0;
    final metersPerDegreeLongitude =
        111320.0 * cos(originLatitude * pi / 180);
    return Venue(
      id: id,
      name: name,
      category: category,
      latitude: originLatitude + northMeters / metersPerDegreeLatitude,
      longitude: originLongitude + eastMeters / metersPerDegreeLongitude,
      activeUsersCount: activeUsersCount,
    );
  }
}
