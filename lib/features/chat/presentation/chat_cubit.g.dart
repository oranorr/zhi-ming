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
          ?.map((e) => MessageEntity.fromJson(jsonEncode(e)))
          .toList() ??
      const [],
  currentInput: json['currentInput'] as String? ?? '',
  loadingMessageIndex: json['loadingMessageIndex'] as int? ?? -1,
);

Map<String, dynamic> _$ChatStateToJson(ChatState instance) => <String, dynamic>{
  'isButtonAvailable': instance.isButtonAvailable,
  'isSendAvailable': instance.isSendAvailable,
  'isLoading': instance.isLoading,
  'messages': instance.messages.map((e) => jsonDecode(e.toJson())).toList(),
  'currentInput': instance.currentInput,
  'loadingMessageIndex': instance.loadingMessageIndex,
};
