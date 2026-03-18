import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:body_progress/core/design_system.dart';
import 'package:body_progress/core/router.dart';
import 'package:body_progress/core/toast_manager.dart';
import 'package:body_progress/models/body_stats.dart';
import 'package:body_progress/providers/stats_provider.dart';
import 'package:body_progress/providers/progress_provider.dart';
import 'package:body_progress/providers/profile_provider.dart';

class StatsView extends ConsumerStatefulWidget {
  const StatsView({super.key});
  @override
  ConsumerState<StatsView> createState() => _StatsViewState();
}

class _StatsViewState extends ConsumerState<StatsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        ref.read(statsProvider.notifier).loadFromCache());
  }

  @override
  Widget build(BuildContext context) {
    final statsState = ref.watch(statsProvider);
    final stats = ref.watch(progressProvider).cachedBodyStats;

    ref.listen(statsProvider, (_, next) {
      if (next.showingAlert && next.errorMessage != null) {
        ToastManager.shared.show(next.errorMessage!, type: ToastType.error);
        ref.read(statsProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      appBar: AppBar(
        title: const Text('Body Stats'),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(gradient: AppGradients.brand, shape: BoxShape.circle),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
            onPressed: () => context.go(AppRoutes.statsEntry),
          ),
        ],
      ),
      body: stats.isEmpty
          ? _EmptyStatsState()
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: stats.length,
              itemBuilder: (_, i) => _StatsCard(stat: stats[i]),
            ),
    );
  }
}

class _StatsCard extends ConsumerWidget {
  final BodyStats stat;
  const _StatsCard({required this.stat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(stat.id ?? stat.date.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.errorRed.withOpacity(0.2),
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.errorRed),
      ),
      onDismissed: (_) async {
        await ref.read(statsProvider.notifier).deleteBodyStats(stat);
        ToastManager.shared.show('Measurement deleted', type: ToastType.success);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    gradient: AppGradients.brand,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.monitor_weight_outlined, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(DateFormat.yMMMd().format(stat.date),
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontFamily: 'Nunito')),
                      Text('${stat.weight.toStringAsFixed(1)} kg',
                          style: const TextStyle(color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700, fontSize: 18, fontFamily: 'Nunito')),
                    ],
                  ),
                ),
                if (stat.bmi != null)
                  _StatBadge(label: 'BMI', value: stat.bmi!.toStringAsFixed(1)),
              ],
            ),
            if (stat.waistCircumference != null || stat.bodyFatPercentage != null) ...[
              const SizedBox(height: 12),
              const Divider(color: Color(0xFF2C2C2E), height: 1),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  if (stat.waistCircumference != null)
                    _MeasurementChip(label: 'Waist', value: '${stat.waistCircumference!.toStringAsFixed(1)} cm'),
                  if (stat.neckCircumference != null)
                    _MeasurementChip(label: 'Neck', value: '${stat.neckCircumference!.toStringAsFixed(1)} cm'),
                  if (stat.hipCircumference != null)
                    _MeasurementChip(label: 'Hip', value: '${stat.hipCircumference!.toStringAsFixed(1)} cm'),
                  if (stat.bodyFatPercentage != null)
                    _MeasurementChip(label: 'Body Fat', value: '${stat.bodyFatPercentage!.toStringAsFixed(1)}%'),
                  if (stat.muscleMass != null)
                    _MeasurementChip(label: 'Muscle', value: '${stat.muscleMass!.toStringAsFixed(1)} kg'),
                ],
              ),
            ],
            if (stat.notes != null && stat.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(stat.notes!,
                    style: const TextStyle(color: AppColors.textTertiary, fontSize: 13, fontFamily: 'Nunito')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  const _StatBadge({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.brandSecondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: AppColors.brandSecondary, fontWeight: FontWeight.w700, fontSize: 15, fontFamily: 'Nunito')),
          Text(label, style: const TextStyle(color: AppColors.textTertiary, fontSize: 10, fontFamily: 'Nunito')),
        ],
      ),
    );
  }
}

class _MeasurementChip extends StatelessWidget {
  final String label;
  final String value;
  const _MeasurementChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.darkCardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontFamily: 'Nunito')),
          const SizedBox(width: 4),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12, fontFamily: 'Nunito')),
        ],
      ),
    );
  }
}

class _EmptyStatsState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AppColors.brandPrimary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.straighten_outlined, color: AppColors.brandPrimary, size: 36),
            ),
            const SizedBox(height: 16),
            const Text('No measurements yet',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 17, fontFamily: 'Nunito')),
            const SizedBox(height: 8),
            const Text('Log your first body measurements to start tracking',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textTertiary, fontSize: 14, fontFamily: 'Nunito')),
          ],
        ),
      ),
    );
  }
}
