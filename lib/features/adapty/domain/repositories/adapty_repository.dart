import 'package:zhi_ming/features/adapty/domain/models/subscription_product.dart';
import 'package:zhi_ming/features/adapty/domain/models/subscription_status.dart';

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

  /// Принудительное обновление кэша продуктов
  /// Обновляет локальный кэш продуктов из Adapty
  /// Полезно для синхронизации с изменениями в Adapty Dashboard
  Future<void> refreshProducts();

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

  /// Отметка использования бесплатного гадания
  /// Устанавливает флаг что пользователь использовал свое единственное бесплатное гадание
  Future<void> markFreeReadingAsUsed();

  /// Уменьшение счетчика фоллоу-ап вопросов
  /// Вызывается при каждом фоллоу-ап вопросе после завершения гадания
  Future<void> decrementFollowUpQuestions();

  /// Проверка возможности начать новое гадание
  /// Возвращает true если пользователь может начать новое гадание (имеет подписку или не использовал бесплатное)
  Future<bool> canStartNewReading();

  /// Проверка возможности задать фоллоу-ап вопрос
  /// Возвращает true если пользователь может задать фоллоу-ап вопрос (имеет подписку или остались вопросы)
  Future<bool> canAskFollowUpQuestion();

  /// Проверка, может ли пользователь сделать запрос (DEPRECATED)
  /// Учитывает как активную подписку, так и оставшиеся бесплатные запросы
  /// РЕКОМЕНДУЕТСЯ использовать более специфичные методы canStartNewReading или canAskFollowUpQuestion
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
