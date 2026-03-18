import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:body_progress/core/design_system.dart';
import 'package:body_progress/core/toast_manager.dart';
import 'package:body_progress/providers/stats_provider.dart';
import 'package:body_progress/providers/profile_provider.dart';
import 'package:body_progress/widgets/loading_button.dart';

class StatsEntryView extends ConsumerStatefulWidget {
  const StatsEntryView({super.key});
  @override
  ConsumerState<StatsEntryView> createState() => _StatsEntryViewState();
}

class _StatsEntryViewState extends ConsumerState<StatsEntryView> {
  @override
  Widget build(BuildContext context) {
    final statsState = ref.watch(statsProvider);
    final notifier = ref.read(statsProvider.notifier);
    final profileState = ref.watch(profileProvider);

    ref.listen(statsProvider, (_, next) {
      if (next.showingAlert && next.errorMessage != null) {
        ToastManager.shared.show(next.errorMessage!, type: ToastType.error);
        notifier.clearError();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      appBar: AppBar(title: const Text('Log Measurements')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Picker
            _DateSelector(
              date: statsState.selectedDate,
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: statsState.selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                  builder: (ctx, child) => Theme(
                    data: ThemeData.dark().copyWith(
                      colorScheme: const ColorScheme.dark(primary: AppColors.brandPrimary),
                    ),
                    child: child!,
                  ),
                );
                if (d != null) notifier.setSelectedDate(d);
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // Weight (required)
            _EntryCard(title: 'Weight *', icon: Icons.monitor_weight_outlined, fields: [
              _InputField(label: 'Weight (kg)', onChanged: notifier.setWeight),
            ]),
            const SizedBox(height: 12),

            // Circumferences
            _EntryCard(title: 'Circumferences', icon: Icons.straighten_outlined, fields: [
              _InputField(label: 'Waist (cm)', onChanged: notifier.setWaist),
              _InputField(label: 'Neck (cm)', onChanged: notifier.setNeck),
              _InputField(label: 'Hip (cm)', onChanged: notifier.setHip),
              _InputField(label: 'Chest (cm)', onChanged: notifier.setChest),
              _InputField(label: 'Arm (cm)', onChanged: notifier.setArm),
              _InputField(label: 'Thigh (cm)', onChanged: notifier.setThigh),
            ]),
            const SizedBox(height: 12),

            // Body Composition
            _EntryCard(title: 'Body Composition', icon: Icons.analytics_outlined, fields: [
              _InputField(label: 'Body Fat %', onChanged: notifier.setBodyFat),
              _InputField(label: 'Muscle Mass (kg)', onChanged: notifier.setMuscleMass),
            ]),
            const SizedBox(height: 12),

            // Notes
            _EntryCard(title: 'Notes', icon: Icons.note_outlined, fields: [
              _InputField(label: 'Optional notes…', onChanged: notifier.setNotes, maxLines: 3),
            ]),
            const SizedBox(height: AppSpacing.xl),

            LoadingButton(
              label: 'Save Measurements',
              isLoading: statsState.isLoading,
              onPressed: () async {
                final ok = await notifier.saveBodyStats(profile: profileState.profile);
                if (ok && context.mounted) {
                  ToastManager.shared.show('Measurements saved!', type: ToastType.success);
                  context.pop();
                }
              },
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;
  const _DateSelector({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: AppColors.brandPrimary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Date', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontFamily: 'Nunito')),
                  Text(DateFormat.yMMMMd().format(date),
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontFamily: 'Nunito')),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> fields;
  const _EntryCard({required this.title, required this.icon, required this.fields});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.brandPrimary, size: 18),
              const SizedBox(width: 8),
              Text(title, style: AppTextStyles.cardTitle),
            ],
          ),
          const SizedBox(height: 16),
          ...fields.map((f) => Padding(padding: const EdgeInsets.only(bottom: 12), child: f)),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final void Function(String) onChanged;
  final int maxLines;
  const _InputField({required this.label, required this.onChanged, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return TextField(
      keyboardType: maxLines == 1 ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.multiline,
      maxLines: maxLines,
      onChanged: onChanged,
      style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Nunito'),
      decoration: InputDecoration(labelText: label),
    );
  }
}
