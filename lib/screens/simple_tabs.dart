import 'package:flutter/material.dart';
import 'package:momnt/theme/momnt_theme.dart';

class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _EmptyTab(
      title: 'İstekler',
      icon: Icons.favorite_border,
      message: 'Henüz check-in isteğin yok.',
    );
  }
}

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _EmptyTab(
      title: 'Mesajlar',
      icon: Icons.chat_bubble_outline,
      message: 'Sohbetlerin burada görünecek.',
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: MomntColors.navy,
              child: Icon(Icons.person, color: Colors.white, size: 40),
            ),
            SizedBox(height: 16),
            Text(
              'MOMNT kullanıcısı',
              style: TextStyle(
                color: MomntColors.navy,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Check-in durumun ve geçmişin yakında burada.',
              textAlign: TextAlign.center,
              style: TextStyle(color: MomntColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTab extends StatelessWidget {
  const _EmptyTab({
    required this.title,
    required this.icon,
    required this.message,
  });

  final String title;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: MomntColors.navy),
            const SizedBox(height: 12),
            Text(message, style: const TextStyle(color: MomntColors.muted)),
          ],
        ),
      ),
    );
  }
}
