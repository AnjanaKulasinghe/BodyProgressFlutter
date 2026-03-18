import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:body_progress/models/body_stats.dart';
import 'package:body_progress/models/user_profile.dart';
import 'package:body_progress/services/firestore_service.dart';
import 'package:body_progress/services/health_service.dart';
import 'package:body_progress/providers/auth_provider.dart';
import 'package:body_progress/providers/progress_provider.dart';
import 'package:body_progress/providers/achievement_provider.dart';

class StatsState {
  final List<BodyStats> bodyStats;
  final bool isLoading;
  final String? errorMessage;
  final bool showingAlert;
  final bool isHealthSyncEnabled;
  // Form fields
  final String weight;
  final String waistCircumference;
  final String neckCircumference;
  final String hipCircumference;
  final String chestCircumference;
  final String armCircumference;
  final String thighCircumference;
  final String bodyFatPercentage;
  final String muscleMass;
  final String notes;
  final DateTime selectedDate;
  final DataSource dataSource;

  StatsState({
    this.bodyStats = const [],
    this.isLoading = false,
    this.errorMessage,
    this.showingAlert = false,
    this.isHealthSyncEnabled = false,
    this.weight = '',
    this.waistCircumference = '',
    this.neckCircumference = '',
    this.hipCircumference = '',
    this.chestCircumference = '',
    this.armCircumference = '',
    this.thighCircumference = '',
    this.bodyFatPercentage = '',
    this.muscleMass = '',
    this.notes = '',
    DateTime? selectedDate,
    this.dataSource = DataSource.manual,
  }) : selectedDate = selectedDate ?? DateTime.now();

  StatsState copyWith({
    List<BodyStats>? bodyStats,
    bool? isLoading,
    String? errorMessage,
    bool? showingAlert,
    bool? isHealthSyncEnabled,
    String? weight,
    String? waistCircumference,
    String? neckCircumference,
    String? hipCircumference,
    String? chestCircumference,
    String? armCircumference,
    String? thighCircumference,
    String? bodyFatPercentage,
    String? muscleMass,
    String? notes,
    DateTime? selectedDate,
    DataSource? dataSource,
    bool clearError = false,
    bool clearForm = false,
  }) => StatsState(
    bodyStats: bodyStats ?? this.bodyStats,
    isLoading: isLoading ?? this.isLoading,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    showingAlert: clearError ? false : (showingAlert ?? this.showingAlert),
    isHealthSyncEnabled: isHealthSyncEnabled ?? this.isHealthSyncEnabled,
    weight: clearForm ? '' : (weight ?? this.weight),
    waistCircumference: clearForm ? '' : (waistCircumference ?? this.waistCircumference),
    neckCircumference: clearForm ? '' : (neckCircumference ?? this.neckCircumference),
    hipCircumference: clearForm ? '' : (hipCircumference ?? this.hipCircumference),
    chestCircumference: clearForm ? '' : (chestCircumference ?? this.chestCircumference),
    armCircumference: clearForm ? '' : (armCircumference ?? this.armCircumference),
    thighCircumference: clearForm ? '' : (thighCircumference ?? this.thighCircumference),
    bodyFatPercentage: clearForm ? '' : (bodyFatPercentage ?? this.bodyFatPercentage),
    muscleMass: clearForm ? '' : (muscleMass ?? this.muscleMass),
    notes: clearForm ? '' : (notes ?? this.notes),
    selectedDate: clearForm ? DateTime.now() : (selectedDate ?? this.selectedDate),
    dataSource: clearForm ? DataSource.manual : (dataSource ?? this.dataSource),
  );
}

class StatsNotifier extends StateNotifier<StatsState> {
  final FirestoreService _firestoreService = FirestoreService();
  final HealthService _healthService = HealthService();
  final Ref _ref;

  StatsNotifier(this._ref) : super(StatsState(selectedDate: DateTime.now()));

  String? get _uid => _ref.read(authProvider).user?.uid;

  // ── Form updates ──────────────────────────────────────────────────────────
  void setWeight(String v)             => state = state.copyWith(weight: v);
  void setWaist(String v)              => state = state.copyWith(waistCircumference: v);
  void setNeck(String v)               => state = state.copyWith(neckCircumference: v);
  void setHip(String v)                => state = state.copyWith(hipCircumference: v);
  void setChest(String v)              => state = state.copyWith(chestCircumference: v);
  void setArm(String v)                => state = state.copyWith(armCircumference: v);
  void setThigh(String v)              => state = state.copyWith(thighCircumference: v);
  void setBodyFat(String v)            => state = state.copyWith(bodyFatPercentage: v);
  void setMuscleMass(String v)         => state = state.copyWith(muscleMass: v);
  void setNotes(String v)              => state = state.copyWith(notes: v);
  void setSelectedDate(DateTime v)     => state = state.copyWith(selectedDate: v);
  void setDataSource(DataSource v)     => state = state.copyWith(dataSource: v);
  void clearError()                    => state = state.copyWith(clearError: true);

