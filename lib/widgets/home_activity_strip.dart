import 'package:flutter/material.dart';
import 'package:momnt/models/check_in_session.dart';
import 'package:momnt/models/mutual_follow_profile.dart';
import 'package:momnt/widgets/active_check_in_card.dart';

/// Check-in bittiğinde hikâye alanı kalan genişliği kendiliğinden devralır.
class HomeActivityStrip extends StatelessWidget {
  const HomeActivityStrip({
    super.key,
    this.session,
    this.onManageCheckIn,
    this.mutualFollows = const [],
  });

  final CheckInSession? session;
  final VoidCallback? onManageCheckIn;
  final List<MutualFollowProfile> mutualFollows;

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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hikâyeler',
                      style: TextStyle(
                        color: Color(0xFF0F2167),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Hikâyeler burada görünecek.',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
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
