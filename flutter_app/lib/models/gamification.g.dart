// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gamification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserStreak _$UserStreakFromJson(Map<String, dynamic> json) => UserStreak(
  currentStreak: (json['current_streak'] as num).toInt(),
  longestStreak: (json['longest_streak'] as num).toInt(),
  lastWorkoutDate: json['last_workout_date'] as String?,
  streakStartDate: json['streak_start_date'] as String?,
  totalWorkouts: (json['total_workouts'] as num).toInt(),
  totalWorkoutMinutes: (json['total_workout_minutes'] as num).toInt(),
  currentWeekWorkouts: (json['current_week_workouts'] as num).toInt(),
  weekWorkoutDays: (json['week_workout_days'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$UserStreakToJson(UserStreak instance) =>
    <String, dynamic>{
      'current_streak': instance.currentStreak,
      'longest_streak': instance.longestStreak,
      'last_workout_date': instance.lastWorkoutDate,
      'streak_start_date': instance.streakStartDate,
      'total_workouts': instance.totalWorkouts,
      'total_workout_minutes': instance.totalWorkoutMinutes,
      'current_week_workouts': instance.currentWeekWorkouts,
      'week_workout_days': instance.weekWorkoutDays,
    };

Achievement _$AchievementFromJson(Map<String, dynamic> json) => Achievement(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  icon: json['icon'] as String,
  category: json['category'] as String,
  requirementType: json['requirement_type'] as String,
  requirementValue: (json['requirement_value'] as num).toInt(),
  points: (json['points'] as num).toInt(),
  rarity: json['rarity'] as String,
  sortOrder: (json['sort_order'] as num).toInt(),
);

Map<String, dynamic> _$AchievementToJson(Achievement instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'icon': instance.icon,
      'category': instance.category,
      'requirement_type': instance.requirementType,
      'requirement_value': instance.requirementValue,
      'points': instance.points,
      'rarity': instance.rarity,
      'sort_order': instance.sortOrder,
    };

UserAchievement _$UserAchievementFromJson(Map<String, dynamic> json) =>
    UserAchievement(
      id: json['id'] as String,
      achievementId: json['achievement_id'] as String,
      earnedAt: DateTime.parse(json['earned_at'] as String),
      context: json['context'] as Map<String, dynamic>?,
      notified: json['notified'] as bool,
      achievement: Achievement.fromJson(
        json['achievement'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$UserAchievementToJson(UserAchievement instance) =>
    <String, dynamic>{
      'id': instance.id,
      'achievement_id': instance.achievementId,
      'earned_at': instance.earnedAt.toIso8601String(),
      'context': instance.context,
      'notified': instance.notified,
      'achievement': instance.achievement,
    };

AchievementProgress _$AchievementProgressFromJson(Map<String, dynamic> json) =>
    AchievementProgress(
      achievement: Achievement.fromJson(
        json['achievement'] as Map<String, dynamic>,
      ),
      earned: json['earned'] as bool,
      earnedAt: json['earned_at'] == null
          ? null
          : DateTime.parse(json['earned_at'] as String),
      currentProgress: (json['current_progress'] as num).toInt(),
      progressPercentage: (json['progress_percentage'] as num).toDouble(),
    );

Map<String, dynamic> _$AchievementProgressToJson(
  AchievementProgress instance,
) => <String, dynamic>{
  'achievement': instance.achievement,
  'earned': instance.earned,
  'earned_at': instance.earnedAt?.toIso8601String(),
  'current_progress': instance.currentProgress,
  'progress_percentage': instance.progressPercentage,
};

GamificationStats _$GamificationStatsFromJson(Map<String, dynamic> json) =>
    GamificationStats(
      streak: UserStreak.fromJson(json['streak'] as Map<String, dynamic>),
      totalPoints: (json['total_points'] as num).toInt(),
      achievementsEarned: (json['achievements_earned'] as num).toInt(),
      achievementsTotal: (json['achievements_total'] as num).toInt(),
      recentAchievements: (json['recent_achievements'] as List<dynamic>)
          .map((e) => UserAchievement.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$GamificationStatsToJson(GamificationStats instance) =>
    <String, dynamic>{
      'streak': instance.streak,
      'total_points': instance.totalPoints,
      'achievements_earned': instance.achievementsEarned,
      'achievements_total': instance.achievementsTotal,
      'recent_achievements': instance.recentAchievements,
    };

NewAchievementNotification _$NewAchievementNotificationFromJson(
  Map<String, dynamic> json,
) => NewAchievementNotification(
  achievement: Achievement.fromJson(
    json['achievement'] as Map<String, dynamic>,
  ),
  earnedAt: DateTime.parse(json['earned_at'] as String),
  context: json['context'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$NewAchievementNotificationToJson(
  NewAchievementNotification instance,
) => <String, dynamic>{
  'achievement': instance.achievement,
  'earned_at': instance.earnedAt.toIso8601String(),
  'context': instance.context,
};
