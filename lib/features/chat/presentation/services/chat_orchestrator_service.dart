import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:zhi_ming/core/services/deepseek/deepseek_service.dart';
import 'package:zhi_ming/core/services/shake_service/shaker_service_repo.dart';
import 'package:zhi_ming/features/adapty/domain/models/subscription_status.dart';
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

  /// Генерация гексаграммы из значений линий
  Future<HexagramPair> generateHexagramFromLines(List<int> lineValues) async {
    return _hexagramService.generateHexagramFromLines(lineValues);
  }

  /// Отметить использование бесплатного гадания
  Future<void> markFreeReadingAsUsed() async {
    return _subscriptionService.markFreeReadingAsUsed();
  }

  /// Валидация пользовательского запроса
  Future<ValidationResult> validateUserRequest(
    List<String> questionContext,
  ) async {
    // [ChatOrchestratorService] НОВАЯ ЛОГИКА: ВСЕГДА разрешаем задать вопрос и сделать броски
    // Проверка подписки происходит ТОЛЬКО ПОСЛЕ бросков монет в processAfterShaking
    debugPrint(
      '[ChatOrchestratorService] Разрешаем задать вопрос и сделать броски для любого гадания',
    );

    // Просто валидируем содержание вопроса, не проверяя подписку
    return _validationService.validateUserRequest(questionContext);
  }

  /// Обработка последующего вопроса
  Future<FollowUpQuestionResult> handleFollowUpQuestion({
    required String question,
    required HexagramContext context,
    required List<MessageEntity> conversationHistory,
  }) async {
    debugPrint('[ChatOrchestratorService] Обработка последующего вопроса');

    // [ChatOrchestratorService] Проверяем возможность задать фоллоу-ап вопрос
    final canAskFollowUp = await _subscriptionService.canAskFollowUpQuestion();

    if (!canAskFollowUp) {
      return FollowUpQuestionResult.paywalRequired(
        message:
            'Вы исчерпали все бесплатные дополнительные вопросы. '
            'Для продолжения необходимо оформить подписку.',
      );
    }

    // Обрабатываем вопрос
    final result = await _validationService.handleFollowUpQuestion(
      question: question,
      context: context,
      conversationHistory: conversationHistory,
    );

    if (result.isSuccess) {
      // [ChatOrchestratorService] Уменьшаем счетчик фоллоу-ап вопросов после успешной обработки
      await _subscriptionService.decrementFollowUpQuestions();

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

      // [ChatOrchestratorService] УБИРАЕМ проверку подписки - она теперь происходит в ChatCubit ПОСЛЕ генерации гексаграмм
      // final canStartReading = await _subscriptionService.canStartNewReading();
      // if (!canStartReading) {
      //   return ShakeProcessingResult.paywallRequired(
      //     message: 'Вы уже использовали свое бесплатное гадание. Для продолжения необходимо оформить подписку.',
      //   );
      // }

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

      // [ChatOrchestratorService] УБИРАЕМ отметку использования бесплатного гадания
      // Эта логика теперь обрабатывается в ChatCubit ПОСЛЕ покупки подписки
      // await _subscriptionService.markFreeReadingAsUsed();

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

  /// Обработка результата встряхивания с гексаграммами
  /// [userQuestion] - вопрос пользователя для интерпретации
  /// [hexagramPair] - результат бросков монет
  Future<ShakeProcessingResult> processShakeResult({
    required String userQuestion,
    required HexagramPair hexagramPair,
  }) async {
    try {
      debugPrint(
        '[ChatOrchestratorService] Обработка результата встряхивания для вопроса: $userQuestion',
      );

      // Получаем интерпретацию от DeepSeek
      final interpretationResult = await _deepSeekService
          .interpretHexagramsStructured(
            question: userQuestion,
            primaryHexagram: hexagramPair.primary,
            secondaryHexagram: hexagramPair.secondary,
          );

      // [ChatOrchestratorService] ВАЖНО: Отмечаем использование бесплатного гадания ПОСЛЕ успешного получения интерпретации
      await _subscriptionService.markFreeReadingAsUsed();

      // Примечание: сброс результатов встряхиваний должен выполняться во внешнем коде

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

  /// Обработка последующего вопроса пользователя
  /// [question] - новый вопрос от пользователя
  /// [context] - контекст последнего гадания
  /// [conversationHistory] - история сообщений для контекста
  Future<FollowUpQuestionResult> processFollowUpQuestion({
    required String question,
    required HexagramContext context,
    required List<MessageEntity> conversationHistory,
  }) async {
    debugPrint(
      '[ChatOrchestratorService] Обработка последующего вопроса: $question',
    );

    try {
      // [ChatOrchestratorService] Проверяем возможность задать фоллоу-ап вопрос
      final subscriptionStatus =
          await _subscriptionService.getSubscriptionStatus();

      if (!subscriptionStatus.canAskFollowUpQuestion) {
        return FollowUpQuestionResult.paywalRequired(
          message:
              'Вы исчерпали все бесплатные дополнительные вопросы. '
              'Для продолжения необходимо оформить подписку.',
        );
      }

      // Обрабатываем вопрос через валидационный сервис
      final result = await _validationService.handleFollowUpQuestion(
        question: question,
        context: context,
        conversationHistory: conversationHistory,
      );

      if (result.isSuccess) {
        // [ChatOrchestratorService] Уменьшаем счетчик фоллоу-ап вопросов ПОСЛЕ успешной обработки
        await _subscriptionService.decrementFollowUpQuestions();

        return FollowUpQuestionResult.success(
          response: result.response,
          updatedSubscriptionStatus:
              await _subscriptionService.getSubscriptionStatus(),
        );
      } else {
        return FollowUpQuestionResult.error(message: result.errorMessage);
      }
    } catch (e) {
      debugPrint(
        '[ChatOrchestratorService] Ошибка при обработке последующего вопроса: $e',
      );
      return FollowUpQuestionResult.error(
        message:
            'Произошла ошибка при обработке вашего вопроса. '
            'Пожалуйста, попробуйте сформулировать его иначе.',
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

  /// Проверка необходимости перехода на paywall для нового гадания
  bool shouldNavigateToPaywallForNewReading({
    required bool hasActiveSubscription,
    required bool hasUsedFreeReading,
  }) {
    return _validationService.shouldShowPaywallForNewReading(
      hasActiveSubscription: hasActiveSubscription,
      hasUsedFreeReading: hasUsedFreeReading,
    );
  }

  /// Проверка необходимости перехода на paywall для фоллоу-ап вопроса
  bool shouldNavigateToPaywallForFollowUp({
    required bool hasActiveSubscription,
    required int remainingFollowUpQuestions,
  }) {
    return _validationService.shouldShowPaywallForFollowUp(
      hasActiveSubscription: hasActiveSubscription,
      remainingFollowUpQuestions: remainingFollowUpQuestions,
    );
  }

  /// Проверка необходимости перехода на paywall (DEPRECATED)
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

  // Методы для тестирования и отладки

  /// Сброс флага бесплатного гадания (для тестирования)
  /// [ChatOrchestratorService] Устанавливает флаг hasUsedFreeReading в false
  Future<void> resetFreeReadingFlag() async {
    await _subscriptionService.resetFreeReadingFlag();
    debugPrint('[ChatOrchestratorService] Флаг бесплатного гадания сброшен');
  }

  /// Сброс счетчика фоллоу-ап вопросов (для тестирования)
  /// [ChatOrchestratorService] Восстанавливает максимальное количество фоллоу-ап вопросов
  Future<void> resetFollowUpQuestionsCount() async {
    await _subscriptionService.resetFollowUpQuestionsCount();
    debugPrint('[ChatOrchestratorService] Счетчик фоллоу-ап вопросов сброшен');
  }

  /// Полный сброс всех данных пользователя (для тестирования)
  /// [ChatOrchestratorService] Сбрасывает все данные пользователя для чистого состояния
  Future<void> resetUserData() async {
    await _subscriptionService.resetUserData();
    debugPrint('[ChatOrchestratorService] Все данные пользователя сброшены');
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
