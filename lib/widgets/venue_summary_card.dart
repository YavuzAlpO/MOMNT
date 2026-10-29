import 'package:flutter/material.dart';
import 'package:momnt/services/location_service.dart';
import 'package:momnt/services/venue_service.dart';
import 'package:momnt/theme/momnt_theme.dart';
import 'package:momnt/utils/formatters.dart';

class VenueSummaryCard extends StatelessWidget {
  const VenueSummaryCard({
    super.key,
    required this.nearby,
    required this.onCheckIn,
  });

  final NearbyVenue nearby;
  final VoidCallback onCheckIn;

  @override
  Widget build(BuildContext context) {
    final venue = nearby.venue;
    final within = const LocationService().canCheckIn(nearby.distanceMeters);

    return Material(
      color: Colors.white,
      elevation: 10,
      shadowColor: MomntColors.navy.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.local_cafe_rounded,
                color: MomntColors.navy,
                size: 32,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    venue.name,
                    style: const TextStyle(
                      color: MomntColors.navy,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${venue.category} · ${formatDistance(nearby.distanceMeters)}',
                    style: const TextStyle(color: MomntColors.muted),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (within)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: MomntColors.successSoft,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            '30 m içinde',
                            style: TextStyle(
                              color: MomntColors.success,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      Text(
                        '${venue.activeUsersCount} kişi',
                        style: const TextStyle(
                          color: MomntColors.navy,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: onCheckIn,
                      child: const Text('Check-in Yap'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
