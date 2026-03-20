import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:body_progress/models/body_stats.dart';
import 'package:body_progress/models/user_profile.dart';
import 'package:body_progress/services/firestore_service.dart';
import 'package:body_progress/services/health_service.dart';
import 'package:body_progress/providers/auth_provider.dart';

// ── Chart helpers ──────────────────────────────────────────────────────────

class ChartDataPoint {
  final DateTime date;
  final double value;
  const ChartDataPoint({required this.date, required this.value});
}

enum TimeRange {
  week('7d', '7 Days', 7),
  month('30d', '30 Days', 30),
  threeMonths('3m', '3 Months', 90),
  sixMonths('6m', '6 Months', 180),
  year('1y', '1 Year', 365),
  allTime('all', 'All Time', null);

  const TimeRange(this.value, this.displayName, this.days);
  final String value;
  final String displayName;
  final int? days;
}

enum ProgressMetric {
  weight('weight', 'Weight', 'kg'),
  bmi('bmi', 'BMI', ''),
  waist('waist', 'Waist', 'cm'),
  neck('neck', 'Neck', 'cm'),
  hip('hip', 'Hip', 'cm'),
  chest('chest', 'Chest', 'cm'),
  arm('arm', 'Arm', 'cm'),
  thigh('thigh', 'Thigh', 'cm'),
  bodyFat('bodyFat', 'Body Fat %', '%'),
  muscleMass('muscleMass', 'Muscle Mass', 'kg');

  const ProgressMetric(this.value, this.displayName, this.unit);
  final String value;
  final String displayName;
  final String unit;
}

enum TrendDirection { increasing, decreasing, stable }

// ── Progress State ─────────────────────────────────────────────────────────

class ProgressState {
  final List<BodyStats> cachedBodyStats;
  final List<BodyStats> bodyStats;
  final bool isLoading;
  final bool isCacheLoaded;
  final String? errorMessage;
  final TimeRange selectedTimeRange;
  final ProgressMetric selectedMetric;
  final UserProfile? profile;

  const ProgressState({
    this.cachedBodyStats = const [],
    this.bodyStats = const [],
    this.isLoading = false,
    this.isCacheLoaded = false,
    this.errorMessage,
    this.selectedTimeRange = TimeRange.month,
    this.selectedMetric = ProgressMetric.weight,
    this.profile,
  });

  ProgressState copyWith({
    List<BodyStats>? cachedBodyStats,
    List<BodyStats>? bodyStats,
    bool? isLoading,
    bool? isCacheLoaded,
    String? errorMessage,
    TimeRange? selectedTimeRange,
    ProgressMetric? selectedMetric,
    UserProfile? profile,
  }) => ProgressState(
    cachedBodyStats: cachedBodyStats ?? this.cachedBodyStats,
    bodyStats: bodyStats ?? this.bodyStats,
    isLoading: isLoading ?? this.isLoading,
    isCacheLoaded: isCacheLoaded ?? this.isCacheLoaded,
    errorMessage: errorMessage ?? this.errorMessage,
    selectedTimeRange: selectedTimeRange ?? this.selectedTimeRange,
    selectedMetric: selectedMetric ?? this.selectedMetric,
    profile: profile ?? this.profile,
  );
}

// ── Progress Notifier ──────────────────────────────────────────────────────

class ProgressNotifier extends StateNotifier<ProgressState> {
  final FirestoreService _firestoreService = FirestoreService();
  final HealthService _healthService = HealthService();
  final Ref _ref;

  ProgressNotifier(this._ref) : super(const ProgressState());

  String? get _uid => _ref.read(authProvider).user?.uid;
  
  // Expose health service for permission checks
  HealthService get healthService => _healthService;

  // ── Cache Management ──────────────────────────────────────────────────────

