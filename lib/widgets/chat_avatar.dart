import 'package:flutter/material.dart';
import 'package:momnt/models/mutual_follow_profile.dart';

class ChatAvatar extends StatelessWidget {
  const ChatAvatar({super.key, required this.contact, this.size = 44});
  final MutualFollowProfile contact;
  final double size;

  @override
  Widget build(BuildContext context) {
    const fallback = ColoredBox(
      color: Color(0xFFE2E8F0),
      child: Icon(Icons.person, color: Color(0xFF0F2167)),
    );
    return SizedBox.square(
      dimension: size,
      child: ClipOval(
        child: contact.avatarUrl == null
            ? fallback
            : Image.network(
                contact.avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
              ),
      ),
    );
  }
}
