import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:zhi_ming/core/services/deepseek/deepseek_service.dart';
import 'package:zhi_ming/core/services/shake_service/shaker_service_repo.dart';
import 'package:zhi_ming/features/chat/domain/message_entity.dart';
import 'package:zhi_ming/features/chat/presentation/models/chat_state.dart';
import 'package:zhi_ming/features/chat/presentation/services/chat_subscription_service.dart';
import 'package:zhi_ming/features/chat/presentation/services/chat_validation_service.dart';
import 'package:zhi_ming/features/chat/presentation/services/hexagram_generation_service.dart';
import 'package:zhi_ming/features/chat/presentation/services/message_streaming_service.dart';
import 'package:zhi_ming/features/iching/models/hexagram.dart';

/// Главный сервис-оркестратор для координации работы всех сервисов чата
/// Инкапсулирует сложную бизнес-логику и предоставляет простой интерфейс для кубита
class ChatOrchestratorService {
  ChatOrchestratorService() {
    _subscriptionService = ChatSubscriptionService();
    _validationService = ChatValidationService();
    _hexagramService = HexagramGenerationService();
    _streamingService = MessageStreamingService();
    _deepSeekService = DeepSeekService();
  }

  late final ChatSubscriptionService _subscriptionService;
  late final ChatValidationService _validationService;
  late final HexagramGenerationService _hexagramService;
  late final MessageStreamingService _streamingService;
  late final DeepSeekService _deepSeekService;

  /// Инициализация всех сервисов
  Future<void> initialize() async {
    debugPrint('[ChatOrchestratorService] Инициализация всех сервисов');
    await _subscriptionService.initialize();
    await _hexagramService.loadHexagramsData();
    debugPrint('[ChatOrchestratorService] Все сервисы инициализированы');
  }

  /// Получение статуса подписки
  Future<SubscriptionStatus> getSubscriptionStatus() async {
    return _subscriptionService.getSubscriptionStatus();
  }

  /// Валидация пользовательского запроса
  Future<ValidationResult> validateUserRequest(
    List<String> questionContext,
  ) async {
    // Сначала проверяем возможность выполнения запроса
    final requestCheck = await _subscriptionService.checkRequestAvailability();

    if (!requestCheck.canMakeRequest) {
      debugPrint(
        '[ChatOrchestratorService] Запрос заблокирован: ${requestCheck.reason}',
      );
      return ValidationResult.error(message: requestCheck.reason);
    }

    // Если запрос возможен, валидируем его содержание
    return _validationService.validateUserRequest(questionContext);
  }

  /// Обработка последующего вопроса
  Future<FollowUpQuestionResult> handleFollowUpQuestion({
    required String question,
    required HexagramContext context,
    required List<MessageEntity> conversationHistory,
  }) async {
    debugPrint('[ChatOrchestratorService] Обработка последующего вопроса');

    // Проверяем возможность выполнения запроса
    final requestCheck = await _subscriptionService.checkRequestAvailability();

    if (!requestCheck.canMakeRequest) {
      return FollowUpQuestionResult.paywalRequired(
        message: requestCheck.reason,
      );
    }

    // Обрабатываем вопрос
    final result = await _validationService.handleFollowUpQuestion(
      question: question,
      context: context,
      conversationHistory: conversationHistory,
    );

    if (result.isSuccess) {
      // Уменьшаем счетчик запросов после успешной обработки
      await _subscriptionService.decrementFreeRequests();

      return FollowUpQuestionResult.success(
        response: result.response,
        updatedSubscriptionStatus:
            await _subscriptionService.getSubscriptionStatus(),
      );
    } else {
      return FollowUpQuestionResult.error(message: result.errorMessage);
    }
  }

  /// Полная обработка встряхивания с генерацией гексаграмм и интерпретацией
  Future<ShakeProcessingResult> processAfterShaking({
    required ShakerServiceRepo shakerService,
    required String userQuestion,
  }) async {
    debugPrint(
      '[ChatOrchestratorService] Начинаю полную обработку встряхивания',
    );

    try {
      // Скрываем клавиатуру
      await SystemChannels.textInput.invokeMethod('TextInput.hide');

      // Проверяем возможность выполнения запроса
      final requestCheck =
          await _subscriptionService.checkRequestAvailability();

      if (!requestCheck.canMakeRequest) {
        return ShakeProcessingResult.paywallRequired(
          message: requestCheck.reason,
        );
      }

      // Получаем значения линий из сервиса встряхивания
      final List<int> lineValues = shakerService.getLineValues();
      debugPrint(
        '[ChatOrchestratorService] Получены значения линий: $lineValues',
      );

      // Если не получены все 6 линий, дополняем до полной гексаграммы
      final List<int> completeLineValues = List<int>.from(lineValues);
      while (completeLineValues.length < 6) {
        completeLineValues.add(8); // молодой инь по умолчанию
      }

      // Генерируем гексаграммы
      final hexagramPair = await _hexagramService.generateHexagramFromLines(
        completeLineValues,
      );

      debugPrint('[ChatOrchestratorService] Сгенерированы гексаграммы:');
      debugPrint(
        '  Основная: ${hexagramPair.primary.number} (${hexagramPair.primary.name})',
      );
      if (hexagramPair.hasChangingLines) {
        debugPrint(
          '  Изменяющаяся: ${hexagramPair.secondary!.number} (${hexagramPair.secondary!.name})',
        );
      }

      // Получаем интерпретацию от DeepSeek
      final interpretationResult = await _deepSeekService
          .interpretHexagramsStructured(
            question: userQuestion,
            primaryHexagram: hexagramPair.primary,
            secondaryHexagram: hexagramPair.secondary,
          );

      // Уменьшаем счетчик запросов после успешного гадания
      await _subscriptionService.decrementFreeRequests();

      // Сбрасываем результаты встряхиваний для следующего сеанса
      shakerService.resetCoinThrows();

      return ShakeProcessingResult.success(
        hexagramPair: hexagramPair,
        interpretationResult: interpretationResult,
        userQuestion: userQuestion,
        updatedSubscriptionStatus:
            await _subscriptionService.getSubscriptionStatus(),
      );
    } catch (e) {
      debugPrint(
        '[ChatOrchestratorService] Ошибка при обработке встряхивания: $e',
      );
      return ShakeProcessingResult.error(
        message:
            'Произошла ошибка при обработке гадания. Пожалуйста, попробуйте еще раз.',
      );
    }
  }

