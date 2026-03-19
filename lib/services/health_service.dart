import 'dart:io' show Platform;
import 'dart:async';
import 'package:health/health.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:body_progress/models/body_stats.dart';
import 'package:body_progress/services/firestore_service.dart';

/// Cross-platform health data service.
/// • iOS: reads from Apple HealthKit
/// • Android: reads from Google Health Connect
class HealthService {
  final Health _health = Health();
  bool _isAuthorized = false;
  bool _hasCheckedPermissions = false;

  bool get isAuthorized => _isAuthorized;

  /// Get the appropriate DataSource based on platform
  DataSource get platformHealthSource {
    if (Platform.isIOS) {
      return DataSource.healthKit;
    } else if (Platform.isAndroid) {
      return DataSource.healthConnect;
    }
    return DataSource.manual;
  }

  // Types we want to access from HealthKit/Health Connect with their permissions
  static final List<HealthDataType> _dataTypes = [
    HealthDataType.WEIGHT,
    HealthDataType.HEIGHT,
    HealthDataType.BODY_FAT_PERCENTAGE,
    HealthDataType.WAIST_CIRCUMFERENCE,
  ];

  static final List<HealthDataAccess> _permissions = [
    HealthDataAccess.READ_WRITE, // WEIGHT - read and write
    HealthDataAccess.READ,       // HEIGHT - read only
    HealthDataAccess.READ_WRITE, // BODY_FAT_PERCENTAGE - read and write
    HealthDataAccess.READ_WRITE, // WAIST_CIRCUMFERENCE - read and write
  ];

  /// Check if we already have permissions (fast check, no UI)
  Future<bool> hasPermissions() async {
    if (_hasCheckedPermissions) {
      return _isAuthorized;
    }
    
    try {
      _isAuthorized = await _health.hasPermissions(_dataTypes) ?? false;
      _hasCheckedPermissions = true;
      return _isAuthorized;
    } catch (e) {
      print('Error checking health permissions: $e');
      _hasCheckedPermissions = true;
      _isAuthorized = false;
      return false;
    }
  }

  Future<bool> requestAuthorization() async {
    try {
      _isAuthorized = await _health.requestAuthorization(
        _dataTypes,
        permissions: _permissions,
      );
      _hasCheckedPermissions = true;
      return _isAuthorized;
    } catch (e) {
      print('Error requesting health authorization: $e');
      _isAuthorized = false;
      _hasCheckedPermissions = true;
      return false;
    }
  }

  Future<double?> getLatestWeight() async {
    if (!_isAuthorized) {
      await hasPermissions();
    }
    if (!_isAuthorized) return null;

    try {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      
      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.WEIGHT],
        startTime: yesterday,
        endTime: now,
      );
      
      if (data.isEmpty) return null;
      
      // Get most recent weight
      data.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
      final value = data.first.value;
      
