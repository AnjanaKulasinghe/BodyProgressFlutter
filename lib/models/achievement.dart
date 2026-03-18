import 'package:cloud_firestore/cloud_firestore.dart';

/// Achievement/Milestone types
enum AchievementType {
  // Weight progress milestones (dynamic based on user's goal)
  weightProgress10('weight_progress_10', 'Getting Started!', '🎯', 'Achieved 10% of your goal'),
  weightProgress25('weight_progress_25', 'Quarter Way There!', '🌟', 'Achieved 25% of your goal'),
  weightProgress50('weight_progress_50', 'Halfway Champion!', '🏆', 'Achieved 50% of your goal'),
  weightProgress75('weight_progress_75', 'Almost There!', '💪', 'Achieved 75% of your goal'),
  weightProgress90('weight_progress_90', 'So Close!', '🔥', 'Achieved 90% of your goal'),
  weightProgress100('weight_progress_100', 'Goal Achieved!', '🎉', 'You reached your target!'),
  
  // Consistency milestones
  firstWeek('first_week', 'First Week Complete!', '📅', 'Logged stats for 7 days'),
  streak30('streak_30', 'Month Strong!', '⭐', '30-day logging streak'),
  streak100('streak_100', 'Century Club!', '💯', '100-day logging streak'),
  
  // Photo milestones
  firstPhoto('first_photo', 'Picture Perfect!', '📸', 'Uploaded your first progress photo'),
  photos10('photos_10', 'Photo Enthusiast!', '📷', 'Uploaded 10 progress photos'),
  photos50('photos_50', 'Photo Master!', '🎬', 'Uploaded 50 progress photos'),
  
  // BMI improvement milestones
  bmiImprovement('bmi_improvement', 'Health Champion!', '❤️', 'Improved BMI category'),
  healthyBmi('healthy_bmi', 'Healthy Range!', '🌈', 'Reached healthy BMI'),
  
  // Consistency milestones
  entries10('entries_10', 'Committed!', '✅', 'Logged 10 measurements'),
  entries50('entries_50', 'Dedicated!', '🎖️', 'Logged 50 measurements'),
  entries100('entries_100', 'Ultimate Tracker!', '👑', 'Logged 100 measurements');

  const AchievementType(this.id, this.title, this.emoji, this.description);
  final String id;
  final String title;
  final String emoji;
  final String description;

  static AchievementType? fromId(String id) {
    try {
      return AchievementType.values.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
}

/// Achievement model - tracks earned achievements
class Achievement {
  final String? id;
  final String userId;
  final AchievementType type;
  final DateTime earnedAt;
  final double? progressValue; // For progress milestones, stores the actual percentage/value
  final Map<String, dynamic>? metadata;

  const Achievement({
    this.id,
    required this.userId,
    required this.type,
    required this.earnedAt,
    this.progressValue,
    this.metadata,
  });

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'type': type.id,
    'earnedAt': Timestamp.fromDate(earnedAt),
    if (progressValue != null) 'progressValue': progressValue,
    if (metadata != null) 'metadata': metadata,
  };

  factory Achievement.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Achievement(
      id: doc.id,
      userId: data['userId'] as String,
      type: AchievementType.fromId(data['type'] as String) ?? AchievementType.firstWeek,
      earnedAt: (data['earnedAt'] as Timestamp).toDate(),
      progressValue: data['progressValue'] as double?,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  Achievement copyWith({
    String? id,
    String? userId,
    AchievementType? type,
    DateTime? earnedAt,
    double? progressValue,
    Map<String, dynamic>? metadata,
  }) => Achievement(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    type: type ?? this.type,
    earnedAt: earnedAt ?? this.earnedAt,
    progressValue: progressValue ?? this.progressValue,
    metadata: metadata ?? this.metadata,
  );
}
