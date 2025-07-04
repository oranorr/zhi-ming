# Страница профиля пользователя

Красивая и современная страница профиля, выполненная в соответствии с принципами Apple Human Interface Guidelines.

## 🎨 Дизайн

### Стиль Apple HIG
- **Минималистичный дизайн** - чистые линии, много белого пространства
- **Градиентные элементы** - красивые переходы цветов
- **Мягкие тени** - создают ощущение глубины
- **Скругленные углы** - современный внешний вид
- **Плавные анимации** - приятные переходы

### Цветовая схема
- Основные цвета: фиолетовый и розовый градиенты
- Текст: черный для основного, серый для вспомогательного
- Фон: светло-серый (`Colors.grey[50]`)
- Акценты: используются цвета из `ZColors`

## 📱 Функциональность

### Основные секции

1. **Заголовок с градиентом**
   - SliverAppBar с красивым градиентным фоном
   - Плавное поведение при прокрутке

2. **Карточка профиля**
   - Круглый аватар с инициалом имени
   - Отображение имени и возраста
   - Чипы с датой и временем рождения
   - Мягкие тени для глубины

3. **Секция настроек**
   - Редактирование профиля (пока не реализовано)
   - Настройки темы (пока не реализовано)

4. **Секция информации**
   - Просмотр интересов пользователя
   - Информация о приложении

5. **Секция действий**
   - Отладочная информация (переход к `UserProfileDebugScreen`)
   - Сброс профиля (с подтверждением)

### Интерактивные элементы

- **Диалог интересов** - показывает список выбранных интересов
- **Диалог информации о приложении** - версия и сборка
- **Подтверждение сброса** - безопасное удаление данных
- **SnackBar уведомления** - обратная связь пользователю

## 🔧 Техническая реализация

### Состояния экрана
1. **Загрузка** - CircularProgressIndicator с текстом
2. **Данные загружены** - полный интерфейс профиля
3. **Ошибка/профиль не найден** - предложение пройти онбординг

### Анимации
- **FadeTransition** - плавное появление контента
- **AnimationController** - управление анимациями
- **Cascade operators** - используются где возможно

### Интеграция с системой профиля
- Использует `UserService` для получения данных
- Автоматическое обновление при изменениях
- Кеширование для производительности

## 📱 Навигация

### Интеграция в HomeScreen
- Третья вкладка в `PageView`
- Заменяет простой `Container` с текстом 'user'
- Плавные переходы между вкладками

### Переходы между экранами
- К экрану отладки профиля
- К онбордингу при сбросе
- К диалогам настроек

## 🌐 Локализация

### Китайский язык (основной)
- Все тексты на китайском языке
- Соответствует общему стилю приложения

### Комментарии на русском
- Подробные комментарии в коде
- Объяснения функциональности
- Логирование с русскими сообщениями

## 🎯 Особенности UX

### Обратная связь пользователю
- Уведомления о не реализованных функциях
- Подтверждения деструктивных действий
- Информативные сообщения об ошибках

### Производительность
- Ленивая загрузка данных
- Кеширование профиля
- Оптимизированные анимации

### Доступность
- Семантически правильная структура
- Подходящие размеры touch targets
- Контрастные цвета

## 🔮 Будущие улучшения

### Планируемые функции
1. **Редактирование профиля**
   - Изменение имени
   - Обновление даты рождения
   - Редактирование интересов

2. **Настройки темы**
   - Светлая/темная тема
   - Выбор акцентных цветов
   - Размер шрифта

3. **Дополнительные настройки**
   - Уведомления
   - Конфиденциальность
   - Экспорт данных

### Технические улучшения
- Добавление тестов
- Улучшение анимаций
- Оптимизация производительности

## 📁 Структура файлов

```
lib/features/profile/
├── presentation/
│   └── profile_page.dart           # Основная страница профиля
└── README.md                       # Эта документация

docs/
├── profile_page_features.md        # Документация функций
└── user_profile_system.md          # Документация системы профиля
```

## 🚀 Использование

### Навигация к странице
```dart
// Через HomeScreen (автоматически)
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const HomeScreen()),
);

// Напрямую
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const ProfilePage()),
);
```

### Пример кастомизации
```dart
// В будущем можно будет передавать параметры
ProfilePage(
  showDebugOptions: true,
  allowProfileReset: true,
)
``` 