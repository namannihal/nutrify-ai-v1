import 'package:json_annotation/json_annotation.dart';

part 'progress.g.dart';

@JsonSerializable()
class ProgressEntry {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'entry_date')
  final String entryDate;
  final double? weight;
  @JsonKey(name: 'body_fat_percentage')
  final double? bodyFatPercentage;
  @JsonKey(name: 'muscle_mass')
  final double? muscleMass;
  final Map<String, dynamic>? measurements;
  @JsonKey(name: 'mood_score')
  final int? moodScore;
  @JsonKey(name: 'energy_score')
  final int? energyScore;
  @JsonKey(name: 'stress_score')
  final int? stressScore;
  @JsonKey(name: 'sleep_hours')
  final double? sleepHours;
  @JsonKey(name: 'sleep_quality')
  final int? sleepQuality;
  @JsonKey(name: 'water_intake_ml')
  final int? waterIntakeMl;
  @JsonKey(name: 'adherence_score')
  final int? adherenceScore;
  final String? notes;
  final Map<String, dynamic>? photos;
  @JsonKey(name: 'created_at')
  final String createdAt;

  ProgressEntry({
    required this.id,
    required this.userId,
    required this.entryDate,
    this.weight,
    this.bodyFatPercentage,
    this.muscleMass,
    this.measurements,
    this.moodScore,
    this.energyScore,
    this.stressScore,
    this.sleepHours,
    this.sleepQuality,
    this.waterIntakeMl,
    this.adherenceScore,
    this.notes,
    this.photos,
    required this.createdAt,
  });

  factory ProgressEntry.fromJson(Map<String, dynamic> json) => _$ProgressEntryFromJson(json);
  Map<String, dynamic> toJson() => _$ProgressEntryToJson(this);
}

@JsonSerializable()
class ProgressEntryCreate {
  @JsonKey(name: 'entry_date')
  final String entryDate;
  final double? weight;
  @JsonKey(name: 'body_fat_percentage')
  final double? bodyFatPercentage;
  @JsonKey(name: 'muscle_mass')
  final double? muscleMass;
  final Map<String, dynamic>? measurements;
  @JsonKey(name: 'mood_score')
  final int? moodScore;
  @JsonKey(name: 'energy_score')
  final int? energyScore;
  @JsonKey(name: 'stress_score')
  final int? stressScore;
  @JsonKey(name: 'sleep_hours')
  final double? sleepHours;
  @JsonKey(name: 'sleep_quality')
  final int? sleepQuality;
  @JsonKey(name: 'water_intake_ml')
  final int? waterIntakeMl;
  @JsonKey(name: 'adherence_score')
  final int? adherenceScore;
  final String? notes;
  final Map<String, dynamic>? photos;

  ProgressEntryCreate({
    required this.entryDate,
    this.weight,
    this.bodyFatPercentage,
    this.muscleMass,
    this.measurements,
    this.moodScore,
    this.energyScore,
    this.stressScore,
    this.sleepHours,
    this.sleepQuality,
    this.waterIntakeMl,
    this.adherenceScore,
    this.notes,
    this.photos,
  });

  factory ProgressEntryCreate.fromJson(Map<String, dynamic> json) => _$ProgressEntryCreateFromJson(json);
  Map<String, dynamic> toJson() => _$ProgressEntryCreateToJson(this);
}