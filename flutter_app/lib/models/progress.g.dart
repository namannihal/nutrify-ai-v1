// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProgressEntry _$ProgressEntryFromJson(Map<String, dynamic> json) =>
    ProgressEntry(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      entryDate: json['entry_date'] as String,
      weight: (json['weight'] as num?)?.toDouble(),
      bodyFatPercentage: (json['body_fat_percentage'] as num?)?.toDouble(),
      muscleMass: (json['muscle_mass'] as num?)?.toDouble(),
      measurements: json['measurements'] as Map<String, dynamic>?,
      moodScore: (json['mood_score'] as num?)?.toInt(),
      energyScore: (json['energy_score'] as num?)?.toInt(),
      stressScore: (json['stress_score'] as num?)?.toInt(),
      sleepHours: (json['sleep_hours'] as num?)?.toDouble(),
      sleepQuality: (json['sleep_quality'] as num?)?.toInt(),
      waterIntakeMl: (json['water_intake_ml'] as num?)?.toInt(),
      adherenceScore: (json['adherence_score'] as num?)?.toInt(),
      notes: json['notes'] as String?,
      photos: json['photos'] as Map<String, dynamic>?,
      createdAt: json['created_at'] as String,
    );

Map<String, dynamic> _$ProgressEntryToJson(ProgressEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'entry_date': instance.entryDate,
      'weight': instance.weight,
      'body_fat_percentage': instance.bodyFatPercentage,
      'muscle_mass': instance.muscleMass,
      'measurements': instance.measurements,
      'mood_score': instance.moodScore,
      'energy_score': instance.energyScore,
      'stress_score': instance.stressScore,
      'sleep_hours': instance.sleepHours,
      'sleep_quality': instance.sleepQuality,
      'water_intake_ml': instance.waterIntakeMl,
      'adherence_score': instance.adherenceScore,
      'notes': instance.notes,
      'photos': instance.photos,
      'created_at': instance.createdAt,
    };

ProgressEntryCreate _$ProgressEntryCreateFromJson(Map<String, dynamic> json) =>
    ProgressEntryCreate(
      entryDate: json['entry_date'] as String,
      weight: (json['weight'] as num?)?.toDouble(),
      bodyFatPercentage: (json['body_fat_percentage'] as num?)?.toDouble(),
      muscleMass: (json['muscle_mass'] as num?)?.toDouble(),
      measurements: json['measurements'] as Map<String, dynamic>?,
      moodScore: (json['mood_score'] as num?)?.toInt(),
      energyScore: (json['energy_score'] as num?)?.toInt(),
      stressScore: (json['stress_score'] as num?)?.toInt(),
      sleepHours: (json['sleep_hours'] as num?)?.toDouble(),
      sleepQuality: (json['sleep_quality'] as num?)?.toInt(),
      waterIntakeMl: (json['water_intake_ml'] as num?)?.toInt(),
      adherenceScore: (json['adherence_score'] as num?)?.toInt(),
      notes: json['notes'] as String?,
      photos: json['photos'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$ProgressEntryCreateToJson(
  ProgressEntryCreate instance,
) => <String, dynamic>{
  'entry_date': instance.entryDate,
  'weight': instance.weight,
  'body_fat_percentage': instance.bodyFatPercentage,
  'muscle_mass': instance.muscleMass,
  'measurements': instance.measurements,
  'mood_score': instance.moodScore,
  'energy_score': instance.energyScore,
  'stress_score': instance.stressScore,
  'sleep_hours': instance.sleepHours,
  'sleep_quality': instance.sleepQuality,
  'water_intake_ml': instance.waterIntakeMl,
  'adherence_score': instance.adherenceScore,
  'notes': instance.notes,
  'photos': instance.photos,
};
