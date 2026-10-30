import 'package:flutter/material.dart';
import 'package:momnt/state/explore_controller.dart';
import 'package:momnt/theme/momnt_theme.dart';
import 'package:momnt/widgets/check_in_sheet.dart';
import 'package:momnt/widgets/stylized_map.dart';
import 'package:momnt/widgets/venue_summary_card.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key, required this.controller});

  final ExploreController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final selected = controller.selected;
        final pins = [
          for (final nearby in controller.visibleVenues)
            if (nearby.distanceMeters <= 3000 ||
                nearby.venue.id == selected?.venue.id)
              nearby,
        ];

        return Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: StylizedMap(
                  userLatitude: controller.latitude,
                  userLongitude: controller.longitude,
                  venues: pins,
                  selectedId: selected?.venue.id,
                  onSelect: controller.selectVenue,
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Material(
                    elevation: 4,
                    shadowColor: MomntColors.navy.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                    child: TextField(
                      onChanged: controller.setSearchQuery,
                      decoration: InputDecoration(
                        hintText: 'Mekân ara',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: MomntColors.navy,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 16,
                bottom: selected == null ? 24 : 230,
                child: FloatingActionButton.small(
                  backgroundColor: Colors.white,
                  foregroundColor: MomntColors.navy,
                  onPressed: controller.loadFromGps,
                  child: const Icon(Icons.my_location),
                ),
              ),
              if (selected != null)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: VenueSummaryCard(
                      key: const Key('map-venue-card'),
                      nearby: selected,
                      onCheckIn: () async {
                        final allowed =
                            await controller.startCheckIn(selected.venue);
                        if (!context.mounted) return;
                        if (!allowed) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Check-in için mekana 30 m içinde olmalısın.',
                              ),
                            ),
                          );
                          return;
                        }
                        await presentCheckInForVenue(
                          context: context,
                          venue: selected.venue,
                          distanceMeters:
                              controller.selected?.distanceMeters ??
                                  selected.distanceMeters,
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
