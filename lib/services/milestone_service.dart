import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:body_progress/models/achievement.dart';
import 'package:body_progress/models/body_stats.dart';
import 'package:body_progress/models/user_profile.dart';
import 'package:body_progress/models/photo_metadata.dart';

/// Service for tracking and checking milestone achievements
class MilestoneService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _achievements => _firestore.collection('achievements');

  // ── Save Achievement ──────────────────────────────────────────────────────

  Future<void> saveAchievement(Achievement achievement) async {
    await _achievements.add(achievement.toFirestore());
  }

  Future<List<Achievement>> getUserAchievements(String userId) async {
    final query = await _achievements
        .where('userId', isEqualTo: userId)
        .get();
    return query.docs.map((doc) => Achievement.fromFirestore(doc)).toList();
  }

  Future<Set<String>> getEarnedAchievementIds(String userId) async {
    final achievements = await getUserAchievements(userId);
    return achievements.map((a) => a.type.id).toSet();
  }

  // ── Delete All Achievements (for cleanup) ─────────────────────────────────

  Future<void> deleteAllAchievements(String userId) async {
    final query = await _achievements.where('userId', isEqualTo: userId).get();
    final batch = _firestore.batch();
    for (final doc in query.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // ── Recalculate All Achievements (cleanup and recalculate) ────────────────

  Future<List<Achievement>> recalculateAchievements({
    required String userId,
    required UserProfile? profile,
    required List<BodyStats> allStats,
    required List<PhotoMetadata> allPhotos,
  }) async {
    // Delete all existing achievements first
    await deleteAllAchievements(userId);
    
    // Now check all achievements as if starting fresh (earnedIds will be empty)
    final newAchievements = <Achievement>[];
    
    // Weight progress achievements (dynamic based on goal)
    if (profile != null && profile.weight != null && profile.targetWeight != null) {
      final progressAchievements = _checkWeightProgress(
        userId: userId,
        currentWeight: allStats.isNotEmpty ? allStats.first.weight : profile.weight,
        startWeight: profile.weight!,
        targetWeight: profile.targetWeight!,
        earnedIds: {}, // Force empty set
      );
      newAchievements.addAll(progressAchievements);
      
      // Save weight achievements immediately
      for (final achievement in progressAchievements) {
        await saveAchievement(achievement);
      }
    }

    // Consistency achievements
    final consistencyAchievements = _checkConsistency(
      userId: userId,
      stats: allStats,
      earnedIds: {},
    );
    newAchievements.addAll(consistencyAchievements);
    for (final achievement in consistencyAchievements) {
      await saveAchievement(achievement);
    }

    // Photo achievements
    final photoAchievements = _checkPhotos(
      userId: userId,
      photoCount: allPhotos.length,
      earnedIds: {},
    );
    newAchievements.addAll(photoAchievements);
    for (final achievement in photoAchievements) {
      await saveAchievement(achievement);
    }

    // BMI improvements
    if (allStats.length >= 2) {
      final bmiAchievements = _checkBmiImprovements(
        userId: userId,
        stats: allStats,
        earnedIds: {},
      );
      newAchievements.addAll(bmiAchievements);
      for (final achievement in bmiAchievements) {
        await saveAchievement(achievement);
      }
    }

    // Entry count achievements
    final entryAchievements = _checkEntries(
      userId: userId,
      entryCount: allStats.length,
      earnedIds: {},
    );
    newAchievements.addAll(entryAchievements);
    for (final achievement in entryAchievements) {
      await saveAchievement(achievement);
    }
    
    // Small delay to ensure Firestore write is complete
    await Future.delayed(const Duration(milliseconds: 200));
    
    // Return all newly created achievements
    return await getUserAchievements(userId);
  }

  // ── Check for New Achievements ────────────────────────────────────────────

  /// Check all potential achievements and return newly earned ones
  Future<List<Achievement>> checkAchievements({
    required String userId,
    required UserProfile? profile,
    required List<BodyStats> allStats,
    required List<PhotoMetadata> allPhotos,
  }) async {
    final earnedIds = await getEarnedAchievementIds(userId);
    final newAchievements = <Achievement>[];

    // Weight progress achievements (dynamic based on goal)
    if (profile != null && profile.weight != null && profile.targetWeight != null) {
      final progressAchievements = _checkWeightProgress(
        userId: userId,
        currentWeight: allStats.isNotEmpty ? allStats.first.weight : profile.weight,
        startWeight: profile.weight!,
        targetWeight: profile.targetWeight!,
        earnedIds: earnedIds,
      );
      newAchievements.addAll(progressAchievements);
    }

    // Consistency achievements
    newAchievements.addAll(_checkConsistency(
      userId: userId,
      stats: allStats,
      earnedIds: earnedIds,
    ));

    // Photo achievements
    newAchievements.addAll(_checkPhotos(
      userId: userId,
      photoCount: allPhotos.length,
      earnedIds: earnedIds,
    ));

    // BMI improvements
    if (allStats.length >= 2) {
      newAchievements.addAll(_checkBmiImprovements(
        userId: userId,
        stats: allStats,
        earnedIds: earnedIds,
      ));
    }

    // Entry count achievements
    newAchievements.addAll(_checkEntries(
      userId: userId,
      entryCount: allStats.length,
      earnedIds: earnedIds,
    ));

    // Save new achievements to Firestore
    for (final achievement in newAchievements) {
      await saveAchievement(achievement);
    }

    return newAchievements;
  }

  // ── Weight Progress Calculation ───────────────────────────────────────────

  List<Achievement> _checkWeightProgress({
    required String userId,
    required double? currentWeight,
    required double startWeight,
    required double targetWeight,
    required Set<String> earnedIds,
  }) {
    if (currentWeight == null) return [];

    final achievements = <Achievement>[];
    final totalChange = (startWeight - targetWeight).abs();
    final currentChange = (startWeight - currentWeight).abs();
    final progressPercent = (currentChange / totalChange * 100).clamp(0.0, 100.0).toDouble();

    // Check each milestone
    final milestones = [
      (10.0, AchievementType.weightProgress10),
      (25.0, AchievementType.weightProgress25),
      (50.0, AchievementType.weightProgress50),
      (75.0, AchievementType.weightProgress75),
      (90.0, AchievementType.weightProgress90),
      (100.0, AchievementType.weightProgress100),
    ];

    for (final (threshold, type) in milestones) {
      if (progressPercent >= threshold && !earnedIds.contains(type.id)) {
        achievements.add(Achievement(
          userId: userId,
          type: type,
          earnedAt: DateTime.now(),
          progressValue: progressPercent,
          metadata: {
            'startWeight': startWeight,
            'currentWeight': currentWeight,
            'targetWeight': targetWeight,
            'progressPercent': progressPercent,
          },
        ));
      }
    }

    return achievements;
  }

  // ── Consistency Achievements ──────────────────────────────────────────────

  List<Achievement> _checkConsistency({
    required String userId,
    required List<BodyStats> stats,
    required Set<String> earnedIds,
  }) {
    final achievements = <Achievement>[];
    
    if (stats.isEmpty) return [];

    // Calculate longest streak
    final streak = _calculateStreak(stats);

    if (streak >= 7 && !earnedIds.contains(AchievementType.firstWeek.id)) {
      achievements.add(Achievement(
        userId: userId,
        type: AchievementType.firstWeek,
        earnedAt: DateTime.now(),
        progressValue: streak.toDouble(),
      ));
    }

    if (streak >= 30 && !earnedIds.contains(AchievementType.streak30.id)) {
      achievements.add(Achievement(
        userId: userId,
        type: AchievementType.streak30,
        earnedAt: DateTime.now(),
        progressValue: streak.toDouble(),
      ));
    }

    if (streak >= 100 && !earnedIds.contains(AchievementType.streak100.id)) {
      achievements.add(Achievement(
        userId: userId,
        type: AchievementType.streak100,
        earnedAt: DateTime.now(),
        progressValue: streak.toDouble(),
      ));
    }

    return achievements;
  }

  int _calculateStreak(List<BodyStats> stats) {
    if (stats.isEmpty) return 0;

    // Sort by date
    final sortedStats = List<BodyStats>.from(stats)
      ..sort((a, b) => b.date.compareTo(a.date));

    int streak = 1;
    for (int i = 0; i < sortedStats.length - 1; i++) {
      final current = sortedStats[i].date;
      final next = sortedStats[i + 1].date;
      final difference = current.difference(next).inDays;

      if (difference <= 1) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  // ── Photo Achievements ────────────────────────────────────────────────────

  List<Achievement> _checkPhotos({
    required String userId,
    required int photoCount,
    required Set<String> earnedIds,
  }) {
    final achievements = <Achievement>[];

    if (photoCount >= 1 && !earnedIds.contains(AchievementType.firstPhoto.id)) {
      achievements.add(Achievement(
        userId: userId,
        type: AchievementType.firstPhoto,
        earnedAt: DateTime.now(),
        progressValue: photoCount.toDouble(),
      ));
    }

    if (photoCount >= 10 && !earnedIds.contains(AchievementType.photos10.id)) {
      achievements.add(Achievement(
        userId: userId,
        type: AchievementType.photos10,
        earnedAt: DateTime.now(),
        progressValue: photoCount.toDouble(),
      ));
    }

    if (photoCount >= 50 && !earnedIds.contains(AchievementType.photos50.id)) {
      achievements.add(Achievement(
        userId: userId,
        type: AchievementType.photos50,
        earnedAt: DateTime.now(),
        progressValue: photoCount.toDouble(),
      ));
    }

    return achievements;
  }

  // ── BMI Achievements ──────────────────────────────────────────────────────

  List<Achievement> _checkBmiImprovements({
    required String userId,
    required List<BodyStats> stats,
    required Set<String> earnedIds,
  }) {
    final achievements = <Achievement>[];
    
    if (stats.length < 2) return [];

    final sorted = List<BodyStats>.from(stats)
      ..sort((a, b) => a.date.compareTo(b.date));

    final firstBmi = sorted.first.bmi;
    final latestBmi = sorted.last.bmi;

    if (firstBmi == null || latestBmi == null) return [];

    // Check BMI category improvement
    final firstCategory = _getBmiCategory(firstBmi);
    final latestCategory = _getBmiCategory(latestBmi);

    if (firstCategory > latestCategory && !earnedIds.contains(AchievementType.bmiImprovement.id)) {
      achievements.add(Achievement(
        userId: userId,
        type: AchievementType.bmiImprovement,
        earnedAt: DateTime.now(),
        metadata: {
          'startBmi': firstBmi,
          'currentBmi': latestBmi,
        },
      ));
    }

    // Check healthy BMI range
    if (latestBmi >= 18.5 && latestBmi < 25.0 && !earnedIds.contains(AchievementType.healthyBmi.id)) {
      achievements.add(Achievement(
        userId: userId,
        type: AchievementType.healthyBmi,
        earnedAt: DateTime.now(),
        progressValue: latestBmi,
      ));
    }

    return achievements;
  }

  int _getBmiCategory(double bmi) {
    if (bmi < 18.5) return 0; // Underweight
    if (bmi < 25.0) return 1; // Normal
    if (bmi < 30.0) return 2; // Overweight
    return 3; // Obese
  }

  // ── Entry Count Achievements ──────────────────────────────────────────────

  List<Achievement> _checkEntries({
    required String userId,
    required int entryCount,
    required Set<String> earnedIds,
  }) {
    final achievements = <Achievement>[];

    if (entryCount >= 10 && !earnedIds.contains(AchievementType.entries10.id)) {
      achievements.add(Achievement(
        userId: userId,
        type: AchievementType.entries10,
        earnedAt: DateTime.now(),
        progressValue: entryCount.toDouble(),
      ));
    }

    if (entryCount >= 50 && !earnedIds.contains(AchievementType.entries50.id)) {
      achievements.add(Achievement(
        userId: userId,
        type: AchievementType.entries50,
        earnedAt: DateTime.now(),
        progressValue: entryCount.toDouble(),
      ));
    }

    if (entryCount >= 100 && !earnedIds.contains(AchievementType.entries100.id)) {
      achievements.add(Achievement(
        userId: userId,
        type: AchievementType.entries100,
        earnedAt: DateTime.now(),
        progressValue: entryCount.toDouble(),
      ));
    }

    return achievements;
  }
}
