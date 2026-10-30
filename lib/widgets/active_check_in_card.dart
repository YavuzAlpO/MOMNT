import 'package:flutter/material.dart';
import 'package:momnt/models/check_in_session.dart';
import 'package:momnt/widgets/check_in_status_badge.dart';

class ActiveCheckInCard extends StatelessWidget {
  const ActiveCheckInCard({
    super.key,
    required this.session,
    this.onChangeStatus,
    this.onCheckOut,
  });

  final CheckInSession session;
  final VoidCallback? onChangeStatus;
  final VoidCallback? onCheckOut;

  static const _navy = Color(0xFF0F2167);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _navy.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _navy.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Şu an buradasın',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            session.venueName,
            style: const TextStyle(
              color: _navy,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          CheckInStatusBadge(status: session.status),
          if (onChangeStatus != null || onCheckOut != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (onChangeStatus != null)
                  TextButton(
                    onPressed: onChangeStatus,
                    child: const Text('Statüyü değiştir'),
                  ),
                if (onCheckOut != null)
                  TextButton(
                    onPressed: onCheckOut,
                    child: const Text('Check-out'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
