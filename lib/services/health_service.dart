// Temporarily stubbed out due to Android compatibility issues with health plugin
import 'package:body_progress/models/body_stats.dart';

/// Cross-platform health data service (STUBBED VERSION).
/// • iOS: reads from Apple HealthKit
/// • Android: reads from Google Health Connect
///
/// NOTE: Currently stubbed out due to plugin compatibility issues.
/// All methods return null/empty/false to allow app to run without health integration.
class HealthService {
  bool _isAuthorized = false;

  bool get isAuthorized => _isAuthorized;

  Future<bool> requestAuthorization() async {
    _isAuthorized = false;
    return _isAuthorized;
  }

  Future<double?> getLatestWeight() async => null;
  Future<double?> getLatestHeight() async => null;
  Future<double?> getLatestBodyFat() async => null;

  Future<void> saveBodyStatsToHealth(BodyStats stats) async {
    // Stubbed: do nothing
  }

  Future<HealthSyncResult> syncLastYears(int years, String userId) async {
    return HealthSyncResult(
      uploadedCount: 0,
      errorMessage: 'Health integration temporarily disabled',
    );
  }

  Future<HealthSyncResult> syncHealthData({
    required String userId,
    required DateTime from,
    required DateTime to,
  }) async {
    return HealthSyncResult(
      uploadedCount: 0,
      errorMessage: 'Health integration temporarily disabled',
    );
  }
}

class HealthSyncResult {
  final int uploadedCount;
  final double? latestWeight;
  final String? errorMessage;

  const HealthSyncResult({
    required this.uploadedCount,
    this.latestWeight,
    this.errorMessage,
  });
}
