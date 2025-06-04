# Система профиля пользователя

Данная система позволяет сохранять и управлять данными пользователя, собранными во время онбординга.

## Архитектура

### Основные компоненты

1. **UserProfile** (`lib/features/onboard/data/user_profile_service.dart`)
   - Модель данных пользователя
   - Содержит: имя, дату рождения, время рождения (опционально), интересы
   - Поддерживает сериализацию в JSON

2. **UserProfileService** (`lib/features/onboard/data/user_profile_service.dart`)
   - Низкоуровневый сервис для работы с локальным хранилищем
   - Использует SharedPreferences для сохранения данных
   - Методы: save, load, delete, update

3. **UserService** (`lib/core/services/user_service.dart`)
   - Высокоуровневый сервис с кешированием
   - Единая точка доступа к профилю пользователя
   - Предоставляет удобные методы для получения конкретных данных

## Данные пользователя

### Обязательные поля
- **Имя пользователя** - текстовое поле, введенное в начале онбординга
- **Дата рождения** - выбирается через DatePicker
- **Интересы** - список выбранных категорий

### Опциональные поля
- **Время рождения** - можно пропустить в онбординге
- **Дата создания профиля** - автоматически устанавливается при первом сохранении
- **Дата последнего обновления** - обновляется при каждом изменении

## Использование

### Получение профиля пользователя
```dart
final userService = UserService();
final profile = await userService.getUserProfile();

if (profile != null) {
  print('Имя: ${profile.name}');
  print('Возраст: ${profile.age}');
  print('Интересы: ${profile.interestNames.join(', ')}');
}
```

### Проверка наличия профиля
```dart
final hasProfile = await userService.hasUserProfile();
final isComplete = await userService.isProfileComplete();
```

### Получение конкретных данных
```dart
final name = await userService.getUserName();
final age = await userService.getUserAge();
final interests = await userService.getUserInterests();
```

### Обновление профиля
```dart
final updatedProfile = profile.copyWith(name: 'Новое имя');
await userService.updateUserProfile(updatedProfile);
```

### Удаление профиля
```dart
await userService.deleteUserProfile(); // Также сбрасывает статус онбординга
```

## Интеграция с онбордингом

### Процесс сохранения
1. Пользователь проходит все этапы онбординга
2. В методе `saveInterests()` создается объект `UserProfile`
3. Профиль сохраняется через `UserProfileService`
4. Устанавливается флаг завершения онбординга

### Проверка при запуске приложения
1. В `App._checkOnboardingStatus()` проверяется статус онбординга
2. Если онбординг завершен, профиль предзагружается в кеш
3. Пользователь перенаправляется на соответствующий экран

## Отладка

### Отладочный экран
Используйте `UserProfileDebugScreen` для тестирования:
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const UserProfileDebugScreen(),
  ),
);
```

### Логирование
Все операции с профилем логируются с префиксом:
- `[UserService]` - высокоуровневые операции
- `[UserProfileService]` - низкоуровневые операции  
- `[OnboardMixin]` - операции в онбординге
- `[App]` - операции при запуске приложения

## Хранение данных

### Ключи SharedPreferences
- `user_profile` - JSON профиля пользователя
- `onboarding_completed` - флаг завершения онбординга

### Формат JSON
```json
{
  "name": "Имя пользователя",
  "birthDate": "1990-01-01T00:00:00.000Z",
  "birthTime": {
    "hour": 12,
    "minute": 30
  },
  "interests": [
    {"name": "爱情与关系"},
    {"name": "职业与事业"}
  ],
  "createdAt": "2024-01-01T10:00:00.000Z",
  "updatedAt": "2024-01-01T11:00:00.000Z"
}
```

## Безопасность

- Данные хранятся локально на устройстве
- Используется SharedPreferences (безопасно для пользовательских настроек)
- Нет передачи персональных данных на сервер (кроме DeepSeek анализа)
- При удалении приложения все данные удаляются автоматически

## Производительность

- **Кеширование**: профиль кешируется в памяти после первой загрузки
- **Ленивая загрузка**: профиль загружается только при необходимости
- **Принудительное обновление**: доступно через `forceRefresh: true`

## Примеры использования

### В других частях приложения
```dart
// В чате - получить имя для персонализации
final userName = await UserService().getUserName();
final greeting = 'Привет, $userName!';

// В аналитике - получить интересы для таргетинга
final interests = await UserService().getUserInterests();

// В настройках - показать полную информацию
final profile = await UserService().getUserProfile();
```

### Обработка ошибок
```dart
try {
  final profile = await userService.getUserProfile();
  // Используем профиль
} catch (e) {
  // Обрабатываем ошибку, например, профиль поврежден
  print('Ошибка загрузки профиля: $e');
  // Можно предложить пользователю пройти онбординг заново
}
``` 