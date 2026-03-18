enum GoalType {
  weightLoss('weight_loss', 'Weight Loss', 'kg'),
  weightGain('weight_gain', 'Weight Gain', 'kg'),
  bodyFatReduction('body_fat_reduction', 'Body Fat Reduction', '%'),
  muscleMassGain('muscle_mass_gain', 'Muscle Mass Gain', 'kg'),
  waistReduction('waist_reduction', 'Waist Reduction', 'cm');

  const GoalType(this.value, this.displayName, this.unit);
  final String value;
  final String displayName;
  final String unit;

  static GoalType fromString(String s) =>
      GoalType.values.firstWhere((e) => e.value == s, orElse: () => GoalType.weightLoss);
}

class UserGoal {
  final String id;
  final GoalType type;
  final double targetValue;
  final double currentValue;
  final DateTime deadline;
  final bool isActive;

  UserGoal({
    String? id,
    required this.type,
    required this.targetValue,
    required this.currentValue,
    required this.deadline,
    required this.isActive,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  double get progressPercentage {
    if (targetValue == currentValue) return 100.0;

    switch (type) {
      case GoalType.weightLoss:
      case GoalType.bodyFatReduction:
      case GoalType.waistReduction:
        final totalReduction = currentValue - targetValue;
        if (totalReduction <= 0) return 0;
        final actualReduction = currentValue - targetValue;
        return (actualReduction / totalReduction * 100).clamp(0, 100);
      case GoalType.weightGain:
      case GoalType.muscleMassGain:
        final totalGain = targetValue - currentValue;
        if (totalGain <= 0) return 0;
        final actualGain = currentValue - targetValue;
        return (actualGain / totalGain * 100).clamp(0, 100);
    }
  }
}
