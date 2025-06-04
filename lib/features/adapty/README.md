# Adapty Feature

Эта функция обеспечивает интеграцию с Adapty SDK для управления подписками и внутренними покупками в приложении.

## Архитектура

Модуль построен по принципам Clean Architecture:

```
lib/features/adapty/
├── data/
│   └── repositories/
│       └── adapty_repository_impl.dart    # Реализация репозитория с Adapty SDK
├── domain/
│   ├── models/
│   │   ├── subscription_product.dart       # Модель продукта подписки
│   │   └── subscription_status.dart        # Модель статуса подписки
│   └── repositories/
│       └── adapty_repository.dart          # Абстрактный репозиторий
└── presentation/
    ├── pages/
    │   └── adapty_test_page.dart           # Страница для тестирования
    └── widgets/
        └── subscription_status_widget.dart # Виджет статуса подписки
```

### Domain Layer

#### AdaptyRepository

Абстрактный репозиторий определяет контракт для работы с подписками:

```dart
abstract interface class AdaptyRepository {
  // Инициализация
  Future<void> initialize();
  
  // Статус подписки
  Future<SubscriptionStatus> getSubscriptionStatus();
  
  // Продукты
  Future<List<SubscriptionProduct>> getAvailableProducts();
  
  // Покупки
  Future<bool> purchaseSubscription(String productId);
  Future<bool> restorePurchases();
  
  // Бесплатные запросы
  Future<void> decrementFreeRequests();
  Future<bool> canMakeRequest();
  
  // Аналитика
  Future<void> trackEvent(String eventName, {Map<String, dynamic>? parameters});
}
```

#### Модели

**SubscriptionStatus** - содержит информацию о текущем статусе подписки:
- `hasPremiumAccess` - есть ли активная подписка
- `remainingFreeRequests` - оставшиеся бесплатные запросы
- `expirationDate` - дата окончания подписки

**SubscriptionProduct** - информация о продукте подписки:
- `productId` - идентификатор продукта
- `title` - название
- `price` - цена
- `subscriptionPeriod` - период подписки

### Data Layer

#### AdaptyRepositoryImpl

Реализация репозитория с Adapty SDK. Поддерживает:
- Singleton pattern для глобального доступа
- Fallback на mock данные в debug режиме
- Локальное хранение счетчика бесплатных запросов
- Обработку ошибок и исключений

### Presentation Layer

#### AdaptyTestPage

Страница для тестирования функциональности:
- Отображение статуса подписки
- Список доступных продуктов
- Тестирование покупок и восстановления

#### SubscriptionStatusWidget

Переиспользуемый виджет для отображения статуса подписки в любой части приложения.

## Использование

### Инициализация

В `main.dart`:

```dart
void main() async {
  // Активация Adapty SDK
  await Adapty().activate(
    configuration: AdaptyConfiguration(apiKey: 'your_api_key'),
  );
  
  // Инициализация репозитория
  await AdaptyRepositoryImpl.instance.initialize();
  
  runApp(const App());
}
```

### Проверка статуса подписки

```dart
final repository = AdaptyRepositoryImpl.instance;
final status = await repository.getSubscriptionStatus();

if (status.hasPremiumAccess) {
  // Пользователь имеет активную подписку
} else {
  // Показать количество оставшихся бесплатных запросов
  print('Осталось запросов: ${status.remainingFreeRequests}');
}
```

### Загрузка и покупка продуктов

```dart
final repository = AdaptyRepositoryImpl.instance;

// Получение списка продуктов
final products = await repository.getAvailableProducts();

// Покупка продукта
final success = await repository.purchaseSubscription('monthly_premium');
if (success) {
  // Покупка прошла успешно
}
```

### Проверка возможности запроса

```dart
final repository = AdaptyRepositoryImpl.instance;

final canMake = await repository.canMakeRequest();
if (canMake) {
  // Выполняем запрос
  await performRequest();
  
  // Уменьшаем счетчик для бесплатных пользователей
  await repository.decrementFreeRequests();
}
```

## Тестирование

Для тестирования доступен debug-режим с:
- Уменьшенным лимитом бесплатных запросов (5 вместо 20)
- Mock продуктами при ошибках загрузки
- Дополнительным логированием

Используйте `AdaptyTestPage` для проверки функциональности.

## Конфигурация

### Константы

В `AdaptyRepositoryImpl`:
- `_maxFreeRequests` - максимальное количество бесплатных запросов
- `_premiumAccessLevel` - уровень доступа для премиум подписки
- `_paywallPlacementId` - ID размещения paywall в Adapty

### Локальное хранение

Используется `FlutterSecureStorage` для хранения:
- Счетчика бесплатных запросов
- Статуса подписки (fallback)

## Обработка ошибок

Репозиторий обрабатывает ошибки gracefully:
- При ошибках Adapty SDK возвращает безопасные значения по умолчанию
- В debug режиме показывает mock данные
- Логирует все ошибки для отладки

## Безопасность

- Счетчик бесплатных запросов хранится в `FlutterSecureStorage`
- API ключ используется только публичный (не секретный)
- Все транзакции обрабатываются через Adapty SDK

## Локализация

Модели поддерживают китайскую локализацию:
- 月度会员 (Месячная подписка)
- 年度会员 (Годовая подписка)  
- 终身会员 (Пожизненная подписка)

## Зависимости

- `adapty_flutter: ^3.6.1` - Основной SDK
- `flutter_secure_storage` - Безопасное хранение
- `equatable` - Сравнение объектов 