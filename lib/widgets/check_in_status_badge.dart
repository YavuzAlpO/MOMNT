import 'package:flutter/material.dart';
import 'package:momnt/models/check_in_status.dart';

class CheckInStatusBadge extends StatelessWidget {
  const CheckInStatusBadge({super.key, required this.status});

  final CheckInStatus status;

  static const _navy = Color(0xFF0F2167);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _navy.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _navy.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 16, color: _navy),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: const TextStyle(
              color: _navy,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
