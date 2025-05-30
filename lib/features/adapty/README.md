# Интеграция Adapty SDK

Этот модуль предоставляет полную интеграцию с Adapty SDK для управления подписками в приложении.

## Структура

```
lib/features/adapty/
├── domain/                     # Доменный слой
│   ├── models/                 # Модели данных
│   │   ├── subscription_status.dart
│   │   └── subscription_product.dart
│   └── repositories/           # Интерфейсы репозиториев
│       └── adapty_repository.dart
├── data/                       # Слой данных
│   ├── repositories/           # Реализации репозиториев
│   │   └── adapty_repository_impl.dart
│   └── services/               # Сервисы
│       └── adapty_service.dart
├── presentation/               # Слой представления
│   ├── pages/                  # Страницы
│   │   ├── adapty_test_page.dart
│   │   └── paywall.dart
│   └── widgets/                # Виджеты
│       └── subscription_status_widget.dart
├── adapty.dart                 # Файл экспорта
└── README.md                   # Документация
```

## Основные компоненты

### 1. Модели данных

#### SubscriptionStatus
Представляет статус подписки пользователя:
- `hasPremiumAccess` - есть ли премиум доступ
- `remainingFreeRequests` - оставшиеся бесплатные запросы
- `expirationDate` - дата окончания подписки
- `subscriptionType` - тип подписки

#### SubscriptionProduct
Представляет продукт подписки:
- `productId` - идентификатор продукта
- `title` - название продукта
- `price` - цена в локальной валюте
- `subscriptionPeriod` - период подписки (monthly, yearly, lifetime)
- `discountPercentage` - процент скидки

### 2. Репозиторий

#### AdaptyRepository
Интерфейс для работы с Adapty SDK:
- `initialize()` - инициализация SDK
- `getSubscriptionStatus()` - получение статуса подписки
- `getAvailableProducts()` - получение доступных продуктов
- `purchaseSubscription()` - покупка подписки
- `restorePurchases()` - восстановление покупок
- `decrementFreeRequests()` - уменьшение счетчика бесплатных запросов
- `canMakeRequest()` - проверка возможности запроса
- `trackEvent()` - отправка событий
- `setUserAttributes()` - установка атрибутов пользователя

### 3. Сервис

#### AdaptyService
Singleton сервис для управления Adapty SDK:
- Инициализация SDK
- Предоставление доступа к репозиторию
- Управление состоянием

### 4. UI компоненты

#### SubscriptionStatusWidget
Виджет для отображения статуса подписки пользователя.

#### AdaptyTestPage
Страница для тестирования функциональности Adapty.

## Использование

### 1. Инициализация

В `main.dart` уже настроена инициализация:

```dart
import 'package:zhi_ming/features/adapty/adapty.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Инициализация Adapty SDK
  await Adapty().activate(
    configuration: AdaptyConfiguration(
      apiKey: 'public_live_fskP9YOd.ESywAoCmsmDLtoV0z9tI',
    )..withLogLevel(AdaptyLogLevel.verbose),
  );
  
  // Инициализация нашего сервиса
  await AdaptyService.instance.initialize();
  
  runApp(const App());
}
```

### 2. Проверка статуса подписки

```dart
final status = await AdaptyService.instance.repository.getSubscriptionStatus();

if (status.hasPremiumAccess) {
  // Пользователь имеет премиум доступ
  print('Премиум до: ${status.expirationDate}');
} else {
  // Бесплатный пользователь
  print('Осталось запросов: ${status.remainingFreeRequests}');
}
```

### 3. Получение продуктов

```dart
final products = await AdaptyService.instance.repository.getAvailableProducts();

for (final product in products) {
  print('${product.title}: ${product.price}');
}
```

### 4. Покупка подписки

```dart
final success = await AdaptyService.instance.repository.purchaseSubscription('monthly_premium');

if (success) {
  print('Подписка успешно приобретена');
} else {
  print('Ошибка покупки');
}
```

### 5. Использование бесплатного запроса

```dart
final canMake = await AdaptyService.instance.repository.canMakeRequest();

if (canMake) {
  // Выполняем запрос
  await AdaptyService.instance.repository.decrementFreeRequests();
} else {
  // Показываем paywall
}
```

### 6. Отображение статуса подписки

```dart
import 'package:zhi_ming/features/adapty/adapty.dart';

class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const SubscriptionStatusWidget(),
          // Другие виджеты
        ],
      ),
    );
  }
}
```

## Тестирование

Для тестирования функциональности используйте `AdaptyTestPage`:

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const AdaptyTestPage(),
  ),
);
```

## Конфигурация

### API ключ
Текущий API ключ: `public_live_fskP9YOd.ESywAoCmsmDLtoV0z9tI`

### Настройки бесплатных запросов
- Debug режим: 5 запросов
- Release режим: 20 запросов

### Placement ID
Используется `zhi-ming-placement` для получения продуктов.

## Архитектура

Модуль следует принципам Clean Architecture:

1. **Domain Layer** - содержит бизнес-логику и интерфейсы
2. **Data Layer** - содержит реализации и работу с внешними API
3. **Presentation Layer** - содержит UI компоненты

## Обработка ошибок

Все методы репозитория обрабатывают ошибки и предоставляют fallback значения:
- При ошибке получения статуса возвращается бесплатный статус
- При ошибке получения продуктов возвращаются mock данные
- Все ошибки логируются с префиксом `[AdaptyRepositoryImpl]`

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