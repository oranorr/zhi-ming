import 'package:flutter/foundation.dart';
import 'package:zhi_ming/core/services/adapty/adapty_service.dart';
import 'package:zhi_ming/core/services/adapty/adapty_service_impl.dart';

/// Сервис для управления подпиской и лимитами запросов
/// Отвечает за проверку доступности запросов, обновление счетчиков и статуса подписки
class ChatSubscriptionService {
  ChatSubscriptionService() {
    _adaptyService = AdaptyServiceImpl();
  }

  late final AdaptyService _adaptyService;

  /// Инициализация сервиса
  Future<void> initialize() async {
    debugPrint('[ChatSubscriptionService] Инициализация сервиса подписки');
    await _adaptyService.init();
  }

  /// Проверка активности подписки
  Future<bool> hasActiveSubscription() async {
    final hasSubscription = await _adaptyService.hasActiveSubscription();
    debugPrint('[ChatSubscriptionService] Активная подписка: $hasSubscription');
    return hasSubscription;
  }

  /// Получение количества оставшихся бесплатных запросов
  Future<int> getRemainingFreeRequests() async {
    final remainingRequests = await _adaptyService.getRemainingFreeRequests();
    debugPrint(
      '[ChatSubscriptionService] Оставшиеся бесплатные запросы: $remainingRequests',
    );
    return remainingRequests;
  }

  /// Проверка возможности выполнения запроса
  Future<bool> canMakeRequest() async {
    final canMake = await _adaptyService.canMakeRequest();
    debugPrint('[ChatSubscriptionService] Может ли сделать запрос: $canMake');
    return canMake;
  }

  /// Уменьшение счетчика бесплатных запросов
  Future<void> decrementFreeRequests() async {
    debugPrint(
      '[ChatSubscriptionService] Уменьшаем счетчик бесплатных запросов',
    );
    await _adaptyService.decrementFreeRequests();
  }

  /// Получение данных о статусе подписки
  Future<SubscriptionStatus> getSubscriptionStatus() async {
    final hasSubscription = await hasActiveSubscription();
    final remainingRequests = await getRemainingFreeRequests();

    return SubscriptionStatus(
      hasActiveSubscription: hasSubscription,
      remainingFreeRequests: remainingRequests,
    );
  }

  /// Проверка лимитов перед выполнением запроса
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

/// Класс для хранения статуса подписки
class SubscriptionStatus {
  const SubscriptionStatus({
    required this.hasActiveSubscription,
    required this.remainingFreeRequests,
  });

  final bool hasActiveSubscription;
  final int remainingFreeRequests;
}

/// Класс для результата проверки возможности запроса
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
