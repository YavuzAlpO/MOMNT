import 'dart:async';

import 'package:flutter/material.dart';
import 'package:momnt/models/check_in_session.dart';
import 'package:momnt/models/mutual_follow_profile.dart';
import 'package:momnt/utils/formatters.dart';
import 'package:momnt/widgets/check_in_status_badge.dart';
import 'package:momnt/widgets/mutual_follow_avatars.dart';

class ActiveCheckInCard extends StatefulWidget {
  const ActiveCheckInCard({
    super.key,
    required this.session,
    this.mutualFollows = const [],
    this.onChangeStatus,
    this.onCheckOut,
    this.compact = false,
    this.onOpen,
  });

  final CheckInSession session;
  final List<MutualFollowProfile> mutualFollows;
  final VoidCallback? onChangeStatus;
  final VoidCallback? onCheckOut;
  final bool compact;
  final VoidCallback? onOpen;

  @override
  State<ActiveCheckInCard> createState() => _ActiveCheckInCardState();
}

class _ActiveCheckInCardState extends State<ActiveCheckInCard> {
  static const _navy = Color(0xFF0F2167);
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _syncTicker();
  }

  @override
  void didUpdateWidget(covariant ActiveCheckInCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session.expiresAt != widget.session.expiresAt) {
      _syncTicker();
    }
  }

  void _syncTicker() {
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final remaining = session.remaining();

    if (widget.compact) {
      return Material(
        color: _navy.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _navy.withValues(alpha: 0.16)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onOpen,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: _navy),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Aktif check-in',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: _navy),
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 16, color: _navy),
                  ],
                ),
                Text(
                  session.venueName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  session.status.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: _navy),
                ),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 13, color: _navy),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        formatCountdown(remaining),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _navy,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (widget.mutualFollows.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 40,
                        height: 26,
                        child: FittedBox(
                          child: MutualFollowAvatars(
                            profiles: widget.mutualFollows,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

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
          Row(
            children: [
              const Flexible(
                child: Text(
                  'Şu an buradasın',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (widget.mutualFollows.isNotEmpty) ...[
                const SizedBox(width: 10),
                Flexible(
                  flex: 2,
                  child: MutualFollowAvatars(profiles: widget.mutualFollows),
                ),
              ],
            ],
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
          const SizedBox(height: 10),
          _LifecycleBanner(session: session, remaining: remaining),
          if (widget.onChangeStatus != null || widget.onCheckOut != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (widget.onChangeStatus != null)
                  TextButton(
                    onPressed: widget.onChangeStatus,
                    child: const Text('Statüyü değiştir'),
                  ),
                if (widget.onCheckOut != null)
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: widget.onCheckOut,
                        child: const Text("Check-in'i Bitir"),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LifecycleBanner extends StatelessWidget {
  const _LifecycleBanner({required this.session, required this.remaining});

  final CheckInSession session;
  final Duration remaining;

  static const _navy = Color(0xFF0F2167);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kalan süre ${formatCountdown(remaining)}',
          style: const TextStyle(
            color: _navy,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          session.autoExtendCount > 0
              ? '${session.duration.label} · ${session.autoExtendCount} kez uzatıldı'
              : session.duration.label,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }
}
