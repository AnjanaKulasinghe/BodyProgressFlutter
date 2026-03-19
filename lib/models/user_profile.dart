import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String? id;
  final String userId;
  final String email;
  final String name;
  final DateTime dateOfBirth;
  final Gender gender;
  final double? height; // cm
  final ActivityLevel activityLevel;
  final FitnessGoal fitnessGoal;
  final double? targetWeight; // kg
  final double? weight;       // current kg
  final double? bmi;
  final double? bodyFatPercentage;
  final double? waistCircumference;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastHealthSync;

  const UserProfile({
    this.id,
    required this.userId,
    required this.email,
    required this.name,
    required this.dateOfBirth,
    required this.gender,
    this.height,
    required this.activityLevel,
    required this.fitnessGoal,
    this.targetWeight,
    this.weight,
    this.bmi,
    this.bodyFatPercentage,
    this.waistCircumference,
    required this.createdAt,
    required this.updatedAt,
    this.lastHealthSync,
  });

  // ── Firestore serialisation ──────────────────────────────────────────────

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UserProfile(
      id: doc.id,
      userId: d['userId'] as String,
      email: d['email'] as String,
      name: d['name'] as String,
      dateOfBirth: (d['dateOfBirth'] as Timestamp?)?.toDate() ?? DateTime(1990, 1, 1),
      gender: Gender.fromString(d['gender'] as String? ?? 'male'),
      height: (d['height'] as num?)?.toDouble(),
      activityLevel: ActivityLevel.fromString(d['activityLevel'] as String? ?? 'moderatelyActive'),
      fitnessGoal: FitnessGoal.fromString(d['fitnessGoal'] as String? ?? 'maintainWeight'),
      targetWeight: (d['targetWeight'] as num?)?.toDouble(),
      weight: (d['weight'] as num?)?.toDouble(),
      bmi: (d['bmi'] as num?)?.toDouble(),
      bodyFatPercentage: (d['bodyFatPercentage'] as num?)?.toDouble(),
      waistCircumference: (d['waistCircumference'] as num?)?.toDouble(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastHealthSync: (d['lastHealthSync'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'email': email,
    'name': name,
    'dateOfBirth': Timestamp.fromDate(dateOfBirth),
    'gender': gender.value,
    if (height != null) 'height': height,
    'activityLevel': activityLevel.value,
    'fitnessGoal': fitnessGoal.value,
    if (targetWeight != null) 'targetWeight': targetWeight,
    if (weight != null) 'weight': weight,
    if (bmi != null) 'bmi': bmi,
    if (bodyFatPercentage != null) 'bodyFatPercentage': bodyFatPercentage,
    if (waistCircumference != null) 'waistCircumference': waistCircumference,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
    if (lastHealthSync != null) 'lastHealthSync': Timestamp.fromDate(lastHealthSync!),
  };

  UserProfile copyWith({
    String? id,
    String? userId,
    String? email,
    String? name,
    DateTime? dateOfBirth,
    Gender? gender,
    double? height,
    ActivityLevel? activityLevel,
    FitnessGoal? fitnessGoal,
    double? targetWeight,
    double? weight,
    double? bmi,
    double? bodyFatPercentage,
    double? waistCircumference,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastHealthSync,
  }) => UserProfile(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    email: email ?? this.email,
    name: name ?? this.name,
    dateOfBirth: dateOfBirth ?? this.dateOfBirth,
    gender: gender ?? this.gender,
    height: height ?? this.height,
    activityLevel: activityLevel ?? this.activityLevel,
    fitnessGoal: fitnessGoal ?? this.fitnessGoal,
    targetWeight: targetWeight ?? this.targetWeight,
    weight: weight ?? this.weight,
    bmi: bmi ?? this.bmi,
    bodyFatPercentage: bodyFatPercentage ?? this.bodyFatPercentage,
    waistCircumference: waistCircumference ?? this.waistCircumference,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    lastHealthSync: lastHealthSync ?? this.lastHealthSync,
  );

  // ── Business Logic (matching iOS exactly) ─────────────────────────────────

  int get age {
    final now = DateTime.now();
    int years = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      years--;
    }
    return years;
  }

  /// Mifflin-St Jeor BMR
  double calculateBmr(double weightKg) {
    final h = height ?? 0;
    if (gender == Gender.male) {
      return 10 * weightKg + 6.25 * h - 5 * age + 5;
    } else {
      return 10 * weightKg + 6.25 * h - 5 * age - 161;
    }
  }

  double calculateTdee(double weightKg) => calculateBmr(weightKg) * activityLevel.multiplier;
}

// ── Enums ────────────────────────────────────────────────────────────────────

enum Gender {
  male('male'),
  female('female');

  const Gender(this.value);
  final String value;

  String get displayName => value == 'male' ? 'Male' : 'Female';

  static Gender fromString(String s) =>
      Gender.values.firstWhere((e) => e.value == s, orElse: () => Gender.male);
}

enum ActivityLevel {
  sedentary('sedentary', 'Sedentary', 1.2),
  lightlyActive('lightlyActive', 'Lightly Active', 1.375),
  moderatelyActive('moderatelyActive', 'Moderately Active', 1.55),
  veryActive('veryActive', 'Very Active', 1.725),
  extraActive('extraActive', 'Extra Active', 1.9);

  const ActivityLevel(this.value, this.displayName, this.multiplier);
  final String value;
  final String displayName;
  final double multiplier;

  static ActivityLevel fromString(String s) =>
      ActivityLevel.values.firstWhere((e) => e.value == s,
          orElse: () => ActivityLevel.moderatelyActive);
}

enum FitnessGoal {
  loseWeight('loseWeight', 'Lose Weight'),
  maintainWeight('maintainWeight', 'Maintain Weight'),
  gainWeight('gainWeight', 'Gain Weight'),
  buildMuscle('buildMuscle', 'Build Muscle'),
  improveEndurance('improveEndurance', 'Improve Endurance');

  const FitnessGoal(this.value, this.displayName);
  final String value;
  final String displayName;

  static FitnessGoal fromString(String s) =>
      FitnessGoal.values.firstWhere((e) => e.value == s,
          orElse: () => FitnessGoal.maintainWeight);
}