  void populateForm(BodyStats stats) {
    state = state.copyWith(
      weight: stats.weight.toStringAsFixed(1),
      waistCircumference: stats.waistCircumference?.toStringAsFixed(1) ?? '',
      neckCircumference: stats.neckCircumference?.toStringAsFixed(1) ?? '',
      hipCircumference: stats.hipCircumference?.toStringAsFixed(1) ?? '',
      chestCircumference: stats.chestCircumference?.toStringAsFixed(1) ?? '',
      armCircumference: stats.armCircumference?.toStringAsFixed(1) ?? '',
      thighCircumference: stats.thighCircumference?.toStringAsFixed(1) ?? '',
      bodyFatPercentage: stats.bodyFatPercentage?.toStringAsFixed(1) ?? '',
      muscleMass: stats.muscleMass?.toStringAsFixed(1) ?? '',
      notes: stats.notes ?? '',
      selectedDate: stats.date,
      dataSource: stats.source,
    );
  }

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> loadFromCache() async {
    final cached = _ref.read(progressProvider).cachedBodyStats;
    state = state.copyWith(bodyStats: cached);
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<bool> saveBodyStats({UserProfile? profile}) async {
    final error = _validate();
    if (error != null) {
      state = state.copyWith(errorMessage: error, showingAlert: true);
      return false;
    }
    final uid = _uid;
    if (uid == null) return false;

    state = state.copyWith(isLoading: true);
    try {
      final weightVal = double.parse(state.weight);
      final heightCm = profile?.height;
      double? bmi;
      if (heightCm != null && heightCm > 0) {
        bmi = weightVal / ((heightCm / 100) * (heightCm / 100));
      }

      final stats = BodyStats(
        userId: uid,
        date: state.selectedDate,
        weight: weightVal,
        waistCircumference: double.tryParse(state.waistCircumference),
        neckCircumference: double.tryParse(state.neckCircumference),
        hipCircumference: double.tryParse(state.hipCircumference),
        chestCircumference: double.tryParse(state.chestCircumference),
        armCircumference: double.tryParse(state.armCircumference),
        thighCircumference: double.tryParse(state.thighCircumference),
        bodyFatPercentage: double.tryParse(state.bodyFatPercentage),
        muscleMass: double.tryParse(state.muscleMass),
        notes: state.notes.isEmpty ? null : state.notes,
        source: state.dataSource,
        createdAt: DateTime.now(),
        bmi: bmi,
      );

      await _firestoreService.saveBodyStats(stats);

      // Write to Health if enabled
      if (state.isHealthSyncEnabled && stats.source == DataSource.manual) {
        await _healthService.saveBodyStatsToHealth(stats);
      }

      // Update progress cache
      _ref.read(progressProvider.notifier).addCachedBodyStat(stats);

      state = state.copyWith(
        isLoading: false,
        bodyStats: [stats, ...state.bodyStats],
        clearForm: true,
        clearError: true,
      );
      
      // Check for achievements after saving stats
      _ref.read(achievementProvider.notifier).checkForNewAchievements();
      
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString(), showingAlert: true);
      return false;
    }
  }

  Future<bool> updateBodyStats(BodyStats stats) async {
    state = state.copyWith(isLoading: true);
    try {
      await _firestoreService.updateBodyStats(stats);
      _ref.read(progressProvider.notifier).updateCachedBodyStat(stats);
      final updated = [...state.bodyStats];
      final idx = updated.indexWhere((s) => s.id == stats.id);
      if (idx != -1) updated[idx] = stats;
      state = state.copyWith(isLoading: false, bodyStats: updated, clearError: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString(), showingAlert: true);
      return false;
    }
  }

  Future<bool> deleteBodyStats(BodyStats stats) async {
    if (stats.id == null) return false;
    state = state.copyWith(isLoading: true);
    try {
      await _firestoreService.deleteBodyStats(stats.id!);
      _ref.read(progressProvider.notifier).deleteCachedBodyStat(stats.id!);
      state = state.copyWith(
        isLoading: false,
        bodyStats: state.bodyStats.where((s) => s.id != stats.id).toList(),
        clearError: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString(), showingAlert: true);
      return false;
    }
  }

  // ── Validation ────────────────────────────────────────────────────────────

  String? _validate() {
    if (state.weight.isEmpty) return 'Please enter your weight';
    final w = double.tryParse(state.weight);
    if (w == null || w <= 0 || w > 300) return 'Weight must be between 1 and 300 kg';
    if (state.waistCircumference.isNotEmpty) {
      final v = double.tryParse(state.waistCircumference);
      if (v == null || v <= 0 || v > 200) return 'Waist must be between 1 and 200 cm';
    }
    if (state.bodyFatPercentage.isNotEmpty) {
      final v = double.tryParse(state.bodyFatPercentage);
      if (v == null || v < 0 || v > 50) return 'Body fat must be between 0 and 50%';
    }
    return null;
  }

  // ── Computed ──────────────────────────────────────────────────────────────

  BodyStats? get latestStats => state.bodyStats.isNotEmpty ? state.bodyStats.first : null;
  bool get hasStats => state.bodyStats.isNotEmpty;
}

final statsProvider = StateNotifierProvider<StatsNotifier, StatsState>(
    (ref) => StatsNotifier(ref));
