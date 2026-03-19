import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:body_progress/core/design_system.dart';
import 'package:body_progress/core/toast_manager.dart';
import 'package:body_progress/models/body_stats.dart';
import 'package:body_progress/providers/progress_provider.dart';
import 'package:body_progress/providers/photo_provider.dart';
import 'package:body_progress/services/export_service.dart';

class ProgressView extends ConsumerWidget {
  const ProgressView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressState = ref.watch(progressProvider);
    final notifier = ref.read(progressProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      appBar: AppBar(
        title: const Text('Progress'),
        actions: [
          // Export button
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Export Data',
            onPressed: () {
              _showExportOptions(context, ref);
            },
          ),
          IconButton(
            icon: const Icon(Icons.sync_outlined),
            tooltip: 'Sync Health Data',
            onPressed: () async {
              try {
                final healthService = notifier.healthService;
                
                // Check permissions
                final hasPermission = await healthService.hasPermissions();
                
                if (!hasPermission) {
                  ToastManager.shared.show(
                    'Requesting health data access...',
                    type: ToastType.info,
                  );
                  
                  final granted = await healthService.requestAuthorization();
                  
                  if (!granted) {
                    final settingsPath = Platform.isIOS
                        ? 'Settings → Privacy & Security → Health → Body Progress'
                        : 'Settings → Apps → Body Progress → Permissions → Health Connect';
                    ToastManager.shared.show(
                      'Health access denied. Open $settingsPath to enable access.',
                      type: ToastType.error,
                    );
                    return;
                  }
                  
                  ToastManager.shared.show(
                    'Health access granted! Starting sync...',
                    type: ToastType.success,
                  );
                }
                
                // Show loading dialog and perform sync
                final navigator = Navigator.of(context);
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (dialogContext) => WillPopScope(
                    onWillPop: () async => false,
                    child: AlertDialog(
                      backgroundColor: AppColors.cardBackground,
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: AppColors.brandPrimary),
                          const SizedBox(height: 16),
                          const Text(
                            'Syncing health data...',
                            style: TextStyle(color: AppColors.textPrimary, fontFamily: 'Nunito'),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Reading from HealthKit',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontFamily: 'Nunito',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
                
                // Perform sync
                final result = await notifier.syncWithHealth();
                
                // Safely dismiss loading dialog and show result using post-frame callback
                if (context.mounted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) {
                      try {
                        navigator.pop();
                      } catch (e) {
                        // Dialog already dismissed or navigator disposed
                      }
                      
                      // Show result after dialog is dismissed
                      ToastManager.shared.show(
                        result.errorMessage ?? 'Synced ${result.uploadedCount} entries',
                        type: result.errorMessage != null ? ToastType.error : ToastType.success,
                      );
                    }
                  });
                }
              } catch (e) {
                print('Error syncing health data: $e');
                // Safely dismiss loading dialog and show error using post-frame callback
                if (context.mounted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) {
                      try {
                        Navigator.of(context).pop();
                      } catch (_) {
                        // Dialog already dismissed or navigator disposed
                      }
                      
                      // Show error after dialog is dismissed
                      ToastManager.shared.show(
                        'Sync failed: ${e.toString()}',
                        type: ToastType.error,
                      );
                    }
                  });
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time Range Selector
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: TimeRange.values.map((r) {
                  final isSelected = progressState.selectedTimeRange == r;
                  return GestureDetector(
                    onTap: () => notifier.setTimeRange(r),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: isSelected ? AppGradients.brand : null,
                        color: isSelected ? null : AppColors.darkCardBackground,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(r.displayName,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                            fontFamily: 'Nunito',
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                            fontSize: 13,
                          )),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Metric Selector
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ProgressMetric.values.map((m) {
                  final isSelected = progressState.selectedMetric == m;
                  return GestureDetector(
                    onTap: () => notifier.setMetric(m),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.brandPrimary.withOpacity(0.15)
                            : AppColors.darkCardBackground,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppColors.brandPrimary : Colors.transparent,
                        ),
                      ),
                      child: Text(m.displayName,
                          style: TextStyle(
                            color: isSelected ? AppColors.brandPrimary : AppColors.textSecondary,
                            fontFamily: 'Nunito',
                            fontSize: 12,
                          )),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Chart
            _ChartCard(progressState: progressState, notifier: notifier),
            const SizedBox(height: AppSpacing.md),

            // Stats Summary Cards
            if (notifier.currentValue != null) ...[
              Row(
                children: [
                  Expanded(child: _SummaryCard(
                    label: 'Current',
                    value: '${notifier.currentValue!.toStringAsFixed(1)} ${progressState.selectedMetric.unit}',
                    color: AppColors.brandPrimary,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _SummaryCard(
                    label: 'Change',
                    value: '${notifier.totalChange != null && notifier.totalChange! >= 0 ? '+' : ''}${notifier.totalChange?.toStringAsFixed(1) ?? '--'}',
                    color: _changeColor(notifier.totalChange, progressState.selectedMetric),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _SummaryCard(
                    label: 'Average',
                    value: '${notifier.averageValue?.toStringAsFixed(1) ?? '--'}',
                    color: AppColors.brandSecondary,
                  )),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.md),

            // All Stats List
            if (progressState.cachedBodyStats.isNotEmpty) ...[
              const Text(
                'All Measurements',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Nunito',
                ),
              ),
              const SizedBox(height: 12),
              ...progressState.cachedBodyStats.take(20).map((stat) => 
                _StatEntryCard(stat: stat, metric: progressState.selectedMetric)
              ),
              if (progressState.cachedBodyStats.length > 20)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Text(
                      'Showing 20 of ${progressState.cachedBodyStats.length} entries',
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 13,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Color _changeColor(double? change, ProgressMetric metric) {
    if (change == null) return AppColors.textSecondary;
    final isPositiveGood = [ProgressMetric.muscleMass].contains(metric);
    final isGood = isPositiveGood ? change >= 0 : change <= 0;
    return isGood ? AppColors.successGreen : AppColors.errorRed;
  }

  void _showExportOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Export Data',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                fontFamily: 'Nunito',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose what data you want to export',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                fontFamily: 'Nunito',
              ),
            ),
            const SizedBox(height: 24),
            _ExportOptionTile(
              icon: Icons.straighten,
              title: 'Body Stats Only',
              subtitle: 'Export all measurements and stats as CSV',
              onTap: () async {
                Navigator.pop(context);
                try {
                  final stats = ref.read(progressProvider).cachedBodyStats;
                  await ExportService().exportBodyStats(stats);
                  ToastManager.shared.show('Stats exported successfully!', type: ToastType.success);
                } catch (e) {
                  ToastManager.shared.show('Export failed: $e', type: ToastType.error);
                }
              },
            ),
            const SizedBox(height: 12),
            _ExportOptionTile(
              icon: Icons.description,
              title: 'Full Report',
              subtitle: 'Export stats, photos, and summary',
              onTap: () async {
                Navigator.pop(context);
                try {
                  final stats = ref.read(progressProvider).cachedBodyStats;
                  final photos = ref.read(photoProvider).photos;
                  await ExportService().exportFullReport(stats: stats, photos: photos);
                  ToastManager.shared.show('Full report exported!', type: ToastType.success);
                } catch (e) {
                  ToastManager.shared.show('Export failed: $e', type: ToastType.error);
                }
              },
            ),
            const SizedBox(height: 12),
            _ExportOptionTile(
              icon: Icons.monitor_weight,
              title: 'Weight Data Only',
              subtitle: 'Export just weight and BMI',
              onTap: () async {
                Navigator.pop(context);
                try {
                  final stats = ref.read(progressProvider).cachedBodyStats;
                  await ExportService().exportWeightData(stats);
                  ToastManager.shared.show('Weight data exported!', type: ToastType.success);
                } catch (e) {
                  ToastManager.shared.show('Export failed: $e', type: ToastType.error);
                }
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final ProgressState progressState;
  final ProgressNotifier notifier;
  const _ChartCard({required this.progressState, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final chartData = notifier.chartData;

    return Container(
      height: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: chartData.isEmpty
          ? const Center(
              child: Text('No data for selected time range',
                  style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Nunito')))
          : LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.white.withOpacity(0.05),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      getTitlesWidget: (value, _) => Text(
                        value.toStringAsFixed(0),
                        style: const TextStyle(
                            color: AppColors.textTertiary, fontSize: 10, fontFamily: 'Nunito'),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: chartData.length > 10
                          ? (chartData.length / 5).ceilToDouble()
                          : 1,
                      getTitlesWidget: (value, _) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= chartData.length) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            DateFormat('d MMM').format(chartData[idx].date),
                            style: const TextStyle(
                                color: AppColors.textTertiary, fontSize: 9, fontFamily: 'Nunito'),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: chartData.asMap().entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value.value))
                        .toList(),
                    isCurved: true,
                    gradient: const LinearGradient(
                      colors: [AppColors.gradientStart, AppColors.gradientEnd],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: chartData.length <= 20,
                      getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                        radius: 4,
                        color: AppColors.brandPrimary,
                        strokeColor: Colors.white,
                        strokeWidth: 1.5,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.brandPrimary.withOpacity(0.2),
                          AppColors.brandPrimary.withOpacity(0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'Nunito')),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12, fontFamily: 'Nunito')),
        ],
      ),
    );
  }
}

class _ExportOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ExportOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0x1AFF6B35),
              Color(0x0DFF9F1C),
              AppColors.darkCardBackground,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.brandPrimary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppGradients.brand,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textTertiary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatEntryCard extends StatelessWidget {
  final BodyStats stat;
  final ProgressMetric metric;

  const _StatEntryCard({required this.stat, required this.metric});

  @override
  Widget build(BuildContext context) {
    final value = _getMetricValue(stat, metric);
    final formattedValue = value != null 
        ? '${value.toStringAsFixed(1)} ${metric.unit}' 
        : '--';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppGradients.brand,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.straighten, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('MMM d, yyyy').format(stat.date),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Nunito',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getStatsPreview(stat),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontFamily: 'Nunito',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            formattedValue,
            style: const TextStyle(
              color: AppColors.brandPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'Nunito',
            ),
          ),
        ],
      ),
    );
  }

  double? _getMetricValue(BodyStats s, ProgressMetric m) {
    switch (m) {
      case ProgressMetric.weight:    return s.weight;
      case ProgressMetric.bmi:       return s.bmi;
      case ProgressMetric.waist:     return s.waistCircumference;
      case ProgressMetric.neck:      return s.neckCircumference;
      case ProgressMetric.hip:       return s.hipCircumference;
      case ProgressMetric.chest:     return s.chestCircumference;
      case ProgressMetric.arm:       return s.armCircumference;
      case ProgressMetric.thigh:     return s.thighCircumference;
      case ProgressMetric.bodyFat:   return s.bodyFatPercentage;
      case ProgressMetric.muscleMass:return s.muscleMass;
    }
  }

  String _getStatsPreview(BodyStats stat) {
    final parts = <String>[];
    if (stat.weight != null) parts.add('Weight: ${stat.weight!.toStringAsFixed(1)}kg');
    if (stat.waistCircumference != null) parts.add('Waist: ${stat.waistCircumference!.toStringAsFixed(1)}cm');
    if (stat.bodyFatPercentage != null) parts.add('BF: ${stat.bodyFatPercentage!.toStringAsFixed(1)}%');
    return parts.isEmpty ? 'No measurements' : parts.join(' • ');
  }
}
