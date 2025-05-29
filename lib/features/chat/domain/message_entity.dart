// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'package:zhi_ming/features/iching/models/hexagram.dart';

part 'message_entity.g.dart';

// Новые модели для структурированной интерпретации
@JsonSerializable()
class InterpretationSummary extends Equatable {
  const InterpretationSummary({
    required this.potentialPositive,
    required this.potentialNegative,
    required this.keyAdvice,
  });

  factory InterpretationSummary.fromJson(Map<String, dynamic> json) =>
      InterpretationSummary(
        potentialPositive: json['potential_positive'] as String,
        potentialNegative: json['potential_negative'] as String,
        keyAdvice:
            (json['key_advice'] as List<dynamic>)
                .map((e) => e as String)
                .toList(),
      );

  final String potentialPositive;
  final String potentialNegative;
  final List<String> keyAdvice;

  Map<String, dynamic> toJson() => {
    'potential_positive': potentialPositive,
    'potential_negative': potentialNegative,
    'key_advice': keyAdvice,
  };

  @override
  List<Object?> get props => [potentialPositive, potentialNegative, keyAdvice];
}

@JsonSerializable()
class HexagramInterpretation extends Equatable {
  const HexagramInterpretation({required this.summary, required this.details});

  factory HexagramInterpretation.fromJson(Map<String, dynamic> json) =>
      HexagramInterpretation(
        summary: InterpretationSummary.fromJson(
          json['summary'] as Map<String, dynamic>,
        ),
        details: json['details'] as String,
      );

  final InterpretationSummary summary;
  final String details;

  Map<String, dynamic> toJson() => {
    'summary': summary.toJson(),
    'details': details,
  };

  @override
  List<Object?> get props => [summary, details];
}

@JsonSerializable()
class SimpleInterpretation extends Equatable {
  const SimpleInterpretation({
    required this.answer,
    required this.interpretationSummary,
    required this.detailedInterpretation,
  });

  factory SimpleInterpretation.fromJson(Map<String, dynamic> json) =>
      SimpleInterpretation(
        answer: json['answer'] as String,
        interpretationSummary: InterpretationSummary.fromJson(
          json['interpretation_summary'] as Map<String, dynamic>,
        ),
        detailedInterpretation: json['detailed_interpretation'] as String,
      );

  final String answer;
  final InterpretationSummary interpretationSummary;
  final String detailedInterpretation;

  Map<String, dynamic> toJson() => {
    'answer': answer,
    'interpretation_summary': interpretationSummary.toJson(),
    'detailed_interpretation': detailedInterpretation,
  };

  @override
  List<Object?> get props => [
    answer,
    interpretationSummary,
    detailedInterpretation,
  ];
}

@JsonSerializable()
class ComplexInterpretation extends Equatable {
  const ComplexInterpretation({
    required this.answer,
    required this.interpretationPrimary,
    required this.interpretationSecondary,
    required this.interpretationChangingLines,
    required this.overallGuidance,
  });

  factory ComplexInterpretation.fromJson(Map<String, dynamic> json) =>
      ComplexInterpretation(
        answer: json['answer'] as String,
        interpretationPrimary: HexagramInterpretation.fromJson(
          json['interpretation_primary'] as Map<String, dynamic>,
        ),
        interpretationSecondary: HexagramInterpretation.fromJson(
          json['interpretation_secondary'] as Map<String, dynamic>,
        ),
        interpretationChangingLines:
            json['interpretation_changing_lines'] as String,
        overallGuidance: json['overall_guidance'] as String,
      );

  final String answer;
  final HexagramInterpretation interpretationPrimary;
  final HexagramInterpretation interpretationSecondary;
  final String interpretationChangingLines;
  final String overallGuidance;

  Map<String, dynamic> toJson() => {
    'answer': answer,
    'interpretation_primary': interpretationPrimary.toJson(),
    'interpretation_secondary': interpretationSecondary.toJson(),
    'interpretation_changing_lines': interpretationChangingLines,
    'overall_guidance': overallGuidance,
  };

  @override
  List<Object?> get props => [
    answer,
    interpretationPrimary,
    interpretationSecondary,
    interpretationChangingLines,
    overallGuidance,
  ];
}

@JsonSerializable()
class MessageEntity extends Equatable {
  const MessageEntity({
    required this.text,
    required this.isMe,
    required this.timestamp,
    this.hexagrams,
    this.simpleInterpretation, // Для простого гадания (одна гексаграмма)
    this.complexInterpretation, // Для сложного гадания (две гексаграммы)
    this.isStreaming = false, // Флаг для отображения streaming эффекта
  });

