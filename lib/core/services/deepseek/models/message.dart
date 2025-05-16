import 'dart:convert';
import 'package:equatable/equatable.dart';

/// Класс для представления сообщения в чате DeepSeek
class DeepSeekMessage extends Equatable {
  /// Конструктор сообщения
  const DeepSeekMessage({required this.role, required this.content, this.name});

  /// Создание сообщения из JSON карты
  factory DeepSeekMessage.fromMap(Map<String, dynamic> map) {
    return DeepSeekMessage(
      role: map['role'] as String,
      content: map['content'] as String,
      name: map['name'] as String?,
    );
  }

  /// Создание сообщения из JSON строки
  factory DeepSeekMessage.fromJson(String source) =>
      DeepSeekMessage.fromMap(json.decode(source) as Map<String, dynamic>);

  /// Роль отправителя сообщения (system, user, assistant)
  final String role;

  /// Содержимое сообщения
  final String content;

  /// Имя отправителя (опционально)
  final String? name;

  /// Конвертация сообщения в JSON карту
  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{'role': role, 'content': content};

    if (name != null) {
      result['name'] = name;
    }

    return result;
  }

  /// Конвертация сообщения в JSON строку
  String toJson() => json.encode(toMap());

  /// Создание копии сообщения с новыми значениями
  DeepSeekMessage copyWith({String? role, String? content, String? name}) {
    return DeepSeekMessage(
      role: role ?? this.role,
      content: content ?? this.content,
      name: name ?? this.name,
    );
  }

  @override
  String toString() =>
      'DeepSeekMessage(role: $role, content: $content, name: $name)';

  @override
  List<Object?> get props => [role, content, name];

  /// Фабричный метод для создания системного сообщения
  static DeepSeekMessage system(String content) {
    return DeepSeekMessage(role: 'system', content: content);
  }

  /// Фабричный метод для создания пользовательского сообщения
  static DeepSeekMessage user(String content) {
    return DeepSeekMessage(role: 'user', content: content);
  }

  /// Фабричный метод для создания сообщения ассистента
  static DeepSeekMessage assistant(String content) {
    return DeepSeekMessage(role: 'assistant', content: content);
  }
}
