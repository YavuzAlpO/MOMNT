import 'package:flutter/material.dart';
import 'package:momnt/theme/momnt_theme.dart';
import 'package:momnt/models/check_in_duration.dart';
import 'package:momnt/models/check_in_status.dart';
import 'package:momnt/models/venue_model.dart';
import 'package:momnt/state/check_in_controller.dart';
import 'package:momnt/services/location_service.dart';

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
  if (checkIn.isCheckedInAt(venue.id)) {
    await presentCheckInEdit(context: context);
    return;
  }
  final selected = await showCheckInSheet(
    context: context,
    venueName: venue.name,
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

/// Düzenleme yalnızca açıldığı oturuma uygulanır; iptal state'i değiştirmez.
Future<void> presentCheckInEdit({required BuildContext context}) async {
  final controller = CheckInScope.read(context);
  final session = controller.session;
  if (session == null) return;
  final selected = await showCheckInSheet(
    context: context,
    venueName: session.venueName,
    initialStatus: session.status,
    initialDuration: session.duration,
    isEditing: true,
  );
  if (selected == null || !context.mounted) return;
  final updated = controller.updateStatus(
    selected.status,
    duration: selected.duration,
    expectedSession: session,
  );
  if (!updated) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bu check-in artık aktif değil.')),
    );
  }
}

Future<CheckInSelection?> showCheckInSheet({
  required BuildContext context,
  required String venueName,
  CheckInStatus? initialStatus,
  CheckInDuration? initialDuration,
  bool showDurationPicker = true,
  bool isEditing = false,
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
      isEditing: isEditing,
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
    this.isEditing = false,
  });

  final String venueName;
  final CheckInStatus? initialStatus;
  final CheckInDuration? initialDuration;
  final bool showDurationPicker;
  final bool isEditing;

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
                  color: MomntColors.outline,
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
                color: MomntColors.accent,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              widget.isEditing
                  ? 'Statünü ve süreni güncelle'
                  : 'Check-in yapmak üzeresin',
              style: const TextStyle(color: MomntColors.muted, fontSize: 13),
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
                          ? MomntColors.accent.withValues(alpha: 0.08)
                          : MomntColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? MomntColors.accent
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          status.icon,
                          color: isSelected
                              ? MomntColors.accent
                              : MomntColors.muted,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            status.label,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? MomntColors.accent
                                  : MomntColors.ink,
                            ),
                          ),
                        ),
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: isSelected
                              ? MomntColors.accent
                              : MomntColors.muted,
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
                      selectedColor: MomntColors.accent.withValues(alpha: 0.12),
                      labelStyle: TextStyle(
                        color: MomntColors.accent,
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
            if (widget.showDurationPicker) ...[
              const SizedBox(height: 10),
              Text(
                'Check-in toplam en fazla ${MomntLocationRules.sessionTimeout.inHours} saat sürer.'
                '${widget.isEditing ? ' Farklı bir süre seçersen yeni süre şimdi başlar.' : ''}',
                style: const TextStyle(color: MomntColors.muted, fontSize: 12),
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
                backgroundColor: MomntColors.accent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                widget.isEditing
                    ? 'Değişiklikleri Kaydet'
                    : 'Check-in\'i Başlat',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
          ],
        ),
      ),
    );
  }
}
