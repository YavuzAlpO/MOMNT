import 'package:flutter/material.dart';
import 'package:momnt/models/profile_info.dart';
import 'package:momnt/screens/edit_profile_screen.dart';
import 'package:momnt/state/check_in_controller.dart';
import 'package:momnt/widgets/active_check_in_card.dart';
import 'package:momnt/widgets/check_in_sheet.dart';

class ProfileTabScreen extends StatefulWidget {
  const ProfileTabScreen({super.key});

  @override
  State<ProfileTabScreen> createState() => _ProfileTabScreenState();
}

class _ProfileTabScreenState extends State<ProfileTabScreen> {
  String _name = 'Ece A.';
  String _username = 'ece.arslan';
  String _bio = 'Kahve ve yeni yerler. ☕✨';

  Future<void> _openEditProfile() async {
    final updated = await Navigator.push<ProfileInfo>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          name: _name,
          username: _username,
          bio: _bio,
        ),
      ),
    );

    if (!mounted || updated == null) return;

    setState(() {
      _name = updated.name;
      _username = updated.username;
      _bio = updated.bio;
    });
  }

  @override
  Widget build(BuildContext context) {
    final checkIn = CheckInScope.of(context);
    final session = checkIn.session;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const CircleAvatar(
            radius: 46,
            backgroundImage: NetworkImage(
              'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=200',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F2167),
            ),
          ),
          Text(
            '@$_username',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(_bio, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            '📍 ${checkIn.lifetimeCheckInCount} check-in',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          if (session != null) ...[
            const SizedBox(height: 16),
            ActiveCheckInCard(
              session: session,
              onChangeStatus: () async {
                final selected = await showCheckInSheet(
                  context: context,
                  venueName: session.venueName,
                  initialStatus: session.status,
                );
                if (selected == null || !mounted) return;
                CheckInScope.of(context).updateStatus(selected);
              },
              onCheckOut: () => CheckInScope.of(context).checkOut(),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _openEditProfile,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Profili Düzenle',
                    style: TextStyle(color: Color(0xFF0F2167)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 16),
                    SizedBox(width: 4),
                    Text('Pinler'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
