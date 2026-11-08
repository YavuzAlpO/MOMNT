import 'dart:async';

import 'package:flutter/material.dart';
import 'package:momnt/theme/momnt_theme.dart';
import 'package:momnt/models/check_in_session.dart';
import 'package:momnt/models/mutual_follow_profile.dart';
import 'package:momnt/utils/formatters.dart';
import 'package:momnt/widgets/check_in_status_badge.dart';
import 'package:momnt/widgets/mutual_follow_avatars.dart';

class ActiveCheckInCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    if (compact) {
      return Material(
        color: MomntColors.soft,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          side: BorderSide(color: MomntColors.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: MomntColors.accent,
                    ),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Aktif check-in',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: MomntColors.accent,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: MomntColors.accent,
                    ),
                  ],
                ),
                Text(
                  session.venueName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: MomntColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  session.status.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: MomntColors.muted,
                  ),
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule,
                      size: 13,
                      color: MomntColors.accent,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _CountdownText(
                        session: session,
                        style: const TextStyle(
                          fontSize: 12,
                          color: MomntColors.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (mutualFollows.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 40,
                        height: 26,
                        child: FittedBox(
                          child: MutualFollowAvatars(profiles: mutualFollows),
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
        color: MomntColors.soft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: MomntColors.outline),
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
                    color: MomntColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (mutualFollows.isNotEmpty) ...[
                const SizedBox(width: 10),
                Flexible(
                  flex: 2,
                  child: MutualFollowAvatars(profiles: mutualFollows),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            session.venueName,
            style: const TextStyle(
              color: MomntColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          CheckInStatusBadge(status: session.status),
          const SizedBox(height: 10),
          _LifecycleBanner(session: session),
          if (onChangeStatus != null || onCheckOut != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (onChangeStatus != null)
                  TextButton(
                    onPressed: onChangeStatus,
                    child: const Text('Statüyü değiştir'),
                  ),
                if (onCheckOut != null)
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: onCheckOut,
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
  const _LifecycleBanner({required this.session});

  final CheckInSession session;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CountdownText(
          session: session,
          prefix: 'Kalan süre ',
          style: const TextStyle(
            color: MomntColors.accent,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          session.autoExtendCount > 0
              ? '${session.duration.label} · ${session.autoExtendCount} kez uzatıldı'
              : session.duration.label,
          style: const TextStyle(color: MomntColors.muted, fontSize: 12),
        ),
      ],
    );
  }
}

class _CountdownText extends StatefulWidget {
  const _CountdownText({
    required this.session,
    required this.style,
    this.prefix = '',
  });

  final CheckInSession session;
  final TextStyle style;
  final String prefix;

  @override
  State<_CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<_CountdownText> {
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTimer();
  }

  @override
  void didUpdateWidget(covariant _CountdownText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session.expiresAt != widget.session.expiresAt) _syncTimer();
  }

  void _syncTimer() {
    final tabVisible = TickerMode.valuesOf(context).enabled;
    final routeVisible = ModalRoute.isCurrentOf(context) ?? true;
    if (!tabVisible ||
        !routeVisible ||
        widget.session.expiresAt == null ||
        widget.session.isExpired()) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    _timer ??= Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {});
      if (widget.session.isExpired()) {
        timer.cancel();
        _timer = null;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      '${widget.prefix}${formatCountdown(widget.session.remaining())}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: widget.style,
    );
  }
}
