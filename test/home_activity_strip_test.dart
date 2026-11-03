import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momnt/models/check_in_session.dart';
import 'package:momnt/models/check_in_status.dart';
import 'package:momnt/models/mutual_follow_profile.dart';
import 'package:momnt/widgets/home_activity_strip.dart';

void main() {
  for (final width in [320.0, 1200.0]) {
    testWidgets('check-in ve hikâyeler $width genişlikte yan yana sığar', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var opened = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeActivityStrip(
              mutualFollows: const [
                MutualFollowProfile(id: '1', name: 'Mert', username: '@mert'),
                MutualFollowProfile(id: '2', name: 'Selin', username: '@selin'),
              ],
              session: CheckInSession(
                venueId: 'venue',
                venueName: 'Uzun isimli örnek bir mekân',
                venueLatitude: 41,
                venueLongitude: 29,
                status: CheckInStatus.socializing,
                checkedInAt: DateTime.now(),
                expiresAt: DateTime.now().add(const Duration(hours: 1)),
              ),
              onManageCheckIn: () => opened = true,
            ),
          ),
        ),
      );
      final checkIn = find.byKey(const Key('home-compact-check-in'));
      final stories = find.byKey(const Key('home-stories-area'));
      expect(
        tester.getRect(checkIn).right,
        lessThan(tester.getRect(stories).left),
      );
      expect(tester.getSize(checkIn).height, 128);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('mutual-follow-group')));
      await tester.pump();
      expect(find.text('Takipleştiğin kişiler (2)'), findsOneWidget);
      expect(opened, isFalse);
      await tester.tap(find.byKey(const ValueKey('mutual-follow-group')));
      await tester.pump();
      await tester.tap(checkIn);
      expect(opened, isTrue);
      final previousWidth = tester.getSize(stories).width;
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: HomeActivityStrip())),
      );
      expect(checkIn, findsNothing);
      expect(tester.getSize(stories).width, width);
      expect(tester.getSize(stories).width, greaterThan(previousWidth));
      expect(tester.takeException(), isNull);
    });
  }
}
