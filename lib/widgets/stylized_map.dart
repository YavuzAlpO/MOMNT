import 'dart:math';

import 'package:flutter/material.dart';
import 'package:momnt/services/venue_service.dart';
import 'package:momnt/theme/momnt_theme.dart';

class StylizedMap extends StatelessWidget {
  const StylizedMap({
    super.key,
    required this.userLatitude,
    required this.userLongitude,
    required this.venues,
    required this.selectedId,
    required this.onSelect,
  });

  final double userLatitude;
  final double userLongitude;
  final List<NearbyVenue> venues;
  final String? selectedId;
  final ValueChanged<NearbyVenue> onSelect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final projector = _MapProjector(
          userLatitude: userLatitude,
          userLongitude: userLongitude,
          venues: venues,
          size: size,
        );

        return Stack(
          children: [
            const Positioned.fill(child: CustomPaint(painter: _MapPainter())),
            Positioned(
              left: projector.userOffset.dx - 10,
              top: projector.userOffset.dy - 10,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: MomntColors.navyDeep,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: MomntColors.navyDeep.withValues(alpha: 0.35),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
            ),
            for (final nearby in venues)
              _MapPin(
                offset: projector.offsetFor(nearby),
                selected: nearby.venue.id == selectedId,
                label: nearby.venue.name,
                onTap: () => onSelect(nearby),
              ),
          ],
        );
      },
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({
    required this.offset,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final Offset offset;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final size = selected ? 44.0 : 36.0;
    return Positioned(
      left: offset.dx - size / 2,
      top: offset.dy - size,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: selected ? MomntColors.navyDeep : MomntColors.navy,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: const [
                  BoxShadow(color: Color(0x33000000), blurRadius: 8),
                ],
              ),
              child: const Icon(Icons.place, color: Colors.white, size: 18),
            ),
            if (selected)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: MomntColors.navy,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MapProjector {
  _MapProjector({
    required this.userLatitude,
    required this.userLongitude,
    required this.venues,
    required this.size,
  }) {
    final lats = [userLatitude, ...venues.map((item) => item.venue.latitude)];
    final lngs = [userLongitude, ...venues.map((item) => item.venue.longitude)];
    minLat = lats.reduce(min) - 0.004;
    maxLat = lats.reduce(max) + 0.004;
    minLng = lngs.reduce(min) - 0.004;
    maxLng = lngs.reduce(max) + 0.004;
  }

  final double userLatitude;
  final double userLongitude;
  final List<NearbyVenue> venues;
  final Size size;
  late final double minLat;
  late final double maxLat;
  late final double minLng;
  late final double maxLng;

  Offset get userOffset => project(userLatitude, userLongitude);

  Offset offsetFor(NearbyVenue nearby) {
    return project(nearby.venue.latitude, nearby.venue.longitude);
  }

  Offset project(double lat, double lng) {
    final x = (lng - minLng) / (maxLng - minLng);
    final y = 1 - (lat - minLat) / (maxLat - minLat);
    return Offset(
      24 + x * (size.width - 48),
      24 + y * (size.height - 48),
    );
  }
}

class _MapPainter extends CustomPainter {
  const _MapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = MomntColors.mapFill);

    final park = Paint()..color = MomntColors.mapPark;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.08, size.height * 0.18, 120, 90),
        const Radius.circular(18),
      ),
      park,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.62, size.height * 0.55, 140, 110),
        const Radius.circular(22),
      ),
      park,
    );

    final road = Paint()
      ..color = MomntColors.mapRoad
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(0, size.height * 0.32),
      Offset(size.width, size.height * 0.38),
      road,
    );
    canvas.drawLine(
      Offset(size.width * 0.28, 0),
      Offset(size.width * 0.42, size.height),
      road,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.72),
      Offset(size.width, size.height * 0.64),
      road,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
