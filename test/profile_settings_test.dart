import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momnt/screens/profile_settings_screen.dart';
import 'package:momnt/services/location_service.dart';

class _TestLocationService extends LocationService {
  bool allowed = false;

  @override
  Future<bool> hasLocationPermission() async => allowed;
}

void main() {
  testWidgets('hesap düzenlemeye bağlanır ve konum izni yenilenir', (
    tester,
  ) async {
    final location = _TestLocationService();
    var edited = false;
    await tester.pumpWidget(
      MaterialApp(
        home: ProfileSettingsScreen(
          onEditProfile: () => edited = true,
          locationService: location,
        ),
      ),
    );

    await tester.tap(find.text('Hesap'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profili Düzenle'));
    expect(edited, isTrue);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Gizlilik'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('İzinler'));
    await tester.pumpAndSettle();
    expect(find.text('Konum izni verilmedi'), findsOneWidget);

    location.allowed = true;
    await tester.tap(find.byTooltip('İzin durumunu yenile'));
    await tester.pumpAndSettle();
    expect(find.text('Konum izni açık'), findsOneWidget);
  });
}
