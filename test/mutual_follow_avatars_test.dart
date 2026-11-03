import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momnt/models/mutual_follow_profile.dart';
import 'package:momnt/widgets/mutual_follow_avatars.dart';

Future<void> _showProfiles(WidgetTester tester, int count) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 160,
            child: MutualFollowAvatars(
              profiles: [
                for (var i = 0; i < count; i++)
                  MutualFollowProfile(
                    id: '$i',
                    name: 'Kişi $i',
                    username: '@kisi$i',
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('hover önizlemeyi açar, panelde açık tutar ve çıkınca kapatır', (
    tester,
  ) async {
    await _showProfiles(tester, 5);
    expect(find.text('+2'), findsNothing);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(
      tester.getCenter(find.byKey(const ValueKey('mutual-follow-group'))),
    );
    await tester.pumpAndSettle();
    final heading = find.text('Takipleştiğin kişiler (5)');
    expect(heading, findsOneWidget);
    for (var i = 0; i < 5; i++) {
      expect(find.text('Kişi $i'), findsOneWidget);
    }
    await mouse.moveTo(tester.getCenter(heading));
    await tester.pump(const Duration(milliseconds: 250));
    expect(heading, findsOneWidget);
    await mouse.moveTo(Offset.zero);
    await tester.pumpAndSettle(const Duration(milliseconds: 250));
    expect(heading, findsNothing);
    await mouse.removePointer();
  });

  testWidgets('dokunma açar ve dışarı dokunma kapatır', (tester) async {
    await _showProfiles(tester, 5);
    await tester.tap(find.byKey(const ValueKey('mutual-follow-group')));
    await tester.pumpAndSettle();
    expect(find.text('Takipleştiğin kişiler (5)'), findsOneWidget);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.text('Takipleştiğin kişiler (5)'), findsNothing);
  });

  testWidgets('üç profilde de tek simge üzerinden tüm profiller açılır', (
    tester,
  ) async {
    await _showProfiles(tester, 3);
    expect(find.byKey(const ValueKey('mutual-follow-group')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('mutual-follow-group')));
    await tester.pumpAndSettle();
    expect(find.text('Takipleştiğin kişiler (3)'), findsOneWidget);
  });
}
