import 'package:flutter/material.dart';
import 'package:momnt/theme/momnt_theme.dart';
import 'package:momnt/models/check_in_session.dart';
import 'package:momnt/models/mutual_follow_profile.dart';
import 'package:momnt/widgets/active_check_in_card.dart';
import 'package:momnt/widgets/home_stories.dart';

/// Check-in bittiğinde hikâye alanı kalan genişliği kendiliğinden devralır.
class HomeActivityStrip extends StatelessWidget {
  const HomeActivityStrip({
    super.key,
    this.session,
    this.onManageCheckIn,
    this.mutualFollows = const [],
    this.stories = const [],
  });

  final CheckInSession? session;
  final VoidCallback? onManageCheckIn;
  final List<MutualFollowProfile> mutualFollows;
  final List<HomeStory> stories;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SizedBox(
        height: 128,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (session != null) ...[
              SizedBox(
                key: const Key('home-compact-check-in'),
                width: constraints.maxWidth < 400 ? 136 : 168,
                child: ActiveCheckInCard(
                  session: session!,
                  compact: true,
                  mutualFollows: mutualFollows,
                  onOpen: onManageCheckIn,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Container(
                key: const Key('home-stories-area'),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: MomntColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: MomntColors.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hikâyeler',
                      style: Theme.of(context).textTheme.labelMedium
                          ?.copyWith(color: MomntColors.ink),
                    ),
                    Expanded(child: HomeStories(stories: stories)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
