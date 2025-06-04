import 'package:zhi_ming/features/history/domain/chat_history_entity.dart';

abstract class ChatEntrypointEntity {
  String? get predefinedQuestion;

  /// Проверяет, является ли этот entrypoint режимом только чтения
  bool get isReadOnlyMode => false;
}

class IzinEntrypointEntity extends ChatEntrypointEntity {
  IzinEntrypointEntity() : super();

  @override
  String? get predefinedQuestion => null;
}

class CardEntrypointEntity extends ChatEntrypointEntity {
  CardEntrypointEntity({String? predefinedQuestion})
    : _predefinedQuestion = predefinedQuestion,
      super();
  final String? _predefinedQuestion;

  @override
  String? get predefinedQuestion => _predefinedQuestion;
}

class BazsuEntrypointEntity extends ChatEntrypointEntity {
  BazsuEntrypointEntity() : super();

  @override
  String? get predefinedQuestion => null;
}

class OnboardingEntrypointEntity extends ChatEntrypointEntity {
  OnboardingEntrypointEntity() : super();

  @override
  String? get predefinedQuestion => null;
}

/// Entrypoint для открытия чата из истории в режиме только чтения
/// Содержит полные данные чата для отображения без возможности редактирования
class HistoryEntrypointEntity extends ChatEntrypointEntity {
  HistoryEntrypointEntity({required this.chatHistory}) : super();

  /// Данные чата из истории
  final ChatHistoryEntity chatHistory;

  @override
  String? get predefinedQuestion => null;

  @override
  bool get isReadOnlyMode => true;
}
