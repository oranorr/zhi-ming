abstract interface class AdaptyService {
  Future<void> init();

  /// Проверка статуса подписки
  Future<bool> hasActiveSubscription();

  /// Получение количества оставшихся бесплатных запросов
  Future<int> getRemainingFreeRequests();

  /// Уменьшение счетчика бесплатных запросов
  Future<void> decrementFreeRequests();

  /// Сброс счетчика бесплатных запросов (для тестирования)
  Future<void> resetFreeRequests();

  /// Проверка, может ли пользователь сделать запрос
  Future<bool> canMakeRequest();

  /// Активация подписки
  Future<void> activateSubscription();

  /// Деактивация подписки
  Future<void> deactivateSubscription();
}
