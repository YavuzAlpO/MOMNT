import 'package:flutter/material.dart';
import 'package:momnt/models/check_in_status.dart';
import 'package:momnt/models/venue_model.dart';
import 'package:momnt/state/check_in_controller.dart';

Future<void> presentCheckInForVenue({
  required BuildContext context,
  required Venue venue,
  required double distanceMeters,
}) async {
  final checkIn = CheckInScope.of(context);
  final selected = await showCheckInSheet(
    context: context,
    venueName: venue.name,
    initialStatus:
        checkIn.isCheckedInAt(venue.id) ? checkIn.session?.status : null,
  );
  if (selected == null || !context.mounted) return;

  final ok = checkIn.tryCheckIn(
    venue: venue,
    status: selected,
    distanceMeters: distanceMeters,
  );
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        ok
            ? '${venue.name} · ${selected.label}'
            : checkIn.lastError ?? 'Check-in yapılamadı.',
      ),
    ),
  );
}

Future<CheckInStatus?> showCheckInSheet({
  required BuildContext context,
  required String venueName,
  CheckInStatus? initialStatus,
}) {
  return showModalBottomSheet<CheckInStatus>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => CheckInSheet(
      venueName: venueName,
      initialStatus: initialStatus,
    ),
  );
}

class CheckInSheet extends StatefulWidget {
  const CheckInSheet({
    super.key,
    required this.venueName,
    this.initialStatus,
  });

  final String venueName;
  final CheckInStatus? initialStatus;

  @override
  State<CheckInSheet> createState() => _CheckInSheetState();
}

class _CheckInSheetState extends State<CheckInSheet> {
  late CheckInStatus _selectedStatus =
      widget.initialStatus ?? CheckInStatus.drinkingCoffee;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.venueName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F2167),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          const Text(
            'Check-in yapmak üzeresin',
            style: TextStyle(color: Colors.grey, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          const Text(
            'Anlık Durumun',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 10),
          ...CheckInStatus.values.map((status) {
            final isSelected = _selectedStatus == status;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: InkWell(
                onTap: () => setState(() => _selectedStatus = status),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF0F2167).withValues(alpha: 0.08)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF0F2167)
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        status.icon,
                        color: isSelected
                            ? const Color(0xFF0F2167)
                            : Colors.black54,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          status.label,
                          style: TextStyle(
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected
                                ? const Color(0xFF0F2167)
                                : Colors.black87,
                          ),
                        ),
                      ),
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: isSelected
                            ? const Color(0xFF0F2167)
                            : Colors.grey,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, _selectedStatus),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F2167),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Check-in\'i Başlat',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
