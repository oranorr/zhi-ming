import 'package:zhi_ming/features/adapty/domain/models/subscription_product.dart';

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

  /// Получение списка доступных продуктов подписки
  Future<List<SubscriptionProduct>> getAvailableProducts();

  /// Покупка подписки по идентификатору продукта
  Future<bool> purchaseSubscription(String productId);

  /// Восстановление покупок пользователя
  Future<bool> restorePurchases();
}