  Future<Duration> loadAndCacheBodyStats() async {
    print('🟠 [ProgressProvider] >>> loadAndCacheBodyStats - START <<<');
    final uid = _uid;
    if (uid == null) {
      print('🟠 [ProgressProvider] uid is null, returning Duration.zero');
      return Duration.zero;
    }
    final start = DateTime.now();
    
    print('🟠 [ProgressProvider] Loading body stats for uid: $uid');
    print('🟠 [ProgressProvider] About to call getBodyStats with 15s timeout...');
    
    // Use smaller limit on cold start to prevent hanging
    final stats = await _firestoreService.getBodyStats(uid, limit: 500).timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        debugPrint('[ProgressProvider] getBodyStats timeout after 15s, returning empty list');
        return <BodyStats>[];
      },
    );
    
    debugPrint('[ProgressProvider] Loaded ${stats.length} body stats in ${DateTime.now().difference(start).inMilliseconds}ms');
    
    // Explicitly sort descending (newest first) for display
    stats.sort((a, b) => b.date.compareTo(a.date));
    state = state.copyWith(
      cachedBodyStats: stats,
      isCacheLoaded: true,
    );
    _applyFilter();
    return DateTime.now().difference(start);
  }

  void addCachedBodyStat(BodyStats stat) {
    final updated = [stat, ...state.cachedBodyStats];
    // Ensure descending order (newest first)
    updated.sort((a, b) => b.date.compareTo(a.date));
    state = state.copyWith(cachedBodyStats: updated);
    _applyFilter();
  }

  void updateCachedBodyStat(BodyStats stat) {
    final idx = state.cachedBodyStats.indexWhere((s) => s.id == stat.id);
    if (idx == -1) return;
    final updated = [...state.cachedBodyStats];
    updated[idx] = stat;
    // Re-sort descending (newest first) in case date was changed
    updated.sort((a, b) => b.date.compareTo(a.date));
    state = state.copyWith(cachedBodyStats: updated);
    _applyFilter();
  }

  void deleteCachedBodyStat(String id) {
    state = state.copyWith(
        cachedBodyStats: state.cachedBodyStats.where((s) => s.id != id).toList());
    _applyFilter();
  }

  // ── Filter / Chart Data ───────────────────────────────────────────────────

  void _applyFilter() {
    final days = state.selectedTimeRange.days;
    final cutoff = days != null
        ? DateTime.now().subtract(Duration(days: days))
        : null;
    final filtered = cutoff == null
        ? state.cachedBodyStats
        : state.cachedBodyStats.where((s) => s.date.isAfter(cutoff)).toList();
    // Keep filtered data in descending order (newest first) for both charts and lists
    state = state.copyWith(bodyStats: filtered..sort((a, b) => b.date.compareTo(a.date)));
  }

  void setTimeRange(TimeRange r) {
    state = state.copyWith(selectedTimeRange: r);
    _applyFilter();
  }

  void setMetric(ProgressMetric m) => state = state.copyWith(selectedMetric: m);

  void setProfile(UserProfile p) => state = state.copyWith(profile: p);

  // ── Chart Data ────────────────────────────────────────────────────────────

  List<ChartDataPoint> get chartData {
    // Sort ascending for chart display (left to right = old to new)
    final sortedForChart = [...state.bodyStats]
      ..sort((a, b) => a.date.compareTo(b.date));
    return sortedForChart.map((s) {
      final v = _getValue(s, state.selectedMetric);
      return v != null ? ChartDataPoint(date: s.date, value: v) : null;
    }).whereType<ChartDataPoint>().toList();
  }

  double? _getValue(BodyStats s, ProgressMetric m) {
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

  // ── Statistics ────────────────────────────────────────────────────────────

  // ChartData is sorted ascending (oldest to newest) for chart display
  double? get currentValue => chartData.isNotEmpty ? chartData.last.value : null;
  double? get startValue   => chartData.isNotEmpty ? chartData.first.value : null;
  double? get totalChange  => (currentValue != null && startValue != null)
      ? currentValue! - startValue! : null;
  double? get percentageChange => (totalChange != null && startValue != null && startValue! != 0)
      ? (totalChange! / startValue!) * 100 : null;
  double? get averageValue {
    if (chartData.isEmpty) return null;
    return chartData.map((p) => p.value).reduce((a, b) => a + b) / chartData.length;
  }
  double? get minValue => chartData.isEmpty ? null : chartData.map((p) => p.value).reduce((a, b) => a < b ? a : b);
  double? get maxValue => chartData.isEmpty ? null : chartData.map((p) => p.value).reduce((a, b) => a > b ? a : b);

  TrendDirection get trendDirection {
    final change = totalChange;
    if (change == null) return TrendDirection.stable;
    final threshold = state.selectedMetric == ProgressMetric.bmi ? 0.1 : 0.5;
    if (change > threshold)  return TrendDirection.increasing;
    if (change < -threshold) return TrendDirection.decreasing;
    return TrendDirection.stable;
  }

  // ── Health Sync ───────────────────────────────────────────────────────────

  Future<HealthSyncResult> syncWithHealth({int years = 5}) async {
    final uid = _uid;
    if (uid == null) {
      return const HealthSyncResult(uploadedCount: 0, errorMessage: 'Not authenticated');
    }
    
    state = state.copyWith(isLoading: true);
    final result = await _healthService.syncLastYears(years, uid);
    await loadAndCacheBodyStats();
    state = state.copyWith(isLoading: false);
    
    return result;
  }

  /// Reset provider to initial state (called on sign out)
  void reset() {
    state = const ProgressState();
  }
}

final progressProvider = StateNotifierProvider<ProgressNotifier, ProgressState>(
    (ref) => ProgressNotifier(ref));
