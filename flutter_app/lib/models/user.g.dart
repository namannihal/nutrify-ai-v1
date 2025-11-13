// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: json['id'] as String,
  email: json['email'] as String,
  name: json['name'] as String,
  avatar: json['avatar'] as String?,
  subscriptionTier: json['subscription_tier'] as String,
  createdAt: json['created_at'] as String,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'name': instance.name,
  'avatar': instance.avatar,
  'subscription_tier': instance.subscriptionTier,
  'created_at': instance.createdAt,
};

UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => UserProfile(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  age: (json['age'] as num?)?.toInt(),
  gender: json['gender'] as String?,
  height: (json['height'] as num?)?.toDouble(),
  weight: (json['weight'] as num?)?.toDouble(),
  activityLevel: json['activity_level'] as String?,
  goals: (json['goals'] as List<dynamic>?)?.map((e) => e as String).toList(),
  dietaryRestrictions: (json['dietary_restrictions'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  fitnessExperience: json['fitness_experience'] as String?,
  onboardingCompleted: json['onboarding_completed'] as bool?,
  createdAt: json['created_at'] as String?,
  updatedAt: json['updated_at'] as String?,
);

Map<String, dynamic> _$UserProfileToJson(UserProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'age': instance.age,
      'gender': instance.gender,
      'height': instance.height,
      'weight': instance.weight,
      'activity_level': instance.activityLevel,
      'goals': instance.goals,
      'dietary_restrictions': instance.dietaryRestrictions,
      'fitness_experience': instance.fitnessExperience,
      'onboarding_completed': instance.onboardingCompleted,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };

AuthResponse _$AuthResponseFromJson(Map<String, dynamic> json) => AuthResponse(
  user: User.fromJson(json['user'] as Map<String, dynamic>),
  token: json['token'] as String,
  refreshToken: json['refresh_token'] as String,
  tokenType: json['token_type'] as String,
);

Map<String, dynamic> _$AuthResponseToJson(AuthResponse instance) =>
    <String, dynamic>{
      'user': instance.user,
      'token': instance.token,
      'refresh_token': instance.refreshToken,
      'token_type': instance.tokenType,
    };
