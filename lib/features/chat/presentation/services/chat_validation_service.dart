import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:zhi_ming/core/services/deepseek/deepseek_service.dart';
import 'package:zhi_ming/core/services/deepseek/models/message.dart';
import 'package:zhi_ming/features/chat/domain/message_entity.dart';
import 'package:zhi_ming/features/chat/presentation/models/chat_state.dart';

/// Сервис для валидации запросов пользователей
/// Отвечает за проверку корректности вопросов и обработку последующих запросов
class ChatValidationService {
  ChatValidationService() {
    _deepSeekService = DeepSeekService();
  }

  late final DeepSeekService _deepSeekService;

  /// Валидация пользовательского запроса
  /// [questionContext] - накопленный контекст вопроса
  /// Возвращает результат валидации с рекомендациями
  Future<ValidationResult> validateUserRequest(
    List<String> questionContext,
  ) async {
    debugPrint(
      '[ChatValidationService] Начинаю валидацию запроса: $questionContext',
    );

    try {
      // Скрываем клавиатуру перед обработкой
      await SystemChannels.textInput.invokeMethod('TextInput.hide');

      // Отправляем весь контекст на валидацию в DeepSeekService
      final validationResponse = await _deepSeekService.validateRequest(
        questionContext,
      );

      debugPrint(
        '[ChatValidationService] Получен ответ валидации: $validationResponse',
      );

      // Преобразуем ответ в результат валидации
      switch (validationResponse.status) {
        case 'valid':
          return ValidationResult.valid(message: '很好，现在请专注你的问题，摇动手机六次进行投币。');

        case 'invalid':
          return ValidationResult.invalid(
            message:
                validationResponse.reasonMessage.isNotEmpty
                    ? validationResponse.reasonMessage
                    : '您的问题不适合占卜。请重新表述。',
          );

        default:
          return ValidationResult.error(
            message:
                'Извините, произошла ошибка при обработке вашего вопроса. '
                'Пожалуйста, попробуйте еще раз или сформулируйте вопрос иначе.',
          );
      }
    } catch (e) {
      debugPrint('[ChatValidationService] Ошибка при валидации запроса: $e');
      return ValidationResult.error(message: '发生技术错误。请重试。');
    }
  }

  /// Обработка последующего вопроса (когда есть контекст последнего гадания)
  /// [question] - новый вопрос пользователя
  /// [context] - контекст последнего гадания
  /// [conversationHistory] - история диалога для контекста
  Future<FollowUpResult> handleFollowUpQuestion({
    required String question,
    required HexagramContext context,
    required List<MessageEntity> conversationHistory,
  }) async {
    debugPrint(
      '[ChatValidationService] Обработка последующего вопроса: $question',
    );
    debugPrint('[ChatValidationService] Контекст: ${context.debugDescription}');

    try {
      // Формируем историю диалога для DeepSeek
      final deepSeekHistory =
          conversationHistory
              .where(
                (m) => !m.isMe && m.hexagrams == null,
              ) // Исключаем сообщения с гексаграммами
              .map((m) => DeepSeekMessage(role: 'assistant', content: m.text))
              .toList();

      // Отправляем запрос на обработку последующего вопроса
      final response = await _deepSeekService.handleFollowUpQuestion(
        question: question,
        originalQuestion: context.originalQuestion,
        primaryHexagram: context.primaryHexagram,
        secondaryHexagram: context.secondaryHexagram,
        previousInterpretation: context.interpretation,
        conversationHistory: deepSeekHistory,
      );

      debugPrint('[ChatValidationService] Получен ответ на последующий вопрос');

      return FollowUpResult.success(response: response);
    } catch (e) {
      debugPrint(
        '[ChatValidationService] Ошибка при обработке последующего вопроса: $e',
      );
      return FollowUpResult.error(errorMessage: '请重试或重新表述您的问题。');
    }
  }

  /// Проверка необходимости перехода на экран оплаты (DEPRECATED)
  /// УСТАРЕЛО: Используйте более специфичные методы
  bool shouldNavigateToPaywall({
    required bool hasActiveSubscription,
    required int remainingFreeRequests,
  }) {
    final shouldNavigate = !hasActiveSubscription && remainingFreeRequests <= 0;
    debugPrint(
      '[ChatValidationService] DEPRECATED: Проверка paywall: '
      'подписка=$hasActiveSubscription, запросы=$remainingFreeRequests, '
      'переходить=$shouldNavigate',
    );
    return shouldNavigate;
  }

  /// Проверка необходимости показа пейвола при попытке начать новое гадание
  /// Возвращает true если пользователь уже использовал бесплатное гадание и не имеет подписки
  bool shouldShowPaywallForNewReading({
    required bool hasActiveSubscription,
    required bool hasUsedFreeReading,
  }) {
    final shouldShow = !hasActiveSubscription && hasUsedFreeReading;
    debugPrint(
      '[ChatValidationService] Проверка paywall для нового гадания: '
      'подписка=$hasActiveSubscription, использовал_бесплатное=$hasUsedFreeReading, '
      'показывать=$shouldShow',
    );
    return shouldShow;
  }

  /// Проверка необходимости показа пейвола при попытке задать фоллоу-ап вопрос
  /// Возвращает true если у пользователя нет подписки и закончились фоллоу-ап вопросы
  bool shouldShowPaywallForFollowUp({
    required bool hasActiveSubscription,
    required int remainingFollowUpQuestions,
  }) {
    final shouldShow =
        !hasActiveSubscription && remainingFollowUpQuestions <= 0;
    debugPrint(
      '[ChatValidationService] Проверка paywall для фоллоу-ап: '
      'подписка=$hasActiveSubscription, остатки_вопросов=$remainingFollowUpQuestions, '
      'показывать=$shouldShow',
    );
    return shouldShow;
  }
}

/// Результат валидации пользовательского запроса
class ValidationResult {
  const ValidationResult._({
    required this.isValid,
    required this.isError,
    required this.message,
    this.shouldClearContext = false,
    this.shouldEnableShaking = false,
  });

  /// Успешная валидация - запрос корректен
  factory ValidationResult.valid({required String message}) {
    return ValidationResult._(
      isValid: true,
      isError: false,
      message: message,
      shouldClearContext: true, // Очищаем контекст после успешной валидации
      shouldEnableShaking: true, // Включаем возможность встряхивания
    );
  }

  /// Неуспешная валидация - запрос некорректен
  factory ValidationResult.invalid({required String message}) {
    return ValidationResult._(isValid: false, isError: false, message: message);
  }

  /// Ошибка валидации - техническая проблема
  factory ValidationResult.error({required String message}) {
    return ValidationResult._(
      isValid: false,
      isError: true,
      message: message,
      shouldClearContext: true, // Очищаем контекст при ошибке
    );
  }

  final bool isValid;
  final bool isError;
  final String message;
  final bool shouldClearContext;
  final bool shouldEnableShaking;
}

/// Результат обработки последующего вопроса
class FollowUpResult {
  const FollowUpResult._({
    required this.isSuccess,
    required this.response,
    required this.errorMessage,
  });

  /// Успешная обработка
  factory FollowUpResult.success({required String response}) {
    return FollowUpResult._(
      isSuccess: true,
      response: response,
      errorMessage: '',
    );
  }

  /// Ошибка обработки
  factory FollowUpResult.error({required String errorMessage}) {
    return FollowUpResult._(
      isSuccess: false,
      response: '',
      errorMessage: errorMessage,
    );
  }

  final bool isSuccess;
  final String response;
  final String errorMessage;
}
