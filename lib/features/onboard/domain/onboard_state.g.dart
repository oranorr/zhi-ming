// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboard_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OnboardState _$OnboardStateFromJson(Map<String, dynamic> json) => OnboardState(
  isDatePickerVisible: json['isDatePickerVisible'] as bool? ?? false,
  messages:
      (json['messages'] as List<dynamic>?)
          ?.map((e) => MessageEntity.fromJson(e as String))
          .toList() ??
      const [],
  currentInput: json['currentInput'] as String? ?? '',
  currentQuestionIndex: (json['currentQuestionIndex'] as num?)?.toInt() ?? 0,
  birthDate:
      json['birthDate'] == null
          ? null
          : DateTime.parse(json['birthDate'] as String),
  birthTime: OnboardState._timeOfDayFromJson(
    json['birthTime'] as Map<String, dynamic>?,
  ),
  isCompleted: json['isCompleted'] as bool? ?? false,
  isLoading: json['isLoading'] as bool? ?? false,
);

Map<String, dynamic> _$OnboardStateToJson(OnboardState instance) =>
    <String, dynamic>{
      'isDatePickerVisible': instance.isDatePickerVisible,
      'messages': instance.messages,
      'currentInput': instance.currentInput,
      'currentQuestionIndex': instance.currentQuestionIndex,
      'birthDate': instance.birthDate?.toIso8601String(),
      'birthTime': OnboardState._timeOfDayToJson(instance.birthTime),
      'isCompleted': instance.isCompleted,
      'isLoading': instance.isLoading,
    };
