// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_cubit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatState _$ChatStateFromJson(Map<String, dynamic> json) => ChatState(
  isButtonAvailable: json['isButtonAvailable'] as bool? ?? false,
  isSendAvailable: json['isSendAvailable'] as bool? ?? false,
  isLoading: json['isLoading'] as bool? ?? false,
  messages:
      (json['messages'] as List<dynamic>?)
          ?.map((e) => MessageEntity.fromJson(e as String))
          .toList() ??
      const [],
  currentInput: json['currentInput'] as String? ?? '',
  loadingMessageIndex: (json['loadingMessageIndex'] as num?)?.toInt() ?? -1,
  lastHexagramContext:
      json['lastHexagramContext'] == null
          ? null
          : HexagramContext.fromJson(
            json['lastHexagramContext'] as Map<String, dynamic>,
          ),
);

Map<String, dynamic> _$ChatStateToJson(ChatState instance) => <String, dynamic>{
  'isButtonAvailable': instance.isButtonAvailable,
  'isSendAvailable': instance.isSendAvailable,
  'isLoading': instance.isLoading,
  'messages': instance.messages,
  'currentInput': instance.currentInput,
  'loadingMessageIndex': instance.loadingMessageIndex,
  'lastHexagramContext': instance.lastHexagramContext,
};

HexagramContext _$HexagramContextFromJson(Map<String, dynamic> json) =>
    HexagramContext(
      originalQuestion: json['originalQuestion'] as String,
      primaryHexagram: Hexagram.fromJson(
        json['primaryHexagram'] as Map<String, dynamic>,
      ),
      interpretation: json['interpretation'] as String,
      secondaryHexagram:
          json['secondaryHexagram'] == null
              ? null
              : Hexagram.fromJson(
                json['secondaryHexagram'] as Map<String, dynamic>,
              ),
    );

Map<String, dynamic> _$HexagramContextToJson(HexagramContext instance) =>
    <String, dynamic>{
      'originalQuestion': instance.originalQuestion,
      'primaryHexagram': instance.primaryHexagram,
      'secondaryHexagram': instance.secondaryHexagram,
      'interpretation': instance.interpretation,
    };
