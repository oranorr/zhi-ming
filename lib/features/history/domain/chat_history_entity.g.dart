// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_history_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatHistoryEntity _$ChatHistoryEntityFromJson(Map<String, dynamic> json) =>
    ChatHistoryEntity(
      id: json['id'] as String,
      mainQuestion: json['mainQuestion'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      messages:
          (json['messages'] as List<dynamic>)
              .map((e) => MessageEntity.fromJson(e as String))
              .toList(),
      updatedAt:
          json['updatedAt'] == null
              ? null
              : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$ChatHistoryEntityToJson(ChatHistoryEntity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'mainQuestion': instance.mainQuestion,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'messages': instance.messages,
    };