  /// Настройка streaming для сообщения
  void setupMessageStreaming({
    required MessageEntity message,
    required VoidCallback onStreamingComplete,
  }) {
    _streamingService.setupStreaming(
      message: message,
      onStreamingComplete: onStreamingComplete,
    );
  }

  /// Остановка всех streaming
  void stopAllStreaming() {
    _streamingService.stopAllStreaming();
  }

  /// Проверка необходимости перехода на paywall
  bool shouldNavigateToPaywall({
    required bool hasActiveSubscription,
    required int remainingFreeRequests,
  }) {
    return _validationService.shouldNavigateToPaywall(
      hasActiveSubscription: hasActiveSubscription,
      remainingFreeRequests: remainingFreeRequests,
    );
  }

  /// Освобождение ресурсов
  void dispose() {
    debugPrint('[ChatOrchestratorService] Освобождение ресурсов');
    _streamingService.dispose();
  }
}

/// Результат обработки последующего вопроса
class FollowUpQuestionResult {
  const FollowUpQuestionResult._({
    required this.type,
    this.response = '',
    this.message = '',
    this.updatedSubscriptionStatus,
  });

  factory FollowUpQuestionResult.success({
    required String response,
    required SubscriptionStatus updatedSubscriptionStatus,
  }) {
    return FollowUpQuestionResult._(
      type: FollowUpResultType.success,
      response: response,
      updatedSubscriptionStatus: updatedSubscriptionStatus,
    );
  }

  factory FollowUpQuestionResult.error({required String message}) {
    return FollowUpQuestionResult._(
      type: FollowUpResultType.error,
      message: message,
    );
  }

  factory FollowUpQuestionResult.paywalRequired({required String message}) {
    return FollowUpQuestionResult._(
      type: FollowUpResultType.paywallRequired,
      message: message,
    );
  }

  final FollowUpResultType type;
  final String response;
  final String message;
  final SubscriptionStatus? updatedSubscriptionStatus;

  bool get isSuccess => type == FollowUpResultType.success;
  bool get isError => type == FollowUpResultType.error;
  bool get requiresPaywall => type == FollowUpResultType.paywallRequired;
}

/// Результат обработки встряхивания
class ShakeProcessingResult {
  const ShakeProcessingResult._({
    required this.type,
    this.hexagramPair,
    this.interpretationResult,
    this.userQuestion = '',
    this.message = '',
    this.updatedSubscriptionStatus,
  });

  factory ShakeProcessingResult.success({
    required HexagramPair hexagramPair,
    required interpretationResult,
    required String userQuestion,
    required SubscriptionStatus updatedSubscriptionStatus,
  }) {
    return ShakeProcessingResult._(
      type: ShakeResultType.success,
      hexagramPair: hexagramPair,
      interpretationResult: interpretationResult,
      userQuestion: userQuestion,
      updatedSubscriptionStatus: updatedSubscriptionStatus,
    );
  }

  factory ShakeProcessingResult.error({required String message}) {
    return ShakeProcessingResult._(
      type: ShakeResultType.error,
      message: message,
    );
  }

  factory ShakeProcessingResult.paywallRequired({required String message}) {
    return ShakeProcessingResult._(
      type: ShakeResultType.paywallRequired,
      message: message,
    );
  }

  final ShakeResultType type;
  final HexagramPair? hexagramPair;
  final dynamic interpretationResult;
  final String userQuestion;
  final String message;
  final SubscriptionStatus? updatedSubscriptionStatus;

  bool get isSuccess => type == ShakeResultType.success;
  bool get isError => type == ShakeResultType.error;
  bool get requiresPaywall => type == ShakeResultType.paywallRequired;
}

/// Типы результатов обработки последующих вопросов
enum FollowUpResultType { success, error, paywallRequired }

/// Типы результатов обработки встряхивания
enum ShakeResultType { success, error, paywallRequired }
