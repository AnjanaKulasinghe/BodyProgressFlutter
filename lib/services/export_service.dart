import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:body_progress/models/body_stats.dart';
import 'package:body_progress/models/photo_metadata.dart';

class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  /// Export body stats to CSV and share
  Future<void> exportBodyStats(List<BodyStats> stats) async {
    if (stats.isEmpty) {
      throw Exception('No stats to export');
    }

    try {
      // Create CSV data
      List<List<dynamic>> rows = [];
      
      // Add header
      rows.add([
        'Date',
        'Weight (kg)',
        'BMI',
        'Body Fat %',
        'Muscle Mass (kg)',
        'Waist (cm)',
        'Neck (cm)',
        'Hip (cm)',
        'Chest (cm)',
        'Arm (cm)',
        'Thigh (cm)',
        'Notes',
        'Source',
      ]);

      // Add data rows
      for (final stat in stats) {
        rows.add([
          DateFormat('yyyy-MM-dd').format(stat.date),
          stat.weight.toStringAsFixed(1),
          stat.bmi?.toStringAsFixed(1) ?? '-',
          stat.bodyFatPercentage?.toStringAsFixed(1) ?? '-',
          stat.muscleMass?.toStringAsFixed(1) ?? '-',
          stat.waistCircumference?.toStringAsFixed(1) ?? '-',
          stat.neckCircumference?.toStringAsFixed(1) ?? '-',
          stat.hipCircumference?.toStringAsFixed(1) ?? '-',
          stat.chestCircumference?.toStringAsFixed(1) ?? '-',
          stat.armCircumference?.toStringAsFixed(1) ?? '-',
          stat.thighCircumference?.toStringAsFixed(1) ?? '-',
          stat.notes ?? '',
          stat.source ?? 'Manual',
        ]);
      }

      // Convert to CSV
      String csv = const ListToCsvConverter().convert(rows);

      // Save to temporary file
      final directory = await getTemporaryDirectory();
      final fileName = 'body_progress_stats_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsString(csv);

      // Share the file
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Body Progress Stats Export',
        text: 'My body progress statistics from BodyProgress app',
      );
    } catch (e) {
      throw Exception('Failed to export stats: $e');
    }
  }

  /// Export body stats with photo metadata to detailed CSV
  Future<void> exportFullReport({
    required List<BodyStats> stats,
    required List<PhotoMetadata> photos,
  }) async {
    if (stats.isEmpty && photos.isEmpty) {
      throw Exception('No data to export');
    }

    try {
      List<List<dynamic>> rows = [];
      
      // Stats section
      if (stats.isNotEmpty) {
        rows.add(['BODY STATS']);
        rows.add([]);
        rows.add([
          'Date',
          'Weight (kg)',
          'BMI',
          'Body Fat %',
          'Muscle Mass (kg)',
          'Waist (cm)',
          'Neck (cm)',
          'Hip (cm)',
          'Chest (cm)',
          'Arm (cm)',
          'Thigh (cm)',
          'Notes',
        ]);

        for (final stat in stats) {
          rows.add([
            DateFormat('yyyy-MM-dd HH:mm').format(stat.date),
            stat.weight.toStringAsFixed(1),
            stat.bmi?.toStringAsFixed(1) ?? '-',
            stat.bodyFatPercentage?.toStringAsFixed(1) ?? '-',
            stat.muscleMass?.toStringAsFixed(1) ?? '-',
            stat.waistCircumference?.toStringAsFixed(1) ?? '-',
            stat.neckCircumference?.toStringAsFixed(1) ?? '-',
            stat.hipCircumference?.toStringAsFixed(1) ?? '-',
            stat.chestCircumference?.toStringAsFixed(1) ?? '-',
            stat.armCircumference?.toStringAsFixed(1) ?? '-',
            stat.thighCircumference?.toStringAsFixed(1) ?? '-',
            stat.notes ?? '',
          ]);
        }
        
        rows.add([]);
        rows.add([]);
      }

      // Photos section
      if (photos.isNotEmpty) {
        rows.add(['PROGRESS PHOTOS']);
        rows.add([]);
        rows.add([
          'Date',
          'Photo Type',
          'Weight (kg)',
          'Notes',
          'File Name',
        ]);

        for (final photo in photos) {
          rows.add([
            DateFormat('yyyy-MM-dd HH:mm').format(photo.date),
            photo.photoType,
            photo.weight?.toStringAsFixed(1) ?? '-',
            photo.notes ?? '',
            photo.fileName,
          ]);
        }
      }

      // Add summary section
      rows.add([]);
      rows.add([]);
      rows.add(['SUMMARY']);
      rows.add([]);
      rows.add(['Total Stats Entries', stats.length]);
      rows.add(['Total Photos', photos.length]);
      
      if (stats.isNotEmpty) {
        final firstStat = stats.last; // oldest
        final lastStat = stats.first; // newest
        final weightChange = lastStat.weight - firstStat.weight;
        rows.add(['Starting Weight', '${firstStat.weight.toStringAsFixed(1)} kg']);
        rows.add(['Current Weight', '${lastStat.weight.toStringAsFixed(1)} kg']);
        rows.add(['Total Change', '${weightChange >= 0 ? "+" : ""}${weightChange.toStringAsFixed(1)} kg']);
        
        if (firstStat.date != lastStat.date) {
          final days = lastStat.date.difference(firstStat.date).inDays;
          rows.add(['Time Period', '$days days']);
        }
      }
      
      rows.add(['Export Date', DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())]);

      // Convert to CSV
      String csv = const ListToCsvConverter().convert(rows);

      // Save to temporary file
      final directory = await getTemporaryDirectory();
      final fileName = 'body_progress_full_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsString(csv);

      // Share the file
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Body Progress Full Report',
        text: 'My complete body progress report from BodyProgress app',
      );
    } catch (e) {
      throw Exception('Failed to export full report: $e');
    }
  }

  /// Export just weight data (simplified)
  Future<void> exportWeightData(List<BodyStats> stats) async {
    if (stats.isEmpty) {
      throw Exception('No weight data to export');
    }

    try {
      List<List<dynamic>> rows = [];
      
      rows.add(['Date', 'Weight (kg)', 'BMI']);

      for (final stat in stats) {
        rows.add([
          DateFormat('yyyy-MM-dd').format(stat.date),
          stat.weight.toStringAsFixed(1),
          stat.bmi?.toStringAsFixed(1) ?? '-',
        ]);
      }

      String csv = const ListToCsvConverter().convert(rows);

      final directory = await getTemporaryDirectory();
      final fileName = 'weight_data_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsString(csv);

      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Weight Data Export',
      );
    } catch (e) {
      throw Exception('Failed to export weight data: $e');
    }
  }
}
