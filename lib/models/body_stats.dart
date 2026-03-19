import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:body_progress/models/user_profile.dart';

class BodyStats {
  final String? id;
  final String userId;
  final DateTime date;
  final double weight; // kg — required
  final double? waistCircumference; // cm
  final double? neckCircumference;  // cm
  final double? hipCircumference;   // cm
  final double? chestCircumference; // cm
  final double? armCircumference;   // cm
  final double? thighCircumference; // cm
  final double? bodyFatPercentage;  // %
  final double? muscleMass;         // kg
  final String? notes;
  final DataSource source;
  final DateTime createdAt;
  final double? bmi;

  const BodyStats({
    this.id,
    required this.userId,
    required this.date,
    required this.weight,
    this.waistCircumference,
    this.neckCircumference,
    this.hipCircumference,
    this.chestCircumference,
    this.armCircumference,
    this.thighCircumference,
    this.bodyFatPercentage,
    this.muscleMass,
    this.notes,
    required this.source,
    required this.createdAt,
    this.bmi,
  });

  // ── Firestore serialisation ──────────────────────────────────────────────

  factory BodyStats.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return BodyStats(
      id: doc.id,
      userId: d['userId'] as String,
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      weight: (d['weight'] as num).toDouble(),
      waistCircumference: (d['waistCircumference'] as num?)?.toDouble(),
      neckCircumference: (d['neckCircumference'] as num?)?.toDouble(),
      hipCircumference: (d['hipCircumference'] as num?)?.toDouble(),
      chestCircumference: (d['chestCircumference'] as num?)?.toDouble(),
      armCircumference: (d['armCircumference'] as num?)?.toDouble(),
      thighCircumference: (d['thighCircumference'] as num?)?.toDouble(),
      bodyFatPercentage: (d['bodyFatPercentage'] as num?)?.toDouble(),
      muscleMass: (d['muscleMass'] as num?)?.toDouble(),
      notes: d['notes'] as String?,
      source: DataSource.fromString(d['source'] as String? ?? 'manual'),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      bmi: (d['bmi'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'date': Timestamp.fromDate(date),
    'weight': weight,
    if (waistCircumference != null) 'waistCircumference': waistCircumference,
    if (neckCircumference != null) 'neckCircumference': neckCircumference,
    if (hipCircumference != null) 'hipCircumference': hipCircumference,
    if (chestCircumference != null) 'chestCircumference': chestCircumference,
    if (armCircumference != null) 'armCircumference': armCircumference,
    if (thighCircumference != null) 'thighCircumference': thighCircumference,
    if (bodyFatPercentage != null) 'bodyFatPercentage': bodyFatPercentage,
    if (muscleMass != null) 'muscleMass': muscleMass,
    if (notes != null) 'notes': notes,
    'source': source.value,
    'createdAt': Timestamp.fromDate(createdAt),
    if (bmi != null) 'bmi': bmi,
  };

  BodyStats copyWith({
    String? id,
    String? userId,
    DateTime? date,
    double? weight,
    double? waistCircumference,
    double? neckCircumference,
    double? hipCircumference,
    double? chestCircumference,
    double? armCircumference,
    double? thighCircumference,
    double? bodyFatPercentage,
    double? muscleMass,
    String? notes,
    DataSource? source,
    DateTime? createdAt,
    double? bmi,
  }) => BodyStats(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    date: date ?? this.date,
    weight: weight ?? this.weight,
    waistCircumference: waistCircumference ?? this.waistCircumference,
    neckCircumference: neckCircumference ?? this.neckCircumference,
    hipCircumference: hipCircumference ?? this.hipCircumference,
    chestCircumference: chestCircumference ?? this.chestCircumference,
    armCircumference: armCircumference ?? this.armCircumference,
    thighCircumference: thighCircumference ?? this.thighCircumference,
    bodyFatPercentage: bodyFatPercentage ?? this.bodyFatPercentage,
    muscleMass: muscleMass ?? this.muscleMass,
    notes: notes ?? this.notes,
    source: source ?? this.source,
    createdAt: createdAt ?? this.createdAt,
    bmi: bmi ?? this.bmi,
  );

  // ── Business Logic ───────────────────────────────────────────────────────

  /// BMI = weight(kg) / (height(m))²
  double calculateBmi(double heightCm) {
    if (heightCm <= 0) return 0;
    return weight / math.pow(heightCm / 100, 2);
  }

  /// US Navy Body Fat method — identical formula to iOS app
  double? calculateBodyFatPercentage(double heightCm, Gender gender) {
    final waist = waistCircumference;
    final neck  = neckCircumference;
    if (waist == null || neck == null || heightCm <= 0) return null;

    final heightIn = heightCm / 2.54;
    final waistIn  = waist / 2.54;
    final neckIn   = neck / 2.54;

    if (gender == Gender.male) {
      final value = waistIn - neckIn;
      if (value <= 0) return null;
      final denom = 1.0324 - 0.19077 * math.log(value) / math.ln10
                            + 0.15456 * math.log(heightIn) / math.ln10;
      return 495 / denom - 450;
    } else {
      final hip = hipCircumference;
      if (hip == null) return null;
      final hipIn = hip / 2.54;
      final value = waistIn + hipIn - neckIn;
      if (value <= 0) return null;
      final denom = 1.29579 - 0.35004 * math.log(value) / math.ln10
                             + 0.22100 * math.log(heightIn) / math.ln10;
      return 495 / denom - 450;
    }
  }

  BmiCategory getBmiCategory(double heightCm) {
    final b = calculateBmi(heightCm);
    if (b < 18.5) return BmiCategory.underweight;
    if (b < 25)   return BmiCategory.normal;
    if (b < 30)   return BmiCategory.overweight;
    return BmiCategory.obese;
  }

  String get formattedWeight => '${weight.toStringAsFixed(1)} kg';
  String get formattedBmi    => (bmi ?? 0).toStringAsFixed(1);
}

// ── Supporting enums ─────────────────────────────────────────────────────────

enum DataSource {
  manual('manual'),
  healthKit('healthKit'),
  healthConnect('healthConnect'),
  scale('scale');

  const DataSource(this.value);
  final String value;

  static DataSource fromString(String s) =>
      DataSource.values.firstWhere((e) => e.value == s, orElse: () => DataSource.manual);
}

enum BmiCategory {
  underweight, normal, overweight, obese;

  String get displayName {
    switch (this) {
      case BmiCategory.underweight: return 'Underweight';
      case BmiCategory.normal:      return 'Normal';
      case BmiCategory.overweight:  return 'Overweight';
      case BmiCategory.obese:       return 'Obese';
    }
  }
}
