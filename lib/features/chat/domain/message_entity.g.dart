// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InterpretationSummary _$InterpretationSummaryFromJson(
  Map<String, dynamic> json,
) => InterpretationSummary(
  potentialPositive: json['potentialPositive'] as String,
  potentialNegative: json['potentialNegative'] as String,
  keyAdvice:
      (json['keyAdvice'] as List<dynamic>).map((e) => e as String).toList(),
);

Map<String, dynamic> _$InterpretationSummaryToJson(
  InterpretationSummary instance,
) => <String, dynamic>{
  'potentialPositive': instance.potentialPositive,
  'potentialNegative': instance.potentialNegative,
  'keyAdvice': instance.keyAdvice,
};

HexagramInterpretation _$HexagramInterpretationFromJson(
  Map<String, dynamic> json,
) => HexagramInterpretation(
  summary: InterpretationSummary.fromJson(
    json['summary'] as Map<String, dynamic>,
  ),
  details: json['details'] as String,
);

Map<String, dynamic> _$HexagramInterpretationToJson(
  HexagramInterpretation instance,
) => <String, dynamic>{
  'summary': instance.summary,
  'details': instance.details,
};

SimpleInterpretation _$SimpleInterpretationFromJson(
  Map<String, dynamic> json,
) => SimpleInterpretation(
  answer: json['answer'] as String,
  interpretationSummary: InterpretationSummary.fromJson(
    json['interpretationSummary'] as Map<String, dynamic>,
  ),
  detailedInterpretation: json['detailedInterpretation'] as String,
);

Map<String, dynamic> _$SimpleInterpretationToJson(
  SimpleInterpretation instance,
) => <String, dynamic>{
  'answer': instance.answer,
  'interpretationSummary': instance.interpretationSummary,
  'detailedInterpretation': instance.detailedInterpretation,
};

ComplexInterpretation _$ComplexInterpretationFromJson(
  Map<String, dynamic> json,
) => ComplexInterpretation(
  answer: json['answer'] as String,
  interpretationPrimary: HexagramInterpretation.fromJson(
    json['interpretationPrimary'] as Map<String, dynamic>,
  ),
  interpretationSecondary: HexagramInterpretation.fromJson(
    json['interpretationSecondary'] as Map<String, dynamic>,
  ),
  interpretationChangingLines: json['interpretationChangingLines'] as String,
  overallGuidance: json['overallGuidance'] as String,
);

Map<String, dynamic> _$ComplexInterpretationToJson(
  ComplexInterpretation instance,
) => <String, dynamic>{
  'answer': instance.answer,
  'interpretationPrimary': instance.interpretationPrimary,
  'interpretationSecondary': instance.interpretationSecondary,
  'interpretationChangingLines': instance.interpretationChangingLines,
  'overallGuidance': instance.overallGuidance,
};

MessageEntity _$MessageEntityFromJson(Map<String, dynamic> json) =>
    MessageEntity(
      text: json['text'] as String,
      isMe: json['isMe'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      hexagrams:
          (json['hexagrams'] as List<dynamic>?)
              ?.map((e) => Hexagram.fromJson(e as Map<String, dynamic>))
              .toList(),
      simpleInterpretation:
          json['simpleInterpretation'] == null
              ? null
              : SimpleInterpretation.fromJson(
                json['simpleInterpretation'] as Map<String, dynamic>,
              ),
      complexInterpretation:
          json['complexInterpretation'] == null
              ? null
              : ComplexInterpretation.fromJson(
                json['complexInterpretation'] as Map<String, dynamic>,
              ),
      isStreaming: json['isStreaming'] as bool? ?? false,
    );

Map<String, dynamic> _$MessageEntityToJson(MessageEntity instance) =>
    <String, dynamic>{
      'text': instance.text,
      'isMe': instance.isMe,
      'timestamp': instance.timestamp.toIso8601String(),
      'hexagrams': instance.hexagrams,
      'simpleInterpretation': instance.simpleInterpretation,
      'complexInterpretation': instance.complexInterpretation,
      'isStreaming': instance.isStreaming,
    };
