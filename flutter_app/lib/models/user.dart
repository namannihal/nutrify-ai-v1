import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final String id;
  final String email;
  final String name;
  final String? avatar;
  @JsonKey(name: 'subscription_tier')
  final String subscriptionTier;
  @JsonKey(name: 'created_at')
  final String createdAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.avatar,
    required this.subscriptionTier,
    required this.createdAt,
  });

  // Convenience getters for first and last name
  String get firstName {
    final names = name.split(' ');
    return names.isNotEmpty ? names.first : '';
  }

  String get lastName {
    final names = name.split(' ');
    return names.length > 1 ? names.sublist(1).join(' ') : '';
  }

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}

@JsonSerializable()
class UserProfile {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  final int? age;
  final String? gender;
  final double? height; // cm
  final double? weight; // kg
  @JsonKey(name: 'activity_level')
  final String? activityLevel;
  final List<String>? goals;
  @JsonKey(name: 'dietary_restrictions')
  final List<String>? dietaryRestrictions;
  @JsonKey(name: 'fitness_experience')
  final String? fitnessExperience;
  @JsonKey(name: 'onboarding_completed')
  final bool? onboardingCompleted;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  UserProfile({
    required this.id,
    required this.userId,
    this.age,
    this.gender,
    this.height,
    this.weight,
    this.activityLevel,
    this.goals,
    this.dietaryRestrictions,
    this.fitnessExperience,
    this.onboardingCompleted,
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => _$UserProfileFromJson(json);
  Map<String, dynamic> toJson() => _$UserProfileToJson(this);
}

@JsonSerializable()
class AuthResponse {
  final User user;
  final String token;
  @JsonKey(name: 'refresh_token')
  final String refreshToken;
  @JsonKey(name: 'token_type')
  final String tokenType;

  AuthResponse({
    required this.user,
    required this.token,
    required this.refreshToken,
    required this.tokenType,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => _$AuthResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}