import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

@JsonSerializable()
class MessageEntity extends Equatable {
  const MessageEntity({
    required this.text,
    required this.isMe,
    required this.timestamp,
  });

  factory MessageEntity.fromMap(Map<String, dynamic> map) {
    return MessageEntity(
      text: map['text'] as String,
      isMe: map['isMe'] as bool,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
    );
  }

  factory MessageEntity.fromJson(String source) =>
      MessageEntity.fromMap(json.decode(source) as Map<String, dynamic>);
  final String text;
  final bool isMe;
  final DateTime timestamp;

  MessageEntity copyWith({String? text, bool? isMe, DateTime? timestamp}) {
    return MessageEntity(
      text: text ?? this.text,
      isMe: isMe ?? this.isMe,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'text': text,
      'isMe': isMe,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() =>
      'MessageEntity(text: $text, isMe: $isMe, timestamp: $timestamp)';

  @override
  bool operator ==(covariant MessageEntity other) {
    if (identical(this, other)) return true;

    return other.text == text &&
        other.isMe == isMe &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode => text.hashCode ^ isMe.hashCode ^ timestamp.hashCode;

  @override
  List<Object?> get props => [text, isMe, timestamp];
}
