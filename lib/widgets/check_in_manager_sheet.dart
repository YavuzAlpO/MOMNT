import 'package:flutter/material.dart';
import 'package:momnt/theme/momnt_theme.dart';
import 'package:momnt/services/location_service.dart';
import 'package:momnt/services/venue_service.dart';
import 'package:momnt/state/check_in_controller.dart';
import 'package:momnt/utils/formatters.dart';
import 'package:momnt/widgets/active_check_in_card.dart';
import 'package:momnt/widgets/check_in_sheet.dart';

Future<void> showCheckInManager(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => const CheckInManagerSheet(),
  );
}

/// Alt menüdeki + düğmesinin açtığı check-in yönetimi.
class CheckInManagerSheet extends StatefulWidget {
  const CheckInManagerSheet({
    super.key,
    this.locationService = const LocationService(),
    this.venueService = const VenueService(),
  });

  final LocationService locationService;
  final VenueService venueService;

  @override
  State<CheckInManagerSheet> createState() => _CheckInManagerSheetState();
}

class _CheckInManagerSheetState extends State<CheckInManagerSheet> {
  bool _busy = false;
  String? _error;
  List<NearbyVenue> _venues = const [];

  @override
  void initState() {
    super.initState();
    if (!CheckInScope.read(context).isCheckedIn) _loadNearby();
  }

  Future<void> _loadNearby() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final position = await widget.locationService.getCurrentPosition();
      final venues = widget.venueService.discoverWithinRadius(
        userLatitude: position.latitude,
        userLongitude: position.longitude,
        locationService: widget.locationService,
      );
      if (!mounted) return;
      setState(() => _venues = venues);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is LocationPermissionException
            ? error.message
            : 'Konum alınamadı. Konum iznini ve konum servisini kontrol et.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _startCheckIn(NearbyVenue nearby) async {
    final controller = CheckInScope.read(context);
    final selected = await showCheckInSheet(
      context: context,
      venueName: nearby.venue.name,
    );
    if (selected == null || !mounted) return;
    // Seçim penceresi açıkken başka bir oturum başlamışsa üstüne yazma.
    if (controller.isCheckedIn) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    // Kaydederken konumu tekrar al: listede görülen mesafeye güvenme.
    final ok = await controller.checkInWithLiveLocation(
      venue: nearby.venue,
      status: selected.status,
      duration: selected.duration,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = ok ? null : controller.lastError;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = CheckInScope.of(context);
    final session = controller.session;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.8,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              session == null ? 'Check-in yap' : 'Check-in yönetimi',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: MomntColors.accent,
              ),
            ),
            const SizedBox(height: 16),
            if (session != null)
              ActiveCheckInCard(
                session: session,
                onChangeStatus: () => presentCheckInEdit(context: context),
                onCheckOut: () {
                  controller.endCheckIn();
                  _loadNearby();
                },
              )
            else ...[
              Text(
                'Mekânını seç. Check-in için en fazla '
                '${MomntLocationRules.checkInProximityMeters.round()} m uzakta olmalısın.',
              ),
              const SizedBox(height: 12),
              if (_busy)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (_error != null) ...[
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 8),
              ],
              for (final nearby in _venues)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.place_outlined),
                  title: Text(nearby.venue.name),
                  subtitle: Text(
                    '${nearby.venue.category} · ${formatDistance(nearby.distanceMeters)}',
                  ),
                  trailing: Icon(
                    widget.locationService.canCheckIn(nearby.distanceMeters)
                        ? Icons.chevron_right
                        : Icons.location_off_outlined,
                  ),
                  enabled:
                      !_busy &&
                      widget.locationService.canCheckIn(nearby.distanceMeters),
                  onTap: () => _startCheckIn(nearby),
                ),
              if (!_busy && _venues.isEmpty && _error == null)
                const Text('Yakınında bir mekân bulunamadı.'),
              TextButton.icon(
                onPressed: _busy ? null : _loadNearby,
                icon: const Icon(Icons.my_location),
                label: const Text('Konumu yenile'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
