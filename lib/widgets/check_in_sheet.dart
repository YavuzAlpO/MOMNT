import 'package:flutter/material.dart';
import 'package:momnt/models/check_in_duration.dart';
import 'package:momnt/models/check_in_status.dart';
import 'package:momnt/models/venue_model.dart';
import 'package:momnt/state/check_in_controller.dart';

class CheckInSelection {
  const CheckInSelection({
    required this.status,
    this.duration = CheckInDuration.defaultValue,
  });

  final CheckInStatus status;
  final CheckInDuration duration;
}

Future<void> presentCheckInForVenue({
  required BuildContext context,
  required Venue venue,
  required double distanceMeters,
}) async {
  final checkIn = CheckInScope.read(context);
  final selected = await showCheckInSheet(
    context: context,
    venueName: venue.name,
    initialStatus:
        checkIn.isCheckedInAt(venue.id) ? checkIn.session?.status : null,
    initialDuration: checkIn.session?.duration,
  );
  if (selected == null || !context.mounted) return;

  final ok = checkIn.tryCheckIn(
    venue: venue,
    status: selected.status,
    duration: selected.duration,
    distanceMeters: distanceMeters,
  );
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        ok
            ? '${venue.name} · ${selected.status.label}'
            : checkIn.lastError ?? 'Check-in yapılamadı.',
      ),
    ),
  );
}

Future<CheckInSelection?> showCheckInSheet({
  required BuildContext context,
  required String venueName,
  CheckInStatus? initialStatus,
  CheckInDuration? initialDuration,
  bool showDurationPicker = true,
}) {
  return showModalBottomSheet<CheckInSelection>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => CheckInSheet(
      venueName: venueName,
      initialStatus: initialStatus,
      initialDuration: initialDuration,
      showDurationPicker: showDurationPicker,
    ),
  );
}

class CheckInSheet extends StatefulWidget {
  const CheckInSheet({
    super.key,
    required this.venueName,
    this.initialStatus,
    this.initialDuration,
    this.showDurationPicker = true,
  });

  final String venueName;
  final CheckInStatus? initialStatus;
  final CheckInDuration? initialDuration;
  final bool showDurationPicker;

  @override
  State<CheckInSheet> createState() => _CheckInSheetState();
}

class _CheckInSheetState extends State<CheckInSheet> {
  late CheckInStatus _selectedStatus =
      widget.initialStatus ?? CheckInStatus.drinkingCoffee;
  late CheckInDuration _selectedDuration =
      widget.initialDuration ?? CheckInDuration.defaultValue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
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
          if (widget.showDurationPicker) ...[
            const SizedBox(height: 8),
            const Text(
              'Ne kadar kalacaksın?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final duration in CheckInDuration.values)
                  ChoiceChip(
                    label: Text(duration.label),
                    selected: _selectedDuration == duration,
                    selectedColor: const Color(0xFF0F2167).withValues(alpha: 0.12),
                    labelStyle: TextStyle(
                      color: const Color(0xFF0F2167),
                      fontWeight: _selectedDuration == duration
                          ? FontWeight.w800
                          : FontWeight.w500,
                    ),
                    onSelected: (_) =>
                        setState(() => _selectedDuration = duration),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(
              context,
              CheckInSelection(
                status: _selectedStatus,
                duration: _selectedDuration,
              ),
            ),
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
      ),
    );
  }
}
