import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:zhi_ming/features/chat/domain/message_entity.dart';

part 'chat_history_entity.g.dart';

/// Сущность для хранения истории отдельного чата
/// Содержит главный вопрос пользователя (заголовок),
/// дату создания и все сообщения в этом чате
@JsonSerializable()
class ChatHistoryEntity extends Equatable {
  const ChatHistoryEntity({
    required this.id,
    required this.mainQuestion,
    required this.createdAt,
    required this.messages,
    this.updatedAt,
  });

  factory ChatHistoryEntity.fromJson(Map<String, dynamic> json) =>
      _$ChatHistoryEntityFromJson(json);

  /// Уникальный идентификатор чата
  final String id;

  /// Главный вопрос пользователя, используется как заголовок
  final String mainQuestion;

  /// Дата и время создания чата
  final DateTime createdAt;

  /// Дата и время последнего обновления чата
  final DateTime? updatedAt;

  /// Все сообщения в этом чате (исключая сообщения с isStreaming = true)
  final List<MessageEntity> messages;

  Map<String, dynamic> toJson() => _$ChatHistoryEntityToJson(this);

  ChatHistoryEntity copyWith({
    String? id,
    String? mainQuestion,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<MessageEntity>? messages,
  }) {
    return ChatHistoryEntity(
      id: id ?? this.id,
      mainQuestion: mainQuestion ?? this.mainQuestion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
    );
  }

  @override
  List<Object?> get props => [id, mainQuestion, createdAt, updatedAt, messages];
}
