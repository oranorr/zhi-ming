import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:zhi_ming/features/iching/models/hexagram.dart';

@JsonSerializable()
class MessageEntity extends Equatable {
  const MessageEntity({
    required this.text,
    required this.isMe,
    required this.timestamp,
    this.hexagrams,
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
    );
  }

  factory MessageEntity.fromJson(String source) =>
      MessageEntity.fromMap(json.decode(source) as Map<String, dynamic>);
  final String text;
  final bool isMe;
  final DateTime timestamp;

  // Список гексаграмм для отображения в сообщении (если сообщение содержит результат гадания)
  final List<Hexagram>? hexagrams;

  MessageEntity copyWith({
    String? text,
    bool? isMe,
    DateTime? timestamp,
    List<Hexagram>? hexagrams,
  }) {
    return MessageEntity(
      text: text ?? this.text,
      isMe: isMe ?? this.isMe,
      timestamp: timestamp ?? this.timestamp,
      hexagrams: hexagrams ?? this.hexagrams,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{
      'text': text,
      'isMe': isMe,
      'timestamp': timestamp.millisecondsSinceEpoch,
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

    return result;
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() =>
      'MessageEntity(text: $text, isMe: $isMe, timestamp: $timestamp, hexagrams: ${hexagrams?.length ?? 0})';

  @override
  bool operator ==(covariant MessageEntity other) {
    if (identical(this, other)) return true;

    return other.text == text &&
        other.isMe == isMe &&
        other.timestamp == timestamp &&
        (hexagrams == null && other.hexagrams == null ||
            hexagrams != null &&
                other.hexagrams != null &&
                hexagrams!.length == other.hexagrams!.length);
  }

  @override
  int get hashCode =>
      text.hashCode ^
      isMe.hashCode ^
      timestamp.hashCode ^
      (hexagrams?.length.hashCode ?? 0);

  @override
  List<Object?> get props => [text, isMe, timestamp, hexagrams];
}
