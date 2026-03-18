import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:body_progress/core/design_system.dart';
import 'package:body_progress/models/achievement.dart';
import 'package:body_progress/models/body_stats.dart';
import 'package:body_progress/providers/achievement_provider.dart';
import 'package:body_progress/providers/profile_provider.dart';
import 'package:body_progress/providers/progress_provider.dart';
import 'package:body_progress/providers/photo_provider.dart';

class AchievementsView extends ConsumerStatefulWidget {
  const AchievementsView({super.key});

  @override
  ConsumerState<AchievementsView> createState() => _AchievementsViewState();
}

class _AchievementsViewState extends ConsumerState<AchievementsView> {
  @override
  void initState() {
    super.initState();
    // Recalculate all achievements to ensure correctness
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(achievementProvider.notifier).recalculateAllAchievements();
    });
  }

  @override
  Widget build(BuildContext context) {
    final achievementState = ref.watch(achievementProvider);
    final profileState = ref.watch(profileProvider);
    final progressState = ref.watch(progressProvider);
    final photoState = ref.watch(photoProvider);

    final earnedAchievements = achievementState.achievements;
    final earnedIds = earnedAchievements.map((a) => a.type.id).toSet();

    // Get current states for progress calculation
    final profile = profileState.profile;
    final stats = progressState.cachedBodyStats;
    final photoCount = photoState.photos.length;
    final entryCount = stats.length;
    
    // Calculate current weight progress
    double? weightProgressPercent;
    if (profile != null && 
        profile.weight != null && 
        profile.targetWeight != null &&
        stats.isNotEmpty) {
      final currentWeight = stats.first.weight;
      if (currentWeight != null) {
        final totalChange = (profile.weight! - profile.targetWeight!).abs();
        final currentChange = (profile.weight! - currentWeight).abs();
        weightProgressPercent = (currentChange / totalChange * 100).clamp(0.0, 100.0).toDouble();
      }
    }
    
    // Calculate current streak
    int currentStreak = _calculateCurrentStreak(stats);

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      appBar: AppBar(
        title: const Text('Achievements'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: achievementState.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.brandPrimary),
            )
          : RefreshIndicator(
              onRefresh: () async {
                await ref.read(achievementProvider.notifier).recalculateAllAchievements();
              },
              color: AppColors.brandPrimary,
              backgroundColor: AppColors.cardBackground,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats summary
                    _StatsCard(
                      earnedCount: earnedAchievements.length,
                      totalCount: AchievementType.values.length,
                      progressPercent: weightProgressPercent,
                    ),
                    const SizedBox(height: 24),

                    // Weight Progress Section
                    if (weightProgressPercent != null) ...[
                      _SectionHeader(
                        title: 'Weight Progress',
                        subtitle: '${weightProgressPercent.toStringAsFixed(0)}% to goal',
                      ),
                      const SizedBox(height: 12),
                      ..._buildWeightProgressAchievements(earnedIds, weightProgressPercent),
                      const SizedBox(height: 24),
                    ],

                    // Consistency Section
                    _SectionHeader(
                      title: 'Consistency',
                      subtitle: currentStreak > 0 ? '$currentStreak day streak' : 'Keep logging regularly',
                    ),
                    const SizedBox(height: 12),
                    ..._buildConsistencyAchievements(earnedIds, currentStreak),
                    const SizedBox(height: 24),

                    // Photos Section
                    _SectionHeader(
                      title: 'Progress Photos',
                      subtitle: '$photoCount photos uploaded',
                    ),
                    const SizedBox(height: 12),
                    ..._buildPhotoAchievements(earnedIds, photoCount),
                    const SizedBox(height: 24),

                    // Health Section
                    _SectionHeader(
                      title: 'Health Milestones',
                      subtitle: 'BMI and body composition',
                    ),
                    const SizedBox(height: 12),
                    ..._buildHealthAchievements(earnedIds),
                    const SizedBox(height: 24),

                    // Entries Section
                    _SectionHeader(
                      title: 'Tracking Champion',
                      subtitle: '$entryCount entries logged',
                    ),
                    const SizedBox(height: 12),
                    ..._buildEntryAchievements(earnedIds, entryCount),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
    );
  }

  List<Widget> _buildWeightProgressAchievements(Set<String> earnedIds, double currentProgress) {
    final types = [
      AchievementType.weightProgress10,
      AchievementType.weightProgress25,
      AchievementType.weightProgress50,
      AchievementType.weightProgress75,
      AchievementType.weightProgress90,
      AchievementType.weightProgress100,
    ];

    return types.map((type) {
      final isEarned = earnedIds.contains(type.id);
      final achievement = ref
          .read(achievementProvider)
          .achievements
          .where((a) => a.type == type)
          .firstOrNull;

      final threshold = int.parse(type.id.split('_').last);
      
      // Calculate progress towards THIS specific milestone
      double? progress;
      if (!isEarned && currentProgress > 0) {
        if (currentProgress < threshold) {
          // Show progress as percentage towards this milestone
          // e.g., if you're at 72% and milestone is 75%, show 96% (72/75 * 100)
          progress = (currentProgress / threshold * 100).clamp(0.0, 100.0).toDouble();
        }
        // If currentProgress >= threshold, don't show progress (should be earned)
      }

      return _AchievementCard(
        type: type,
        isEarned: isEarned,
        earnedAt: achievement?.earnedAt,
        currentProgress: progress,
        progressValue: isEarned ? achievement?.progressValue : null,
      );
    }).toList();
  }

  List<Widget> _buildConsistencyAchievements(Set<String> earnedIds, int currentStreak) {
    final milestones = [
      (AchievementType.firstWeek, 7),
      (AchievementType.streak30, 30),
      (AchievementType.streak100, 100),
    ];

    return milestones.map((record) {
      final type = record.$1;
      final target = record.$2;
      final isEarned = earnedIds.contains(type.id);
      final achievement = ref
          .read(achievementProvider)
          .achievements
          .where((a) => a.type == type)
          .firstOrNull;

      final progress = isEarned ? null : (currentStreak / target * 100).clamp(0.0, 100.0).toDouble();

      return _AchievementCard(
        type: type,
        isEarned: isEarned,
        earnedAt: achievement?.earnedAt,
        currentProgress: progress,
        progressValue: isEarned ? achievement?.progressValue : null,
      );
    }).toList();
  }

  List<Widget> _buildPhotoAchievements(Set<String> earnedIds, int photoCount) {
    final milestones = [
      (AchievementType.firstPhoto, 1),
      (AchievementType.photos10, 10),
      (AchievementType.photos50, 50),
    ];

    return milestones.map((record) {
      final type = record.$1;
      final target = record.$2;
      final isEarned = earnedIds.contains(type.id);
      final achievement = ref
          .read(achievementProvider)
          .achievements
          .where((a) => a.type == type)
          .firstOrNull;

      final progress = isEarned ? null : (photoCount / target * 100).clamp(0.0, 100.0).toDouble();

      return _AchievementCard(
        type: type,
        isEarned: isEarned,
        earnedAt: achievement?.earnedAt,
        currentProgress: progress,
        progressValue: isEarned ? achievement?.progressValue : null,
      );
    }).toList();
  }

  List<Widget> _buildHealthAchievements(Set<String> earnedIds) {
    final types = [
      AchievementType.bmiImprovement,
      AchievementType.healthyBmi,
    ];

    return types.map((type) {
      final isEarned = earnedIds.contains(type.id);
      final achievement = ref
          .read(achievementProvider)
          .achievements
          .where((a) => a.type == type)
          .firstOrNull;

      return _AchievementCard(
        type: type,
        isEarned: isEarned,
        earnedAt: achievement?.earnedAt,
        progressValue: achievement?.progressValue,
        currentProgress: null, // BMI progress is complex (category-based)
      );
    }).toList();
  }

  List<Widget> _buildEntryAchievements(Set<String> earnedIds, int entryCount) {
    final milestones = [
      (AchievementType.entries10, 10),
      (AchievementType.entries50, 50),
      (AchievementType.entries100, 100),
    ];

    return milestones.map((record) {
      final type = record.$1;
      final target = record.$2;
      final isEarned = earnedIds.contains(type.id);
      final achievement = ref
          .read(achievementProvider)
          .achievements
          .where((a) => a.type == type)
          .firstOrNull;

      final progress = isEarned ? null : (entryCount / target * 100).clamp(0.0, 100.0).toDouble();

      return _AchievementCard(
        type: type,
        isEarned: isEarned,
        earnedAt: achievement?.earnedAt,
        currentProgress: progress,
        progressValue: isEarned ? achievement?.progressValue : null,
      );
    }).toList();
  }

  int _calculateCurrentStreak(List<BodyStats> stats) {
    if (stats.isEmpty) return 0;

    final sortedStats = stats.toList()
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
}

