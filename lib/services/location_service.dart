import 'package:geolocator/geolocator.dart';

/// MOMNT konum kuralları. Değerler `.cursorrules` ile aynıdır.
abstract final class MomntLocationRules {
  /// Keşif haritası yarıçapı: 20 km.
  static const double discoveryRadiusMeters = 20000;

  /// Check-in için maksimum mesafe: 30 metre.
  static const double checkInProximityMeters = 30;

  /// Check-in sonrası otomatik çıkış mesafesi: 1 km.
  static const double autoExitDistanceMeters = 1000;

  /// Check-in oturumu zaman aşımı: 4 saat.
  static const Duration sessionTimeout = Duration(hours: 4);
}

/// Aktif check-in yaşam döngüsü (K-036, K-145, K-147).
abstract final class CheckInLifecycleRules {
  /// Süre bitimine bu kadar kala konum kontrolü yapılır (K-145).
  static const Duration autoExtendWindow = Duration(minutes: 5);

  /// Mekândaysa süre bu kadar uzatılır (K-145).
  static const Duration autoExtendBy = Duration(hours: 1);

  static const Duration locationCheckInterval = Duration(seconds: 30);
  static const Duration maxPositionAge = Duration(seconds: 30);
}

class LocationPermissionException implements Exception {
  const LocationPermissionException(this.message);

  final String message;

  @override
  String toString() => 'LocationPermissionException: $message';
}

/// Konum izni, mevcut konum ve MOMNT mesafe kuralları.
class LocationService {
  const LocationService();

  /// Konum servisinin açık olduğunu doğrular, gerekirse izin ister.
  ///
  /// İzin verilirse [LocationPermission.whileInUse] veya
  /// [LocationPermission.always] döner.
  Future<LocationPermission> ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceDisabledException();
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const LocationPermissionException('konum izni reddedildi');
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationPermissionException(
        'konum izni kalıcı olarak reddedildi; ayarlardan açılmalı',
      );
    }

    return permission;
  }

  Future<bool> isLocationServiceEnabled() {
    return Geolocator.isLocationServiceEnabled();
  }

  Future<bool> hasLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// İzin aldıktan sonra mevcut konumu döner.
  Future<Position> getCurrentPosition() async {
    await ensureLocationPermission();
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  /// Aktif oturumu denetlerken yeniden izin istemez.
  Future<Position> getActiveCheckInPosition() async {
    if (!await isLocationServiceEnabled()) {
      throw const LocationServiceDisabledException();
    }
    if (!await hasLocationPermission()) {
      throw const LocationPermissionException('Konum izni gerekli.');
    }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );
  }

  /// İki nokta arasındaki mesafeyi metre cinsinden hesaplar.
  double distanceBetweenMeters({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  bool isWithinDiscoveryRadius(double distanceMeters) {
    return distanceMeters <= MomntLocationRules.discoveryRadiusMeters;
  }

  bool canCheckIn(double distanceMeters) {
    return distanceMeters <= MomntLocationRules.checkInProximityMeters;
  }

  /// Kullanıcı konumunun hedef MOMNT noktasına 30 m içinde olup olmadığını döner.
  bool isWithinCheckInRadius({
    required double userLatitude,
    required double userLongitude,
    required double targetLatitude,
    required double targetLongitude,
  }) {
    final distanceMeters = distanceBetweenMeters(
      startLatitude: userLatitude,
      startLongitude: userLongitude,
      endLatitude: targetLatitude,
      endLongitude: targetLongitude,
    );
    return canCheckIn(distanceMeters);
  }

  bool shouldAutoExit(double distanceMeters) {
    return distanceMeters > MomntLocationRules.autoExitDistanceMeters;
  }

  bool isSessionTimedOut(DateTime checkedInAt, {DateTime? now}) {
    final elapsed = (now ?? DateTime.now()).difference(checkedInAt);
    return elapsed >= MomntLocationRules.sessionTimeout;
  }
}
