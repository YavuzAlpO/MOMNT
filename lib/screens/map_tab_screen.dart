import 'package:flutter/material.dart';
import 'package:momnt/models/venue_model.dart';
import 'package:momnt/state/check_in_controller.dart';
import 'package:momnt/widgets/check_in_sheet.dart';
import 'package:momnt/widgets/check_in_status_badge.dart';

const _navy = Color(0xFF0F2167);

const _modaKahve = Venue(
  id: 'moda-kahve',
  name: 'Moda Kahve',
  category: 'Kafe',
  latitude: 40.9875,
  longitude: 29.0258,
  activeUsersCount: 24,
  address: 'Moda Cad., Kadıköy',
  rating: 4.3,
  friendsHereCount: 2,
);

/// Mock harita kartı: Moda Kahve, keşif örneğinde 30 m içinde.
const _mockDistanceMeters = 18.0;

class MapTabScreen extends StatelessWidget {
  const MapTabScreen({super.key});

  Future<void> _handleCheckIn(BuildContext context) async {
    final controller = CheckInScope.of(context);
    final selected = await showCheckInSheet(
      context: context,
      venueName: _modaKahve.name,
      initialStatus: controller.isCheckedInAt(_modaKahve.id)
          ? controller.session?.status
          : null,
    );
    if (selected == null || !context.mounted) return;

    final ok = controller.tryCheckIn(
      venue: _modaKahve,
      status: selected,
      distanceMeters: _mockDistanceMeters,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? '${_modaKahve.name} · ${selected.label}'
              : controller.lastError ?? 'Check-in yapılamadı.',
        ),
      ),
    );
  }

  Future<void> _handleChangeStatus(BuildContext context) async {
    final controller = CheckInScope.of(context);
    final selected = await showCheckInSheet(
      context: context,
      venueName: _modaKahve.name,
      initialStatus: controller.session?.status,
    );
    if (selected == null || !context.mounted) return;
    controller.updateStatus(selected);
  }

  @override
  Widget build(BuildContext context) {
    final controller = CheckInScope.of(context);
    final checkedInHere = controller.isCheckedInAt(_modaKahve.id);
    final session = controller.session;

    return Stack(
      children: [
        Container(
          color: const Color(0xFFE5E3DF),
          child: const Center(
            child: Icon(Icons.map, size: 120, color: Colors.black12),
          ),
        ),
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: const TextField(
              decoration: InputDecoration(
                hintText: 'Mekân ara',
                prefixIcon: Icon(Icons.search, color: _navy),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ),
        if (session != null && !checkedInHere)
          Positioned(
            top: 88,
            left: 16,
            right: 16,
            child: Card(
              color: Colors.white,
              child: ListTile(
                dense: true,
                leading: Icon(session.status.icon, color: _navy),
                title: Text(
                  session.venueName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(session.status.label),
              ),
            ),
          ),
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Card(
            key: const Key('map-venue-card'),
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          'https://images.unsplash.com/photo-1554118811-1e0d58224f24?q=80&w=150',
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 60,
                            height: 60,
                            color: const Color(0xFFE2E8F0),
                            child: const Icon(Icons.local_cafe, color: _navy),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Moda Kahve',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: _navy,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              '24 kişi · 2 arkadaşın burada',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              '📍 Moda Cad., Kadıköy',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.star, size: 14, color: Colors.amber),
                            SizedBox(width: 2),
                            Text(
                              '4.3',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (checkedInHere && session != null) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: CheckInStatusBadge(status: session.status),
                    ),
                  ],
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () => checkedInHere
                          ? _handleChangeStatus(context)
                          : _handleCheckIn(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _navy,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        checkedInHere ? 'Statüyü Değiştir' : 'Check-in Yap',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (checkedInHere)
                    TextButton(
                      onPressed: () =>
                          CheckInScope.of(context).checkOut(),
                      child: const Text('Check-out'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
