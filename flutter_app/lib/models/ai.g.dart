// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AIInsight _$AIInsightFromJson(Map<String, dynamic> json) => AIInsight(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  insightType: json['insight_type'] as String,
  title: json['title'] as String,
  message: json['message'] as String,
  explanation: json['explanation'] as String,
  actionItems: (json['action_items'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  priority: json['priority'] as String,
  isRead: json['is_read'] as bool,
  isDismissed: json['is_dismissed'] as bool,
  aiModelUsed: json['ai_model_used'] as String?,
  confidenceScore: (json['confidence_score'] as num?)?.toDouble(),
  createdAt: json['created_at'] as String,
);

Map<String, dynamic> _$AIInsightToJson(AIInsight instance) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'insight_type': instance.insightType,
  'title': instance.title,
  'message': instance.message,
  'explanation': instance.explanation,
  'action_items': instance.actionItems,
  'priority': instance.priority,
  'is_read': instance.isRead,
  'is_dismissed': instance.isDismissed,
  'ai_model_used': instance.aiModelUsed,
  'confidence_score': instance.confidenceScore,
  'created_at': instance.createdAt,
};

ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) => ChatMessage(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  messageType: json['message_type'] as String,
  content: json['content'] as String,
  category: json['category'] as String?,
  explanation: json['explanation'] as String?,
  suggestions: json['suggestions'] as Map<String, dynamic>?,
  createdAt: json['created_at'] as String,
);

Map<String, dynamic> _$ChatMessageToJson(ChatMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'message_type': instance.messageType,
      'content': instance.content,
      'category': instance.category,
      'explanation': instance.explanation,
      'suggestions': instance.suggestions,
      'created_at': instance.createdAt,
    };

ChatResponse _$ChatResponseFromJson(Map<String, dynamic> json) => ChatResponse(
  response: json['response'] as String,
  explanation: json['explanation'] as String?,
);

Map<String, dynamic> _$ChatResponseToJson(ChatResponse instance) =>
    <String, dynamic>{
      'response': instance.response,
      'explanation': instance.explanation,
    };