      if (value is NumericHealthValue) {
        final num? numericVal = value.numericValue;
        return numericVal?.toDouble();
      }
      return null;
    } catch (e) {
      print('Error getting weight: $e');
      return null;
    }
  }

  Future<double?> getLatestHeight() async {
    if (!_isAuthorized) {
      await hasPermissions();
    }
    if (!_isAuthorized) return null;

    try {
      final now = DateTime.now();
      final lastWeek = now.subtract(const Duration(days: 7));
      
      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEIGHT],
        startTime: lastWeek,
        endTime: now,
      );
      
      if (data.isEmpty) return null;
      
      data.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
      final value = data.first.value;
      
      if (value is NumericHealthValue) {
        return value.numericValue.toDouble();
      }
      return null;
    } catch (e) {
      print('Error getting height: $e');
      return null;
    }
  }

  Future<double?> getLatestBodyFat() async {
    if (!_isAuthorized) {
      await hasPermissions();
    }
    if (!_isAuthorized) return null;

    try {
      final now = DateTime.now();
      final lastWeek = now.subtract(const Duration(days: 7));
      
      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.BODY_FAT_PERCENTAGE],
        startTime: lastWeek,
        endTime: now,
      );
      
      if (data.isEmpty) return null;
      
      data.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
      final value = data.first.value;
      
      if (value is NumericHealthValue) {
        return value.numericValue.toDouble();
      }
      return null;
    } catch (e) {
      print('Error getting body fat: $e');
      return null;
    }
  }

  Future<void> saveBodyStatsToHealth(BodyStats stats) async {
    if (!_isAuthorized) {
      await hasPermissions();
    }
    if (!_isAuthorized) return;

    try {
      // Save weight
      await _health.writeHealthData(
        value: stats.weight,
        type: HealthDataType.WEIGHT,
        startTime: stats.date,
        endTime: stats.date,
      );

      // Save body fat if available
      if (stats.bodyFatPercentage != null) {
        await _health.writeHealthData(
          value: stats.bodyFatPercentage!,
          type: HealthDataType.BODY_FAT_PERCENTAGE,
          startTime: stats.date,
          endTime: stats.date,
        );
      }

      // Save waist circumference if available
      if (stats.waistCircumference != null) {
        await _health.writeHealthData(
          value: stats.waistCircumference!,
          type: HealthDataType.WAIST_CIRCUMFERENCE,
          startTime: stats.date,
          endTime: stats.date,
        );
      }
    } catch (e) {
      print('Error saving to HealthKit: $e');
    }
  }

  Future<HealthSyncResult> syncLastYears(int years, String userId) async {
    final now = DateTime.now();
    final startDate = DateTime(now.year - years, now.month, now.day);
    return syncHealthData(userId: userId, from: startDate, to: now);
  }

  Future<HealthSyncResult> syncHealthData({
    required String userId,
    required DateTime from,
    required DateTime to,
  }) async {
    if (!_isAuthorized) {
      return const HealthSyncResult(
        uploadedCount: 0,
        errorMessage: 'Health data access not authorized',
      );
    }

    try {
      final data = await _health.getHealthDataFromTypes(
        types: _dataTypes,
        startTime: from,
        endTime: to,
      );

      if (data.isEmpty) {
        return const HealthSyncResult(
          uploadedCount: 0,
          errorMessage: 'No health data found in the selected period',
        );
      }

      // Group by date
      final Map<DateTime, BodyStats> statsByDate = {};
      
      for (var point in data) {
        final date = DateTime(
          point.dateFrom.year,
          point.dateFrom.month,
          point.dateFrom.day,
        );
        
        final existing = statsByDate[date] ?? BodyStats(
          userId: userId,
          date: date,
          weight: 0.0,
          source: platformHealthSource,
          createdAt: DateTime.now(),
        );

        final value = point.value;
        if (value is NumericHealthValue) {
          final num? numericVal = value.numericValue;
          if (numericVal == null) continue;
          final numValue = numericVal.toDouble();
          
          switch (point.type) {
            case HealthDataType.WEIGHT:
              statsByDate[date] = existing.copyWith(weight: numValue);
              break;
            case HealthDataType.BODY_FAT_PERCENTAGE:
              statsByDate[date] = existing.copyWith(bodyFatPercentage: numValue);
              break;
            case HealthDataType.WAIST_CIRCUMFERENCE:
              statsByDate[date] = existing.copyWith(waistCircumference: numValue);
              break;
            default:
              break;
          }
        }
      }

      
      // Filter records with valid weight
      final validStats = statsByDate.values.where((s) => s.weight > 0).toList();
      
      if (validStats.isEmpty) {
        return const HealthSyncResult(
          uploadedCount: 0,
          errorMessage: 'No valid weight data found',
        );
      }
      
      // Upload to Firestore using batch writes
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return const HealthSyncResult(
          uploadedCount: 0,
          errorMessage: 'User not authenticated',
        );
      }
      
      final firestoreService = FirestoreService();
      
      try {
        await firestoreService.batchSaveBodyStats(validStats);
      } catch (e) {
        return HealthSyncResult(
          uploadedCount: 0,
          errorMessage: 'Failed to upload: ${e.toString()}',
        );
      }
      
      final latestWeight = validStats.last.weight;
      return HealthSyncResult(
        uploadedCount: validStats.length,
        latestWeight: latestWeight,
        errorMessage: null,
      );
    } catch (e) {
      print('Error syncing health data: $e');
      return HealthSyncResult(
        uploadedCount: 0,
        errorMessage: 'Sync failed: ${e.toString()}',
      );
    }
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
