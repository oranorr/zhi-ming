import 'package:zhi_ming/features/adapty/domain/models/subscription_status.dart';
import 'package:zhi_ming/features/adapty/domain/models/subscription_product.dart';

/// Абстрактный репозиторий для работы с Adapty SDK
/// Определяет контракт для всех операций с подписками
abstract interface class AdaptyRepository {
  /// Инициализация Adapty SDK
  /// Должна быть вызвана при запуске приложения
  Future<void> initialize();

  /// Получение текущего статуса подписки пользователя
  /// Возвращает [SubscriptionStatus] с информацией о подписке и бесплатных запросах
  Future<SubscriptionStatus> getSubscriptionStatus();

  /// Получение списка доступных продуктов подписки
  /// Возвращает список [SubscriptionProduct] с информацией о ценах и планах
  Future<List<SubscriptionProduct>> getAvailableProducts();

  /// Покупка подписки по идентификатору продукта
  /// [productId] - идентификатор продукта для покупки
  /// Возвращает true если покупка прошла успешно
  Future<bool> purchaseSubscription(String productId);

  /// Восстановление покупок пользователя
  /// Проверяет и восстанавливает ранее совершенные покупки
  /// Возвращает true если есть активные подписки
  Future<bool> restorePurchases();

  /// Уменьшение счетчика бесплатных запросов
  /// Вызывается при каждом использовании бесплатного запроса
  Future<void> decrementFreeRequests();

  /// Проверка, может ли пользователь сделать запрос
  /// Учитывает как активную подписку, так и оставшиеся бесплатные запросы
  Future<bool> canMakeRequest();

  /// Получение информации о paywall для отображения
  /// Возвращает конфигурацию paywall из Adapty
  Future<Map<String, dynamic>?> getPaywallConfiguration();

  /// Отправка события об использовании функции
  /// [eventName] - название события для аналитики
  /// [parameters] - дополнительные параметры события
  Future<void> trackEvent(String eventName, {Map<String, dynamic>? parameters});

  /// Установка пользовательских атрибутов
  /// [attributes] - атрибуты пользователя для сегментации
  Future<void> setUserAttributes(Map<String, dynamic> attributes);

  /// Получение идентификатора пользователя Adapty
  /// Возвращает уникальный ID пользователя в системе Adapty
  Future<String?> getUserId();

  /// Логаут пользователя из Adapty
  /// Очищает данные текущего пользователя
  Future<void> logout();
}