  factory MessageEntity.fromMap(Map<String, dynamic> map) {
    return MessageEntity(
      text: map['text'] as String,
      isMe: map['isMe'] as bool,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      hexagrams:
          map['hexagrams'] != null
              ? (json.decode(map['hexagrams']) as List)
                  .map(
                    (h) => Hexagram(
                      lines:
                          (h['lines'] as List)
                              .map((l) => Line(l as int))
                              .toList(),
                      name: h['name'] as String?,
                      description: h['description'] as String?,
                      number: h['number'] as int?,
                    ),
                  )
                  .toList()
              : null,
      simpleInterpretation:
          map['simpleInterpretation'] != null
              ? SimpleInterpretation.fromJson(
                json.decode(map['simpleInterpretation'])
                    as Map<String, dynamic>,
              )
              : null,
      complexInterpretation:
          map['complexInterpretation'] != null
              ? ComplexInterpretation.fromJson(
                json.decode(map['complexInterpretation'])
                    as Map<String, dynamic>,
              )
              : null,
      isStreaming: map['isStreaming'] as bool? ?? false,
    );
  }

  factory MessageEntity.fromJson(String source) =>
      MessageEntity.fromMap(json.decode(source) as Map<String, dynamic>);

  final String text;
  final bool isMe;
  final DateTime timestamp;

  // Список гексаграмм для отображения в сообщении (если сообщение содержит результат гадания)
  final List<Hexagram>? hexagrams;

  // Структурированные интерпретации
  final SimpleInterpretation? simpleInterpretation;
  final ComplexInterpretation? complexInterpretation;

  // Флаг для эффекта streaming
  final bool isStreaming;

  MessageEntity copyWith({
    String? text,
    bool? isMe,
    DateTime? timestamp,
    List<Hexagram>? hexagrams,
    SimpleInterpretation? simpleInterpretation,
    ComplexInterpretation? complexInterpretation,
    bool? isStreaming,
  }) {
    return MessageEntity(
      text: text ?? this.text,
      isMe: isMe ?? this.isMe,
      timestamp: timestamp ?? this.timestamp,
      hexagrams: hexagrams ?? this.hexagrams,
      simpleInterpretation: simpleInterpretation ?? this.simpleInterpretation,
      complexInterpretation:
          complexInterpretation ?? this.complexInterpretation,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{
      'text': text,
      'isMe': isMe,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isStreaming': isStreaming,
    };

    if (hexagrams != null) {
      result['hexagrams'] = json.encode(
        hexagrams!
            .map(
              (h) => {
                'lines': h.lines.map((l) => l.value).toList(),
                'name': h.name,
                'description': h.description,
                'number': h.number,
              },
            )
            .toList(),
      );
    }

    if (simpleInterpretation != null) {
      result['simpleInterpretation'] = json.encode(
        simpleInterpretation!.toJson(),
      );
    }

    if (complexInterpretation != null) {
      result['complexInterpretation'] = json.encode(
        complexInterpretation!.toJson(),
      );
    }

    return result;
  }

  String toJson() => json.encode(toMap());

  @override
  bool operator ==(covariant MessageEntity other) {
    if (identical(this, other)) return true;

    return other.text == text &&
        other.isMe == isMe &&
        other.timestamp == timestamp &&
        other.isStreaming == isStreaming &&
        (hexagrams == null && other.hexagrams == null ||
            hexagrams != null &&
                other.hexagrams != null &&
                hexagrams!.length == other.hexagrams!.length) &&
        other.simpleInterpretation == simpleInterpretation &&
        other.complexInterpretation == complexInterpretation;
  }

  @override
  int get hashCode =>
      text.hashCode ^
      isMe.hashCode ^
      timestamp.hashCode ^
      isStreaming.hashCode ^
      (hexagrams?.length.hashCode ?? 0) ^
      (simpleInterpretation?.hashCode ?? 0) ^
      (complexInterpretation?.hashCode ?? 0);

  @override
  List<Object?> get props => [
    text,
    isMe,
    timestamp,
    hexagrams,
    simpleInterpretation,
    complexInterpretation,
    isStreaming,
  ];

  @override
  String toString() {
    return 'MessageEntity(text: $text, isMe: $isMe, timestamp: $timestamp, hexagrams: ${hexagrams?.length ?? 0}, isStreaming: $isStreaming, simpleInterpretation: $simpleInterpretation, complexInterpretation: $complexInterpretation)';
  }
}
