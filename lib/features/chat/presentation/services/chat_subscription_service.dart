import 'package:flutter/foundation.dart';
import 'package:zhi_ming/features/adapty/data/repositories/adapty_repository_impl.dart';
import 'package:zhi_ming/features/adapty/domain/models/subscription_status.dart';
import 'package:zhi_ming/features/adapty/domain/repositories/adapty_repository.dart';

/// Сервис для управления подпиской и лимитами запросов
/// Отвечает за проверку доступности запросов, обновление счетчиков и статуса подписки
class ChatSubscriptionService {
  ChatSubscriptionService() {
    _adaptyRepository = AdaptyRepositoryImpl.instance;
  }

  late final AdaptyRepository _adaptyRepository;

  /// Инициализация сервиса
  Future<void> initialize() async {
    debugPrint('[ChatSubscriptionService] Инициализация сервиса подписки');
    await _adaptyRepository.initialize();
  }

  /// Проверка активности подписки
  Future<bool> hasActiveSubscription() async {
    final subscriptionStatus = await _adaptyRepository.getSubscriptionStatus();
    final hasSubscription = subscriptionStatus.hasPremiumAccess;
    debugPrint('[ChatSubscriptionService] Активная подписка: $hasSubscription');
    return hasSubscription;
  }

  /// Получение количества оставшихся бесплатных запросов (DEPRECATED)
  Future<int> getRemainingFreeRequests() async {
    final subscriptionStatus = await _adaptyRepository.getSubscriptionStatus();
    final remainingRequests = subscriptionStatus.remainingFreeRequests;
    debugPrint(
      '[ChatSubscriptionService] Оставшиеся бесплатные запросы: $remainingRequests',
    );
    return remainingRequests;
  }

  /// Проверка возможности выполнения запроса (DEPRECATED)
  Future<bool> canMakeRequest() async {
    final canMake = await _adaptyRepository.canMakeRequest();
    debugPrint('[ChatSubscriptionService] Может ли сделать запрос: $canMake');
    return canMake;
  }

  /// Уменьшение счетчика бесплатных запросов (DEPRECATED)
  Future<void> decrementFreeRequests() async {
    await _adaptyRepository.decrementFreeRequests();
    debugPrint(
      '[ChatSubscriptionService] Счетчик бесплатных запросов уменьшен',
    );
  }

  /// Отметка использования бесплатного гадания
  /// Устанавливает флаг что пользователь использовал свое единственное бесплатное гадание
  Future<void> markFreeReadingAsUsed() async {
    await _adaptyRepository.markFreeReadingAsUsed();
    debugPrint(
      '[ChatSubscriptionService] Бесплатное гадание отмечено как использованное',
    );
  }

  /// Уменьшение счетчика фоллоу-ап вопросов
  /// Вызывается при каждом фоллоу-ап вопросе после завершения гадания
  Future<void> decrementFollowUpQuestions() async {
    await _adaptyRepository.decrementFollowUpQuestions();
    debugPrint('[ChatSubscriptionService] Счетчик фоллоу-ап вопросов уменьшен');
  }

  /// Проверка возможности начать новое гадание
  /// Возвращает true если пользователь может начать новое гадание
  Future<bool> canStartNewReading() async {
    final canStart = await _adaptyRepository.canStartNewReading();
    debugPrint(
      '[ChatSubscriptionService] Может ли начать новое гадание: $canStart',
    );
    return canStart;
  }

  /// Проверка возможности задать фоллоу-ап вопрос
  /// Возвращает true если пользователь может задать фоллоу-ап вопрос
  Future<bool> canAskFollowUpQuestion() async {
    final canAsk = await _adaptyRepository.canAskFollowUpQuestion();
    debugPrint(
      '[ChatSubscriptionService] Может ли задать фоллоу-ап вопрос: $canAsk',
    );
    return canAsk;
  }

  /// Получение данных о статусе подписки
  Future<SubscriptionStatus> getSubscriptionStatus() async {
    return _adaptyRepository.getSubscriptionStatus();
  }

  /// Проверка лимитов перед выполнением запроса (DEPRECATED)
  /// Возвращает результат проверки с детальной информацией
  Future<RequestCheckResult> checkRequestAvailability() async {
    debugPrint('[ChatSubscriptionService] Проверка доступности запроса');

    final hasSubscription = await hasActiveSubscription();
    final remainingRequests = await getRemainingFreeRequests();
    final canMake = await canMakeRequest();

    if (!canMake) {
      return RequestCheckResult(
        canMakeRequest: false,
        reason:
            hasSubscription
                ? 'Неизвестная ошибка проверки подписки'
                : 'Вы исчерпали все бесплатные запросы. Для продолжения необходимо оформить подписку.',
        hasActiveSubscription: hasSubscription,
        remainingFreeRequests: remainingRequests,
      );
    }

    return RequestCheckResult(
      canMakeRequest: true,
      reason: '',
      hasActiveSubscription: hasSubscription,
      remainingFreeRequests: remainingRequests,
    );
  }
}

/// Класс для результата проверки возможности запроса (DEPRECATED)
class RequestCheckResult {
  const RequestCheckResult({
    required this.canMakeRequest,
    required this.reason,
    required this.hasActiveSubscription,
    required this.remainingFreeRequests,
  });

  final bool canMakeRequest;
  final String reason;
  final bool hasActiveSubscription;
  final int remainingFreeRequests;
}
