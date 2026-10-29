import 'package:flutter/material.dart';
import 'package:momnt/state/explore_controller.dart';
import 'package:momnt/theme/momnt_theme.dart';
import 'package:momnt/widgets/check_in_sheet.dart';
import 'package:momnt/widgets/venue_summary_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.controller});

  final ExploreController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('MOMNT'),
            actions: [
              IconButton(
                onPressed: controller.busy ? null : controller.loadFromGps,
                icon: const Icon(Icons.my_location),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              const Text(
                'Yakındaki anlar',
                style: TextStyle(
                  color: MomntColors.navy,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                controller.usingLiveLocation
                    ? 'Konumun 20 km çevresindeki mekanlar'
                    : 'Moda civarı örnek keşif alanı',
                style: const TextStyle(color: MomntColors.muted),
              ),
              if (controller.statusMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  controller.statusMessage!,
                  style: const TextStyle(color: MomntColors.muted),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: controller.busy ? null : controller.loadFromGps,
                icon: controller.busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.explore_outlined),
                label: const Text('Konumumu Al ve Mekanları Göster'),
              ),
              const SizedBox(height: 20),
              for (final nearby in controller.venues) ...[
                VenueSummaryCard(
                  nearby: nearby,
                  onCheckIn: () => showCheckInSheet(
                    context: context,
                    controller: controller,
                    venue: nearby.venue,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        );
      },
    );
  }
}
