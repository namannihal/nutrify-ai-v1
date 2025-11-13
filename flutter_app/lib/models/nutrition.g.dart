// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nutrition.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NutritionPlan _$NutritionPlanFromJson(Map<String, dynamic> json) =>
    NutritionPlan(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      weekStart: json['week_start'] as String,
      dailyCalories: (json['daily_calories'] as num).toInt(),
      macros: json['macros'] as Map<String, dynamic>,
      meals: (json['meals'] as List<dynamic>)
          .map((e) => DailyMeal.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdByAi: json['created_by_ai'] as bool,
      adaptationReason: json['adaptation_reason'] as String?,
    );

Map<String, dynamic> _$NutritionPlanToJson(NutritionPlan instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'week_start': instance.weekStart,
      'daily_calories': instance.dailyCalories,
      'macros': instance.macros,
      'meals': instance.meals,
      'created_by_ai': instance.createdByAi,
      'adaptation_reason': instance.adaptationReason,
    };

DailyMeal _$DailyMealFromJson(Map<String, dynamic> json) => DailyMeal(
  day: json['day'] as String,
  breakfast: (json['breakfast'] as List<dynamic>)
      .map((e) => Meal.fromJson(e as Map<String, dynamic>))
      .toList(),
  lunch: (json['lunch'] as List<dynamic>)
      .map((e) => Meal.fromJson(e as Map<String, dynamic>))
      .toList(),
  dinner: (json['dinner'] as List<dynamic>)
      .map((e) => Meal.fromJson(e as Map<String, dynamic>))
      .toList(),
  snacks: (json['snacks'] as List<dynamic>)
      .map((e) => Meal.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$DailyMealToJson(DailyMeal instance) => <String, dynamic>{
  'day': instance.day,
  'breakfast': instance.breakfast,
  'lunch': instance.lunch,
  'dinner': instance.dinner,
  'snacks': instance.snacks,
};

Meal _$MealFromJson(Map<String, dynamic> json) => Meal(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  calories: (json['calories'] as num).toInt(),
  proteinGrams: (json['protein_grams'] as num).toDouble(),
  carbsGrams: (json['carbs_grams'] as num).toDouble(),
  fatGrams: (json['fat_grams'] as num).toDouble(),
  ingredients: json['ingredients'] as Map<String, dynamic>,
  instructions: json['instructions'] as String?,
  prepTimeMinutes: (json['prep_time_minutes'] as num?)?.toInt(),
  cookTimeMinutes: (json['cook_time_minutes'] as num?)?.toInt(),
);

Map<String, dynamic> _$MealToJson(Meal instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'calories': instance.calories,
  'protein_grams': instance.proteinGrams,
  'carbs_grams': instance.carbsGrams,
  'fat_grams': instance.fatGrams,
  'ingredients': instance.ingredients,
  'instructions': instance.instructions,
  'prep_time_minutes': instance.prepTimeMinutes,
  'cook_time_minutes': instance.cookTimeMinutes,
};
