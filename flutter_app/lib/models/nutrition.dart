import 'package:json_annotation/json_annotation.dart';

part 'nutrition.g.dart';

@JsonSerializable()
class NutritionPlan {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'week_start')
  final String weekStart;
  @JsonKey(name: 'daily_calories')
  final int dailyCalories;
  final Map<String, dynamic> macros;
  final List<DailyMeal> meals;
  @JsonKey(name: 'created_by_ai')
  final bool createdByAi;
  @JsonKey(name: 'adaptation_reason')
  final String? adaptationReason;

  NutritionPlan({
    required this.id,
    required this.userId,
    required this.weekStart,
    required this.dailyCalories,
    required this.macros,
    required this.meals,
    required this.createdByAi,
    this.adaptationReason,
  });

  factory NutritionPlan.fromJson(Map<String, dynamic> json) => _$NutritionPlanFromJson(json);
  Map<String, dynamic> toJson() => _$NutritionPlanToJson(this);
}

@JsonSerializable()
class DailyMeal {
  final String day;
  final List<Meal> breakfast;
  final List<Meal> lunch;
  final List<Meal> dinner;
  final List<Meal> snacks;

  DailyMeal({
    required this.day,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.snacks,
  });

  factory DailyMeal.fromJson(Map<String, dynamic> json) => _$DailyMealFromJson(json);
  Map<String, dynamic> toJson() => _$DailyMealToJson(this);
}

@JsonSerializable()
class Meal {
  final String id;
  final String name;
  final String? description;
  final int calories;
  @JsonKey(name: 'protein_grams')
  final double proteinGrams;
  @JsonKey(name: 'carbs_grams')
  final double carbsGrams;
  @JsonKey(name: 'fat_grams')
  final double fatGrams;
  final Map<String, dynamic> ingredients;
  final String? instructions;
  @JsonKey(name: 'prep_time_minutes')
  final int? prepTimeMinutes;
  @JsonKey(name: 'cook_time_minutes')
  final int? cookTimeMinutes;

  Meal({
    required this.id,
    required this.name,
    this.description,
    required this.calories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    required this.ingredients,
    this.instructions,
    this.prepTimeMinutes,
    this.cookTimeMinutes,
  });

  factory Meal.fromJson(Map<String, dynamic> json) => _$MealFromJson(json);
  Map<String, dynamic> toJson() => _$MealToJson(this);
}