import 'package:json_annotation/json_annotation.dart';

part 'gamification.g.dart';

/// User streak information
@JsonSerializable()
class UserStreak {
  @JsonKey(name: 'current_streak')
  final int currentStreak;

  @JsonKey(name: 'longest_streak')
  final int longestStreak;

  @JsonKey(name: 'last_workout_date')
  final String? lastWorkoutDate;

  @JsonKey(name: 'streak_start_date')
  final String? streakStartDate;

  @JsonKey(name: 'total_workouts')
  final int totalWorkouts;

  @JsonKey(name: 'total_workout_minutes')
  final int totalWorkoutMinutes;

  @JsonKey(name: 'current_week_workouts')
  final int currentWeekWorkouts;

  @JsonKey(name: 'week_workout_days')
  final List<String> weekWorkoutDays;

  UserStreak({
    required this.currentStreak,
    required this.longestStreak,
    this.lastWorkoutDate,
    this.streakStartDate,
    required this.totalWorkouts,
    required this.totalWorkoutMinutes,
    required this.currentWeekWorkouts,
    required this.weekWorkoutDays,
  });

  factory UserStreak.fromJson(Map<String, dynamic> json) =>
      _$UserStreakFromJson(json);
  Map<String, dynamic> toJson() => _$UserStreakToJson(this);

  /// Check if streak is active (worked out yesterday or today)
  bool get isStreakActive {
    if (lastWorkoutDate == null) return false;
    final lastDate = DateTime.parse(lastWorkoutDate!);
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    return lastDate.year == today.year &&
            lastDate.month == today.month &&
            lastDate.day == today.day ||
        lastDate.year == yesterday.year &&
            lastDate.month == yesterday.month &&
            lastDate.day == yesterday.day;
  }

  /// Check if user worked out today
  bool get workedOutToday {
    if (lastWorkoutDate == null) return false;
    final lastDate = DateTime.parse(lastWorkoutDate!);
    final today = DateTime.now();
    return lastDate.year == today.year &&
        lastDate.month == today.month &&
        lastDate.day == today.day;
  }

  /// Format total workout time
  String get formattedTotalTime {
    final hours = totalWorkoutMinutes ~/ 60;
    final minutes = totalWorkoutMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}

/// Achievement definition
@JsonSerializable()
class Achievement {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String category;

  @JsonKey(name: 'requirement_type')
  final String requirementType;

  @JsonKey(name: 'requirement_value')
  final int requirementValue;

  final int points;
  final String rarity;

  @JsonKey(name: 'sort_order')
  final int sortOrder;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.requirementType,
    required this.requirementValue,
    required this.points,
    required this.rarity,
    required this.sortOrder,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) =>
      _$AchievementFromJson(json);
  Map<String, dynamic> toJson() => _$AchievementToJson(this);

  /// Get rarity color
  String get rarityColor {
    switch (rarity) {
      case 'common':
        return '#9CA3AF'; // Gray
      case 'rare':
        return '#3B82F6'; // Blue
      case 'epic':
        return '#8B5CF6'; // Purple
      case 'legendary':
        return '#F59E0B'; // Gold
      default:
        return '#9CA3AF';
    }
  }
}

/// User's earned achievement
@JsonSerializable()
class UserAchievement {
  final String id;

  @JsonKey(name: 'achievement_id')
  final String achievementId;

  @JsonKey(name: 'earned_at')
  final DateTime earnedAt;

  final Map<String, dynamic>? context;
  final bool notified;
  final Achievement achievement;

  UserAchievement({
    required this.id,
    required this.achievementId,
    required this.earnedAt,
    this.context,
    required this.notified,
    required this.achievement,
  });

  factory UserAchievement.fromJson(Map<String, dynamic> json) =>
      _$UserAchievementFromJson(json);
  Map<String, dynamic> toJson() => _$UserAchievementToJson(this);
}

/// Achievement with progress
@JsonSerializable()
class AchievementProgress {
  final Achievement achievement;
  final bool earned;

  @JsonKey(name: 'earned_at')
  final DateTime? earnedAt;

  @JsonKey(name: 'current_progress')
  final int currentProgress;

  @JsonKey(name: 'progress_percentage')
  final double progressPercentage;

  AchievementProgress({
    required this.achievement,
    required this.earned,
    this.earnedAt,
    required this.currentProgress,
    required this.progressPercentage,
  });

  factory AchievementProgress.fromJson(Map<String, dynamic> json) =>
      _$AchievementProgressFromJson(json);
  Map<String, dynamic> toJson() => _$AchievementProgressToJson(this);
}

/// Complete gamification stats
@JsonSerializable()
class GamificationStats {
  final UserStreak streak;

  @JsonKey(name: 'total_points')
  final int totalPoints;

  @JsonKey(name: 'achievements_earned')
  final int achievementsEarned;

  @JsonKey(name: 'achievements_total')
  final int achievementsTotal;

  @JsonKey(name: 'recent_achievements')
  final List<UserAchievement> recentAchievements;

  GamificationStats({
    required this.streak,
    required this.totalPoints,
    required this.achievementsEarned,
    required this.achievementsTotal,
    required this.recentAchievements,
  });

  factory GamificationStats.fromJson(Map<String, dynamic> json) =>
      _$GamificationStatsFromJson(json);
  Map<String, dynamic> toJson() => _$GamificationStatsToJson(this);

  /// Progress towards next achievement level
  double get achievementProgress =>
      achievementsTotal > 0 ? achievementsEarned / achievementsTotal : 0;
}

/// New achievement notification
@JsonSerializable()
class NewAchievementNotification {
  final Achievement achievement;

  @JsonKey(name: 'earned_at')
  final DateTime earnedAt;

  final Map<String, dynamic>? context;

  NewAchievementNotification({
    required this.achievement,
    required this.earnedAt,
    this.context,
  });

  factory NewAchievementNotification.fromJson(Map<String, dynamic> json) =>
      _$NewAchievementNotificationFromJson(json);
  Map<String, dynamic> toJson() => _$NewAchievementNotificationToJson(this);
}
