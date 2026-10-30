import 'package:flutter/material.dart';
import 'package:momnt/models/check_in_status.dart';
import 'package:momnt/state/check_in_controller.dart';
import 'package:momnt/widgets/active_check_in_card.dart';
import 'package:momnt/widgets/check_in_status_badge.dart';

const _navy = Color(0xFF0F2167);

class HomeTabScreen extends StatelessWidget {
  const HomeTabScreen({super.key});

  static const _feed = <_FeedCheckIn>[
    _FeedCheckIn(
      name: 'Ece A.',
      username: '@ece.arslan',
      venue: 'Moda Kahve',
      venueArea: 'Moda Cad., Kadıköy',
      timeAgo: '8 dk önce',
      mood: CheckInStatus.drinkingCoffee,
      avatarUrl:
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=200',
      venueImageUrl:
          'https://images.unsplash.com/photo-1554118811-1e0d58224f24?q=80&w=400',
    ),
    _FeedCheckIn(
      name: 'Mert Yılmaz',
      username: '@mertyilmaz',
      venue: 'Espresso Lab',
      venueArea: 'Bahariye, Kadıköy',
      timeAgo: '22 dk önce',
      mood: CheckInStatus.socializing,
      avatarUrl:
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=200',
      venueImageUrl:
          'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?q=80&w=400',
    ),
    _FeedCheckIn(
      name: 'Selin Kaya',
      username: '@selinkaya',
      venue: 'Moda Kahve',
      venueArea: 'Moda Cad., Kadıköy',
      timeAgo: '41 dk önce',
      mood: CheckInStatus.openToMeet,
      avatarUrl:
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=200',
      venueImageUrl:
          'https://images.unsplash.com/photo-1554118811-1e0d58224f24?q=80&w=400',
    ),
    _FeedCheckIn(
      name: 'Mert Yılmaz',
      username: '@mertyilmaz',
      venue: 'Fenerbahçe Parkı',
      venueArea: 'Fenerbahçe, Kadıköy',
      timeAgo: '2 sa önce',
      mood: CheckInStatus.working,
      avatarUrl:
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=200',
      venueImageUrl:
          'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?q=80&w=400',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final session = CheckInScope.of(context).session;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ana Sayfa',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _navy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Arkadaşlarının anlık check-in’leri',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          if (session != null) ...[
            const SizedBox(height: 16),
            ActiveCheckInCard(session: session),
          ],
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 20),
              itemCount: _feed.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _FeedCard(item: _feed[index]),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedCheckIn {
  const _FeedCheckIn({
    required this.name,
    required this.username,
    required this.venue,
    required this.venueArea,
    required this.timeAgo,
    required this.mood,
    required this.avatarUrl,
    required this.venueImageUrl,
  });

  final String name;
  final String username;
  final String venue;
  final String venueArea;
  final String timeAgo;
  final CheckInStatus mood;
  final String avatarUrl;
  final String venueImageUrl;
}

class _FeedCard extends StatelessWidget {
  const _FeedCard({required this.item});

  final _FeedCheckIn item;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: _navy.withOpacity(0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _navy, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage(item.avatarUrl),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: _navy,
                        ),
                      ),
                      Text(
                        item.username,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  item.timeAgo,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text.rich(
              TextSpan(
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                children: [
                  const TextSpan(text: 'Check-in yaptı: '),
                  TextSpan(
                    text: item.venue,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _navy,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  Image.network(
                    item.venueImageUrl,
                    height: 148,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    left: 10,
                    bottom: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item.venueArea,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
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
            const SizedBox(height: 12),
            CheckInStatusBadge(status: item.mood),
          ],
        ),
      ),
    );
  }
}
