import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:momnt/models/venue_model.dart';
import 'package:momnt/services/location_service.dart';
import 'package:momnt/services/venue_service.dart';

/// Kadıköy / Moda civarı — GPS yokken harita dolu görünsün.
const double kFallbackLatitude = 40.9875;
const double kFallbackLongitude = 29.0258;

class ExploreController extends ChangeNotifier {
  ExploreController({
    LocationService locationService = const LocationService(),
    VenueService venueService = const VenueService(),
  }) : _locationService = locationService,
       _venueService = venueService;

  final LocationService _locationService;
  final VenueService _venueService;

  bool? serviceEnabled;
  double latitude = kFallbackLatitude;
  double longitude = kFallbackLongitude;
  bool usingLiveLocation = false;
  List<NearbyVenue> venues = const [];
  NearbyVenue? selected;
  String? statusMessage;
  bool busy = false;
  String searchQuery = '';

  LocationService get locationService => _locationService;

  List<NearbyVenue> get visibleVenues {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) return venues;
    return venues
        .where((item) => item.venue.name.toLowerCase().contains(query))
        .toList();
  }

  void loadFallbackVenues() {
    _applyVenues(
      _venueService.discoverWithinRadius(
        userLatitude: latitude,
        userLongitude: longitude,
        locationService: _locationService,
      ),
    );
  }

  Future<void> refreshServiceStatus() async {
    try {
      serviceEnabled = await _locationService.isLocationServiceEnabled();
    } catch (_) {
      serviceEnabled = false;
    }
    notifyListeners();
  }

  Future<void> loadFromGps() async {
    busy = true;
    statusMessage = null;
    notifyListeners();

    try {
      await refreshServiceStatus();
      final position = await _locationService.getCurrentPosition();
      latitude = position.latitude;
      longitude = position.longitude;
      usingLiveLocation = true;
      _applyVenues(
        _venueService.discoverWithinRadius(
          userLatitude: latitude,
          userLongitude: longitude,
          locationService: _locationService,
        ),
      );
      statusMessage = '${venues.length} mekan, 20 km keşif alanında.';
    } on LocationServiceDisabledException {
      serviceEnabled = false;
      statusMessage = 'Konum servisi kapalı. Lütfen cihaz ayarlarından aç.';
    } on LocationPermissionException catch (error) {
      statusMessage = error.message;
    } catch (error) {
      statusMessage = 'Konum alınamadı: $error';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String value) {
    searchQuery = value;
    notifyListeners();
  }

  void selectVenue(NearbyVenue nearby) {
    selected = nearby;
    notifyListeners();
  }

  void selectVenueById(String id) {
    final match = venues.where((item) => item.venue.id == id);
    if (match.isNotEmpty) {
      selected = match.first;
      notifyListeners();
    }
  }

  /// Canlı konum alır, mekanları yeniler ve 30 m kuralını uygular.
  Future<bool> startCheckIn(Venue venue) async {
    final position = await _locationService.getCurrentPosition();
    latitude = position.latitude;
    longitude = position.longitude;
    usingLiveLocation = true;
    _applyVenues(
      _venueService.discoverWithinRadius(
        userLatitude: latitude,
        userLongitude: longitude,
        locationService: _locationService,
      ),
    );
    final match = venues.where((item) => item.venue.id == venue.id);
    selected = match.isNotEmpty
        ? match.first
        : (venues.isNotEmpty ? venues.first : selected);
    notifyListeners();
    final distance = selected?.distanceMeters ??
        _locationService.distanceBetweenMeters(
          startLatitude: latitude,
          startLongitude: longitude,
          endLatitude: venue.latitude,
          endLongitude: venue.longitude,
        );
    return _locationService.canCheckIn(distance);
  }

  bool isWithinCheckIn(NearbyVenue nearby) {
    return _locationService.canCheckIn(nearby.distanceMeters);
  }

  void _applyVenues(List<NearbyVenue> next) {
    venues = next;
    if (venues.isEmpty) {
      selected = null;
      return;
    }
    final preferred = venues.where((item) => item.venue.id == 'moda-kahve');
    selected = preferred.isNotEmpty ? preferred.first : venues.first;
  }
}
