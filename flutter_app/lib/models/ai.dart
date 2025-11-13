import 'package:json_annotation/json_annotation.dart';

part 'ai.g.dart';

@JsonSerializable()
class AIInsight {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'insight_type')
  final String insightType;
  final String title;
  final String message;
  final String explanation;
  @JsonKey(name: 'action_items')
  final List<String>? actionItems;
  final String priority;
  @JsonKey(name: 'is_read')
  final bool isRead;
  @JsonKey(name: 'is_dismissed')
  final bool isDismissed;
  @JsonKey(name: 'ai_model_used')
  final String? aiModelUsed;
  @JsonKey(name: 'confidence_score')
  final double? confidenceScore;
  @JsonKey(name: 'created_at')
  final String createdAt;

  AIInsight({
    required this.id,
    required this.userId,
    required this.insightType,
    required this.title,
    required this.message,
    required this.explanation,
    this.actionItems,
    required this.priority,
    required this.isRead,
    required this.isDismissed,
    this.aiModelUsed,
    this.confidenceScore,
    required this.createdAt,
  });

  factory AIInsight.fromJson(Map<String, dynamic> json) => _$AIInsightFromJson(json);
  Map<String, dynamic> toJson() => _$AIInsightToJson(this);
}

@JsonSerializable()
class ChatMessage {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'message_type')
  final String messageType; // 'user' or 'assistant'
  final String content;
  final String? category;
  final String? explanation;
  final Map<String, dynamic>? suggestions;
  @JsonKey(name: 'created_at')
  final String createdAt;

  ChatMessage({
    required this.id,
    required this.userId,
    required this.messageType,
    required this.content,
    this.category,
    this.explanation,
    this.suggestions,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);
  Map<String, dynamic> toJson() => _$ChatMessageToJson(this);
}

@JsonSerializable()
class ChatResponse {
  final String response;
  final String? explanation;

  ChatResponse({
    required this.response,
    this.explanation,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) => _$ChatResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ChatResponseToJson(this);
}