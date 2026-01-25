// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_library.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LibraryExercise _$LibraryExerciseFromJson(Map<String, dynamic> json) =>
    LibraryExercise(
      id: json['id'] as String,
      name: json['name'] as String,
      force: json['force'] as String?,
      level: json['level'] as String? ?? 'beginner',
      mechanic: json['mechanic'] as String?,
      equipment: json['equipment'] as String? ?? 'body only',
      category: json['category'] as String? ?? 'strength',
      primaryMuscles:
          (json['primaryMuscles'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      secondaryMuscles: (json['secondaryMuscles'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      instructions: (json['instructions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      images: (json['images'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$LibraryExerciseToJson(LibraryExercise instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'force': instance.force,
      'level': instance.level,
      'mechanic': instance.mechanic,
      'equipment': instance.equipment,
      'category': instance.category,
      'primaryMuscles': instance.primaryMuscles,
      'secondaryMuscles': instance.secondaryMuscles,
      'instructions': instance.instructions,
      'images': instance.images,
    };
