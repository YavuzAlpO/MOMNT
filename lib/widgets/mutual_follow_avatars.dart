import 'dart:async';

import 'package:flutter/material.dart';
import 'package:momnt/models/mutual_follow_profile.dart';

/// Arkadan görünen küçük fotoğraflarla tek grup simgesi ve profil önizlemesi.
class MutualFollowAvatars extends StatefulWidget {
  const MutualFollowAvatars({super.key, required this.profiles});
  final List<MutualFollowProfile> profiles;

  @override
  State<MutualFollowAvatars> createState() => _MutualFollowAvatarsState();
}

class _MutualFollowAvatarsState extends State<MutualFollowAvatars> {
  static const _visibleCount = 5;
  final _menu = MenuController();
  Timer? _closeTimer;
  bool _hovered = false;

  void _keepOpen() => _closeTimer?.cancel();

  void _closeSoon() {
    _closeTimer?.cancel();
    // İmleç panelin üzerine geçerken kapanıp açılmasını engeller.
    _closeTimer = Timer(const Duration(milliseconds: 180), () {
      if (mounted) _menu.close();
    });
  }

  @override
  void dispose() {
    _closeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profiles = widget.profiles;
    if (profiles.isEmpty) return const SizedBox.shrink();
    final visible = profiles.take(_visibleCount).toList();
    final icons = SizedBox(
      width: 32 + (visible.length - 1) * 8,
      height: 40,
      child: Stack(
        children: [
          // Arkadakileri önce çiz; öndeki fotoğraf tamamıyla görünsün.
          for (var i = visible.length - 1; i >= 0; i--)
            Positioned(
              left: i * 8,
              top: (visible.length - 1 - i) * 1.5,
              child: _ProfileAvatar(profile: visible[i]),
            ),
        ],
      ),
    );
    return MenuAnchor(
      controller: _menu,
      consumeOutsideTap: true,
      style: const MenuStyle(
        padding: WidgetStatePropertyAll(EdgeInsets.zero),
        backgroundColor: WidgetStatePropertyAll(Colors.white),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
      ),
      menuChildren: [
        MouseRegion(
          onEnter: (_) => _keepOpen(),
          onExit: (_) => _closeSoon(),
          child: _ProfilePreview(profiles: profiles),
        ),
      ],
      builder: (context, controller, child) => MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) {
          _keepOpen();
          setState(() => _hovered = true);
          controller.open();
        },
        onExit: (_) {
          setState(() => _hovered = false);
          _closeSoon();
        },
        child: AnimatedScale(
          scale: _hovered ? 1.05 : 1,
          duration: const Duration(milliseconds: 160),
          child: TextButton(
            key: const ValueKey('mutual-follow-group'),
            onPressed: () {
              _keepOpen();
              controller.isOpen ? controller.close() : controller.open();
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Semantics(
              label: '${profiles.length} kişinin profilini önizle',
              excludeSemantics: true,
              child: icons,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfilePreview extends StatelessWidget {
  const _ProfilePreview({required this.profiles});
  final List<MutualFollowProfile> profiles;

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.sizeOf(context).width - 32).clamp(0.0, 320.0);
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Takipleştiğin kişiler (${profiles.length})',
              style: const TextStyle(
                color: Color(0xFF0F2167),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: SingleChildScrollView(
                primary: false,
                child: Wrap(
                  spacing: 10,
                  runSpacing: 14,
                  children: [
                    for (final profile in profiles)
                      Tooltip(
                        message: profile.username,
                        child: SizedBox(
                          width: 88,
                          child: Column(
                            children: [
                              _ProfileAvatar(profile: profile, size: 56),
                              const SizedBox(height: 6),
                              Text(
                                profile.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
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
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.profile, this.size = 32});
  final MutualFollowProfile profile;
  final double size;

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      color: const Color(0xFFE2E8F0),
      child: Icon(
        Icons.person,
        color: const Color(0xFF0F2167),
        size: size * 0.55,
      ),
    );
    return Semantics(
      image: true,
      label: '${profile.name}, karşılıklı takipleşiyorsunuz',
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(
            color: const Color(0xFF0F2167).withValues(alpha: 0.25),
          ),
        ),
        child: ClipOval(
          child: profile.avatarUrl == null
              ? placeholder
              : Image.network(
                  profile.avatarUrl!,
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                  errorBuilder: (_, _, _) => placeholder,
                ),
        ),
      ),
    );
  }
}
