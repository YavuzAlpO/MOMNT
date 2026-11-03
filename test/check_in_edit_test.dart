import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momnt/models/check_in_duration.dart';
import 'package:momnt/models/check_in_status.dart';
import 'package:momnt/models/venue_model.dart';
import 'package:momnt/services/location_service.dart';
import 'package:momnt/state/check_in_controller.dart';
import 'package:momnt/widgets/check_in_sheet.dart';
import 'package:provider/provider.dart';

const _venue = Venue(
  id: 'edit-test',
  name: 'Test Kafe',
  category: 'Kafe',
  latitude: 41,
  longitude: 29,
  activeUsersCount: 1,
);

Future<CheckInController> _openEditor(
  WidgetTester tester, {
  CheckInDuration duration = CheckInDuration.twoHours,
  bool fromVenue = false,
}) async {
  tester.view.physicalSize = const Size(800, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final controller = CheckInController();
  controller.tryCheckIn(
    venue: _venue,
    status: CheckInStatus.working,
    distanceMeters: 10,
    duration: duration,
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
  });
  await tester.pumpWidget(
    ChangeNotifierProvider<CheckInController>(
      create: (_) => controller,
      lazy: false,
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => fromVenue
                  ? presentCheckInForVenue(
                      context: context,
                      venue: _venue,
                      distanceMeters: 10,
                    )
                  : presentCheckInEdit(context: context),
              child: const Text('Düzenle'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Düzenle'));
  await tester.pumpAndSettle();
  return controller;
}

Future<void> _tap(WidgetTester tester, String label) async {
  final target = find.text(label);
  await tester.ensureVisible(target);
  await tester.tap(target);
  // Sayacın zamanlayıcıları testte gereksiz yere ilerlemesin.
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('mevcut statü ve süre seçili gelir; dört süre sunulur', (
    tester,
  ) async {
    await _openEditor(tester);
    final status = find.widgetWithText(InkWell, 'Çalışıyorum');
    expect(
      find.descendant(
        of: status,
        matching: find.byIcon(Icons.radio_button_checked),
      ),
      findsOneWidget,
    );
    for (final duration in CheckInDuration.values) {
      final chip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, duration.label),
      );
      expect(chip.selected, duration == CheckInDuration.twoHours);
    }
  });

  testWidgets(
    'yalnız statü kaydı güncellenir, bitiş ve check-in sayısı korunur',
    (tester) async {
      final controller = await _openEditor(tester);
      final original = controller.session!;
      await _tap(tester, 'Sosyalleşiyorum');
      // Seçimler kaydetmeden önce oturuma yazılmamalı.
      expect(controller.session, same(original));
      await _tap(tester, 'Değişiklikleri Kaydet');
      expect(controller.session!.status, CheckInStatus.socializing);
      expect(controller.session!.duration, original.duration);
      expect(controller.session!.expiresAt, original.expiresAt);
      expect(controller.session!.checkedInAt, original.checkedInAt);
      expect(controller.lifetimeCheckInCount, 1);
      expect(find.byType(CheckInSheet), findsNothing);
    },
  );

  for (final duration in CheckInDuration.values) {
    testWidgets(
      '${duration.label} kaydetme anından hesaplanır ve mevcut kaydı günceller',
      (tester) async {
        final controller = await _openEditor(
          tester,
          duration: duration == CheckInDuration.oneHour
              ? CheckInDuration.twoHours
              : CheckInDuration.oneHour,
          fromVenue: true,
        );
        final original = controller.session!;
        await _tap(tester, duration.label);
        final beforeSave = DateTime.now();
        await _tap(tester, 'Değişiklikleri Kaydet');
        final afterSave = DateTime.now();
        final updated = controller.session!;
        final deadline = original.checkedInAt.add(
          MomntLocationRules.sessionTimeout,
        );
        DateTime expiry(DateTime saved) {
          final requested = duration.expiresAtFrom(saved);
          return requested.isAfter(deadline) ? deadline : requested;
        }

        expect(updated.expiresAt!.isBefore(expiry(beforeSave)), isFalse);
        expect(updated.expiresAt!.isAfter(expiry(afterSave)), isFalse);
        expect(updated.duration, duration);
        expect(updated.venueId, original.venueId);
        expect(updated.checkedInAt, original.checkedInAt);
        expect(controller.lifetimeCheckInCount, 1);
      },
    );
  }

  for (final cancel in ['İptal', 'dışarı dokun', 'geri']) {
    testWidgets('$cancel ile kapanınca hiçbir seçim kaydedilmez', (
      tester,
    ) async {
      final controller = await _openEditor(tester);
      final original = controller.session;
      var changes = 0;
      controller.addListener(() => changes++);
      await _tap(tester, 'Sosyalleşiyorum');
      await _tap(tester, '4 saat');
      if (cancel == 'İptal') {
        await _tap(tester, 'İptal');
      } else if (cancel == 'geri') {
        await tester.binding.handlePopRoute();
      } else {
        await tester.tapAt(const Offset(5, 5));
      }
      await tester.pumpAndSettle();
      expect(find.byType(CheckInSheet), findsNothing);
      expect(controller.session, same(original));
      expect(changes, 0);
      expect(controller.lifetimeCheckInCount, 1);
    });
  }

  testWidgets('ekran açıkken biten check-in kaydetmeyle yeniden oluşturulmaz', (
    tester,
  ) async {
    final controller = await _openEditor(tester);
    controller.endCheckIn();
    await _tap(tester, 'Değişiklikleri Kaydet');
    expect(controller.session, isNull);
    expect(controller.lifetimeCheckInCount, 1);
    expect(find.text('Bu check-in artık aktif değil.'), findsOneWidget);
  });

  testWidgets(
    'eski düzenleme aynı mekandaki yeni check-in kaydını değiştirmez',
    (tester) async {
      final controller = await _openEditor(tester);
      final started = controller.session!.checkedInAt;
      controller.endCheckIn();
      controller.tryCheckIn(
        venue: _venue,
        status: CheckInStatus.drinkingCoffee,
        distanceMeters: 10,
        now: started.add(const Duration(seconds: 1)),
      );
      final replacement = controller.session;
      await _tap(tester, 'Sosyalleşiyorum');
      await _tap(tester, 'Değişiklikleri Kaydet');
      expect(controller.session, same(replacement));
      expect(controller.lifetimeCheckInCount, 2);
    },
  );
}