class _StatsCard extends StatelessWidget {
  final int earnedCount;
  final int totalCount;
  final double? progressPercent;

  const _StatsCard({
    required this.earnedCount,
    required this.totalCount,
    this.progressPercent,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (earnedCount / totalCount * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppGradients.glass,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.brandPrimary.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                label: 'Earned',
                value: '$earnedCount',
                icon: Icons.emoji_events,
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.2),
              ),
              _StatItem(
                label: 'Total',
                value: '$totalCount',
                icon: Icons.star_outline,
              ),
              if (progressPercent != null) ...[
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.2),
                ),
                _StatItem(
                  label: 'Progress',
                  value: '${progressPercent!.toStringAsFixed(0)}%',
                  icon: Icons.trending_up,
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: AppColors.darkCardBackground,
              valueColor: const AlwaysStoppedAnimation(AppColors.brandPrimary),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.brandPrimary, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.title2.copyWith(color: Colors.white),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontFamily: 'Nunito',
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.title3.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontFamily: 'Nunito',
          ),
        ),
      ],
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final AchievementType type;
  final bool isEarned;
  final DateTime? earnedAt;
  final bool isInProgress;
  final double? progressValue;
  final double? currentProgress;

  const _AchievementCard({
    required this.type,
    required this.isEarned,
    this.earnedAt,
    this.isInProgress = false,
    this.progressValue,
    this.currentProgress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isEarned
            ? LinearGradient(
                colors: [
                  AppColors.brandPrimary.withOpacity(0.2),
                  AppColors.cardBackground,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isEarned ? null : AppColors.darkCardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEarned
              ? AppColors.brandPrimary.withOpacity(0.5)
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          // Emoji/Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: isEarned ? AppGradients.brand : null,
              color: isEarned ? null : AppColors.cardBackground,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                isEarned ? type.emoji : '🔒',
                style: TextStyle(
                  fontSize: 32,
                  color: isEarned ? null : Colors.white.withOpacity(0.3),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.title,
                  style: TextStyle(
                    color: isEarned ? Colors.white : AppColors.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Nunito',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  type.description,
                  style: TextStyle(
                    color: isEarned
                        ? AppColors.textSecondary
                        : AppColors.textTertiary,
                    fontSize: 13,
                    fontFamily: 'Nunito',
                  ),
                ),
                if (isEarned && earnedAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Earned ${DateFormat('MMM d, yyyy').format(earnedAt!)}',
                    style: TextStyle(
                      color: AppColors.brandPrimary.withOpacity(0.8),
                      fontSize: 11,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ],
                if (!isEarned && currentProgress != null && currentProgress! > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: currentProgress! / 100,
                            backgroundColor: AppColors.darkCardBackground,
                            valueColor: const AlwaysStoppedAnimation(AppColors.brandSecondary),
                            minHeight: 4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${currentProgress!.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: AppColors.brandSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ],
                  ),
                ],
                if (isInProgress && progressValue != null) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progressValue! / 100,
                      backgroundColor: AppColors.darkCardBackground,
                      valueColor: const AlwaysStoppedAnimation(AppColors.brandSecondary),
                      minHeight: 4,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Checkmark
          if (isEarned)
            const Icon(
              Icons.check_circle,
              color: AppColors.brandPrimary,
              size: 24,
            ),
        ],
      ),
    );
  }
}
