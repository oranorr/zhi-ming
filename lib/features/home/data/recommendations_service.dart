import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhi_ming/core/services/deepseek/deepseek_service.dart';
import 'package:zhi_ming/features/history/data/chat_history_service.dart';
import 'package:zhi_ming/features/onboard/data/onboard_repo.dart';
import 'package:zhi_ming/features/onboard/data/user_profile_service.dart';
import 'package:zhi_ming/features/home/domain/question_entity.dart';
import 'package:zhi_ming/core/theme/theme_colors.dart';

/// Модель для одной рекомендации от DeepSeek
class RecommendationCard {
  const RecommendationCard({required this.question, required this.description});

  factory RecommendationCard.fromJson(Map<String, dynamic> json) {
    return RecommendationCard(
      question: json['question'] as String,
      description: json['description'] as String,
    );
  }

  /// Вопрос для карточки
  final String question;

  /// Описание карточки
  final String description;

  Map<String, dynamic> toJson() {
    return {'question': question, 'description': description};
  }

  @override
  String toString() {
    return 'RecommendationCard(question: $question, description: $description)';
  }
}

/// Модель для сохранения рекомендаций в локальном хранилище
class SavedRecommendations {
  const SavedRecommendations({
    required this.recommendations,
    required this.generatedAt,
    required this.userInterests,
    required this.deviceLanguage,
  });

  factory SavedRecommendations.fromJson(Map<String, dynamic> json) {
    return SavedRecommendations(
      recommendations:
          (json['recommendations'] as List<dynamic>)
              .map(
                (item) =>
                    RecommendationCard.fromJson(item as Map<String, dynamic>),
              )
              .toList(),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      userInterests:
          (json['userInterests'] as List<dynamic>)
              .map((item) => item as String)
              .toList(),
      deviceLanguage: json['deviceLanguage'] as String,
    );
  }

  /// Список рекомендаций
  final List<RecommendationCard> recommendations;

  /// Время генерации
  final DateTime generatedAt;

  /// Интересы пользователя на момент генерации
  final List<String> userInterests;

  /// Язык устройства
  final String deviceLanguage;

  Map<String, dynamic> toJson() {
    return {
      'recommendations': recommendations.map((r) => r.toJson()).toList(),
      'generatedAt': generatedAt.toIso8601String(),
      'userInterests': userInterests,
      'deviceLanguage': deviceLanguage,
    };
  }

  @override
  String toString() {
    return 'SavedRecommendations(count: ${recommendations.length}, generatedAt: $generatedAt, interests: $userInterests)';
  }
}

/// Сервис для работы с рекомендациями и генерацией контента
/// на основе интересов пользователя
class RecommendationsService {
  factory RecommendationsService() => _instance;
  RecommendationsService._internal();

  /// Singleton instance
  static final RecommendationsService _instance =
      RecommendationsService._internal();

  // Ключи для SharedPreferences
  static const String _mainRecommendationsKey =
      'main_recommendations'; // Основные рекомендации (для домашнего экрана)
  static const String _newRecommendationsKey =
      'new_recommendations'; // Новые рекомендации (после гадания)

  final UserProfileService _userProfileService = UserProfileService();
  final ChatHistoryService _chatHistoryService = ChatHistoryService();
  final DeepSeekService _deepSeekService = DeepSeekService();

  /// Цветовые пары для карточек (как в HomeLocalRepo)
  final List<Map<String, Color>> _colorPairs = [
    {'back': ZColors.blueLight, 'arrow': ZColors.blueMiddle},
    {'back': ZColors.pinkMiddle, 'arrow': ZColors.pinkDark},
    {'back': ZColors.yellowLight, 'arrow': ZColors.yellowMiddle},
    {'back': ZColors.purpleLight, 'arrow': ZColors.purpleMiddle},
  ];

  /// Кэш последних сгенерированных QuestionEntity
  List<QuestionEntity> _cachedQuestionEntities = [];

  /// Получает сгенерированные QuestionEntity (для использования в HomePage)
  List<QuestionEntity> getQuestionEntities() {
    return _cachedQuestionEntities;
  }

  /// Проверяет, есть ли сохраненные основные рекомендации
  Future<bool> hasSavedRecommendations() async {
    final saved = await _loadMainRecommendations();
    return saved != null;
  }

  /// Очищает все рекомендации (публичный метод)
  Future<bool> clearRecommendations() async {
    debugPrint('[RecommendationsService] Очистка всех рекомендаций');
    _cachedQuestionEntities.clear();
    await _clearMainRecommendations();
    await _clearNewRecommendations();
    return true;
  }

  /// Проверяет новое хранилище и переносит его содержимое в основное при наличии
  Future<void> _checkAndPromoteNewRecommendations() async {
    try {
      debugPrint(
        '[RecommendationsService] Проверяем наличие новых рекомендаций при старте',
      );

      // Загружаем новые рекомендации
      final newRecommendations = await _loadNewRecommendations();

      if (newRecommendations != null) {
        debugPrint(
          '[RecommendationsService] 🔄 НАЙДЕНЫ новые рекомендации! Переносим их в основное хранилище',
        );
        debugPrint(
          '[RecommendationsService] Количество новых рекомендаций: ${newRecommendations.recommendations.length}',
        );

        // Выводим содержимое новых рекомендаций перед переносом
        debugPrint('[RecommendationsService] СОДЕРЖИМОЕ новых рекомендаций:');
        for (int i = 0; i < newRecommendations.recommendations.length; i++) {
          final rec = newRecommendations.recommendations[i];
          debugPrint('[RecommendationsService] ${i + 1}. "${rec.question}"');
          debugPrint(
            '[RecommendationsService]    Описание: ${rec.description}',
          );
        }

        // Переносим новые рекомендации в основное хранилище
        final promoted = await _saveMainRecommendations(newRecommendations);

        if (promoted) {
          debugPrint(
            '[RecommendationsService] ✅ Новые рекомендации успешно перенесены в основное хранилище',
          );

          // Очищаем новое хранилище после успешного переноса
          final cleared = await _clearNewRecommendations();

          if (cleared) {
            debugPrint('[RecommendationsService] 🗑️ Новое хранилище очищено');
          } else {
            debugPrint(
              '[RecommendationsService] ⚠️ Ошибка при очистке нового хранилища',
            );
          }
        } else {
          debugPrint(
            '[RecommendationsService] ❌ Ошибка при переносе новых рекомендаций',
          );
        }
      } else {
        debugPrint(
          '[RecommendationsService] Новые рекомендации не найдены - ничего не переносим',
        );
      }
    } catch (e) {
      debugPrint(
        '[RecommendationsService] Ошибка при проверке и переносе новых рекомендаций: $e',
      );
    }
  }

  /// Инициализация сервиса - проверяет новые рекомендации и переносит их в основные
  Future<void> initialize() async {
    debugPrint('[RecommendationsService] Инициализация сервиса');

    // Сначала проверяем есть ли новые рекомендации
    await _checkAndPromoteNewRecommendations();

    // Затем загружаем основные рекомендации
    await _loadMainRecommendations();
  }

  /// Сохранение рекомендаций в основное хранилище (main)
  Future<bool> _saveMainRecommendations(
    SavedRecommendations savedRecommendations,
  ) async {
    try {
      debugPrint(
        '[RecommendationsService] Сохранение ОСНОВНЫХ рекомендаций в локальное хранилище',
      );

      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(savedRecommendations.toJson());
      await prefs.setString(_mainRecommendationsKey, json);

      debugPrint(
        '[RecommendationsService] Основные рекомендации сохранены: ${savedRecommendations.recommendations.length} элементов',
      );
      return true;
    } catch (e) {
      debugPrint(
        '[RecommendationsService] Ошибка при сохранении основных рекомендаций: $e',
      );
      return false;
    }
  }

  /// Сохранение рекомендаций в новое хранилище (new)
  Future<bool> _saveNewRecommendations(
    SavedRecommendations savedRecommendations,
  ) async {
    try {
      debugPrint(
        '[RecommendationsService] Сохранение НОВЫХ рекомендаций в локальное хранилище',
      );

      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(savedRecommendations.toJson());
      await prefs.setString(_newRecommendationsKey, json);

      debugPrint(
        '[RecommendationsService] Новые рекомендации сохранены: ${savedRecommendations.recommendations.length} элементов',
      );
      return true;
    } catch (e) {
      debugPrint(
        '[RecommendationsService] Ошибка при сохранении новых рекомендаций: $e',
      );
      return false;
    }
  }

  /// Загрузка основных рекомендаций из локального хранилища (main)
  Future<SavedRecommendations?> _loadMainRecommendations() async {
    try {
      debugPrint(
        '[RecommendationsService] Загрузка ОСНОВНЫХ сохраненных рекомендаций',
      );

      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_mainRecommendationsKey);

      if (jsonString == null) {
        debugPrint('[RecommendationsService] Основные рекомендации не найдены');
        return null;
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final savedRecommendations = SavedRecommendations.fromJson(json);

      debugPrint(
        '[RecommendationsService] Загружены основные рекомендации: ${savedRecommendations.recommendations.length} элементов',
      );

      // Преобразуем в QuestionEntity и сохраняем в кэш
      final questionEntities = _createQuestionEntitiesFromRecommendations(
        savedRecommendations.recommendations,
      );
      _cachedQuestionEntities = questionEntities;

      debugPrint(
        '[RecommendationsService] Основные рекомендации загружены в кэш: ${questionEntities.length} карточек',
      );

      return savedRecommendations;
    } catch (e) {
      debugPrint(
        '[RecommendationsService] Ошибка при загрузке основных рекомендаций: $e',
      );
      return null;
    }
  }

  /// Загрузка новых рекомендаций из локального хранилища (new)
  Future<SavedRecommendations?> _loadNewRecommendations() async {
    try {
      debugPrint(
        '[RecommendationsService] Загрузка НОВЫХ сохраненных рекомендаций',
      );

      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_newRecommendationsKey);

      if (jsonString == null) {
        debugPrint('[RecommendationsService] Новые рекомендации не найдены');
        return null;
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final savedRecommendations = SavedRecommendations.fromJson(json);

      debugPrint(
        '[RecommendationsService] Загружены новые рекомендации: ${savedRecommendations.recommendations.length} элементов',
      );

      return savedRecommendations;
    } catch (e) {
      debugPrint(
        '[RecommendationsService] Ошибка при загрузке новых рекомендаций: $e',
      );
      return null;
    }
  }

  /// Очистка основных рекомендаций
  Future<bool> _clearMainRecommendations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_mainRecommendationsKey);
      debugPrint('[RecommendationsService] Основные рекомендации очищены');
      return true;
    } catch (e) {
      debugPrint(
        '[RecommendationsService] Ошибка при очистке основных рекомендаций: $e',
      );
      return false;
    }
  }

  /// Очистка новых рекомендаций
  Future<bool> _clearNewRecommendations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_newRecommendationsKey);
      debugPrint('[RecommendationsService] Новые рекомендации очищены');
      return true;
    } catch (e) {
      debugPrint(
        '[RecommendationsService] Ошибка при очистке новых рекомендаций: $e',
      );
      return false;
    }
  }

  /// Получает язык устройства пользователя
  String _getDeviceLanguage() {
    try {
      // Получаем только языковой код без страны
      final locale = PlatformDispatcher.instance.locale;
      return locale.languageCode;
    } catch (e) {
      return 'en'; // По умолчанию английский
    }
  }

  /// Получает интересы пользователя из профиля
  /// Возвращает список интересов или пустой список если профиль не найден
  Future<List<Interest>> getUserInterests() async {
    try {
      debugPrint('[RecommendationsService] Получаем интересы пользователя');

      final userProfile = await _userProfileService.loadUserProfile();

      if (userProfile != null) {
        debugPrint(
          '[RecommendationsService] Профиль пользователя найден: ${userProfile.name}',
        );
        debugPrint(
          '[RecommendationsService] Количество интересов: ${userProfile.interests.length}',
        );

        // Выводим каждый интерес в консоль
        for (int i = 0; i < userProfile.interests.length; i++) {
          final interest = userProfile.interests[i];
          debugPrint('[RecommendationsService] ${i + 1}. ${interest.name}');
        }

        return userProfile.interests;
      } else {
        debugPrint('[RecommendationsService] Профиль пользователя не найден');
        return [];
      }
    } catch (e) {
      debugPrint('[RecommendationsService] Ошибка при получении интересов: $e');
      return [];
    }
  }

  /// Получает все главные вопросы из истории чатов
  /// Возвращает список строк с вопросами, отсортированных по дате создания
  Future<List<String>> getChatHistoryQuestions() async {
    try {
      debugPrint('[RecommendationsService] Получаем историю вопросов из чатов');

      final allChats = await _chatHistoryService.getAllChats();

      if (allChats.isNotEmpty) {
        debugPrint(
          '[RecommendationsService] Найдено ${allChats.length} чатов в истории',
        );

        // Извлекаем mainQuestion из каждого чата
        final questions = allChats.map((chat) => chat.mainQuestion).toList();

        // Выводим каждый вопрос в консоль
        for (int i = 0; i < questions.length; i++) {
          final question = questions[i];
          final chatDate = allChats[i].createdAt;
          debugPrint(
            '[RecommendationsService] ${i + 1}. "$question" (${chatDate.day}/${chatDate.month}/${chatDate.year})',
          );
        }

        return questions;
      } else {
        debugPrint('[RecommendationsService] История чатов пуста');
        return [];
      }
    } catch (e) {
      debugPrint(
        '[RecommendationsService] Ошибка при получении истории вопросов: $e',
      );
      return [];
    }
  }

  /// Получает интересы пользователя тихо (без логов)
  Future<List<Interest>> _getUserInterestsQuiet() async {
    try {
      final userProfile = await _userProfileService.loadUserProfile();
      return userProfile?.interests ?? [];
    } catch (e) {
      return [];
    }
  }

  /// Получает историю вопросов тихо (без логов)
  Future<List<String>> _getChatHistoryQuestionsQuiet() async {
    try {
      final allChats = await _chatHistoryService.getAllChats();
      return allChats.map((chat) => chat.mainQuestion).toList();
    } catch (e) {
      return [];
    }
  }

  /// Проверяет, есть ли у пользователя профиль с интересами
  Future<bool> hasUserProfile() async {
    try {
      return await _userProfileService.hasUserProfile();
    } catch (e) {
      debugPrint('[RecommendationsService] Ошибка при проверке профиля: $e');
      return false;
    }
  }

  /// Парсит JSON ответ от DeepSeek и извлекает рекомендации
  List<RecommendationCard> _parseDeepSeekResponse(String response) {
    try {
      debugPrint(
        '[RecommendationsService] Начинаем парсинг ответа от DeepSeek',
      );

      // Извлекаем JSON из возможного markdown блока
      String jsonString = _extractJsonFromResponse(response);

      debugPrint(
        '[RecommendationsService] Извлеченный JSON (первые 200 символов): ${jsonString.length > 200 ? "${jsonString.substring(0, 200)}..." : jsonString}',
      );

      final Map<String, dynamic> json = jsonDecode(jsonString);

      if (json.containsKey('recommendations') &&
          json['recommendations'] is List) {
        final List<dynamic> recommendationsList = json['recommendations'];

        debugPrint(
          '[RecommendationsService] Найдено рекомендаций в JSON: ${recommendationsList.length}',
        );

        return recommendationsList
            .map(
              (item) =>
                  RecommendationCard.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      } else {
        debugPrint(
          '[RecommendationsService] Неверный формат ответа от DeepSeek: отсутствует поле recommendations',
        );
        debugPrint(
          '[RecommendationsService] Ключи в JSON: ${json.keys.toList()}',
        );
        return [];
      }
    } catch (e) {
      debugPrint(
        '[RecommendationsService] Ошибка при парсинге ответа от DeepSeek: $e',
      );
      debugPrint(
        '[RecommendationsService] Исходный ответ (первые 500 символов): ${response.length > 500 ? "${response.substring(0, 500)}..." : response}',
      );
      return [];
    }
  }

  /// Извлекает JSON из ответа, удаляя markdown обертки если они есть
  String _extractJsonFromResponse(String response) {
    // Убираем лишние пробелы в начале и конце
    String cleaned = response.trim();

    // Проверяем, начинается ли ответ с markdown блока кода
    if (cleaned.startsWith('```json')) {
      debugPrint(
        '[RecommendationsService] Обнаружен markdown блок кода, извлекаем JSON',
      );

      // Ищем начало JSON (после ```json и возможного переноса строки)
      int startIndex = cleaned.indexOf('```json') + 7;

      // Пропускаем возможные переносы строк после ```json
      while (startIndex < cleaned.length &&
          (cleaned[startIndex] == '\n' || cleaned[startIndex] == '\r')) {
        startIndex++;
      }

      // Ищем конец JSON (до closing ```)
      int endIndex = cleaned.lastIndexOf('```');

      if (endIndex > startIndex) {
        String extractedJson = cleaned.substring(startIndex, endIndex).trim();
        debugPrint('[RecommendationsService] JSON извлечен из markdown блока');
        return extractedJson;
      } else {
        debugPrint(
          '[RecommendationsService] Не найден закрывающий markdown блок, возвращаем исходный ответ',
        );
        return cleaned;
      }
    }
    // Проверяем, есть ли просто ``` в начале (без json)
    else if (cleaned.startsWith('```')) {
      debugPrint(
        '[RecommendationsService] Обнаружен обычный markdown блок кода, извлекаем содержимое',
      );

      // Ищем начало содержимого (после ``` и возможного переноса строки)
      int startIndex = cleaned.indexOf('```') + 3;

      // Пропускаем возможные переносы строк
      while (startIndex < cleaned.length &&
          (cleaned[startIndex] == '\n' || cleaned[startIndex] == '\r')) {
        startIndex++;
      }

      // Ищем конец содержимого (до closing ```)
      int endIndex = cleaned.lastIndexOf('```');

      if (endIndex > startIndex) {
        String extractedContent =
            cleaned.substring(startIndex, endIndex).trim();
        debugPrint(
          '[RecommendationsService] Содержимое извлечено из markdown блока',
        );
        return extractedContent;
      } else {
        debugPrint(
          '[RecommendationsService] Не найден закрывающий markdown блок, возвращаем исходный ответ',
        );
        return cleaned;
      }
    }
    // Если markdown блоков нет, возвращаем как есть
    else {
      debugPrint(
        '[RecommendationsService] Markdown блоки не обнаружены, используем ответ как есть',
      );
      return cleaned;
    }
  }

  /// Преобразует рекомендации в QuestionEntity с цветовой схемой
  List<QuestionEntity> _createQuestionEntitiesFromRecommendations(
    List<RecommendationCard> recommendations,
  ) {
    final List<QuestionEntity> questionEntities = [];

    for (int i = 0; i < recommendations.length; i++) {
      final recommendation = recommendations[i];

      // Получаем цветовую пару циклически
      final colorPair = _colorPairs[i % _colorPairs.length];

      questionEntities.add(
        QuestionEntity(
          title: _truncateText(recommendation.question, 60),
          subtitle: _truncateText(recommendation.description, 80),
          backColor: colorPair['back']!,
          arrowColor: colorPair['arrow']!,
        ),
      );
    }

    return questionEntities;
  }

  /// Обрезает текст до указанной длины с добавлением многоточия
  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    }

    // Ищем последний пробел перед максимальной длиной для красивого обрезания
    int cutIndex = maxLength;
    final lastSpaceIndex = text.lastIndexOf(' ', maxLength);

    if (lastSpaceIndex > maxLength * 0.7) {
      // Если пробел находится не слишком близко к началу, используем его
      cutIndex = lastSpaceIndex;
    }

    final truncatedText = '${text.substring(0, cutIndex).trim()}...';

    // Логируем обрезание длинных текстов
    debugPrint(
      '[RecommendationsService] Обрезан текст: "${text.substring(0, 30)}..." → "${truncatedText.substring(0, 30)}..."',
    );

    return truncatedText;
  }

  /// Генерирует рекомендации карточек через DeepSeek агент
  Future<RecommendationResult> regenerateRecommendations() async {
    try {
      // Получаем язык устройства
      final deviceLanguage = _getDeviceLanguage();

      // Получаем все вопросы из истории чатов (без логов)
      final historyQuestions = await _getChatHistoryQuestionsQuiet();

      // Получаем интересы пользователя (без логов)
      final interests = await _getUserInterestsQuiet();

      // Формируем JSON для отправки в DeepSeek
      final jsonInput = {
        'language': deviceLanguage,
        'interests': interests.map((interest) => interest.name).toList(),
        'recent_questions': historyQuestions,
      };

      // Выводим входной JSON
      debugPrint('[RecommendationsService] Отправляем в DeepSeek:');
      debugPrint(jsonEncode(jsonInput));

      // Отправляем в DeepSeek агент recommendator
      final response = await _deepSeekService.sendMessage(
        agentType: AgentType.recommendator,
        message: jsonEncode(jsonInput),
      );

      // Выводим результат от DeepSeek
      debugPrint('[RecommendationsService] Результат от DeepSeek:');
      debugPrint(response);

      // Парсим ответ от DeepSeek
      final recommendationCards = _parseDeepSeekResponse(response);
      debugPrint(
        '[RecommendationsService] Распарсено ${recommendationCards.length} рекомендаций',
      );

      // Создаем QuestionEntity из рекомендаций
      final questionEntities = _createQuestionEntitiesFromRecommendations(
        recommendationCards,
      );
      debugPrint(
        '[RecommendationsService] Создано ${questionEntities.length} QuestionEntity',
      );

      // Обновляем кэш последних сгенерированных QuestionEntity
      _cachedQuestionEntities = questionEntities;

      // Сохраняем рекомендации в основное хранилище
      final savedRecommendations = SavedRecommendations(
        recommendations: recommendationCards,
        generatedAt: DateTime.now(),
        userInterests: interests.map((i) => i.name).toList(),
        deviceLanguage: deviceLanguage,
      );

      await _saveMainRecommendations(savedRecommendations);

      return RecommendationResult(
        success: true,
        message: 'Рекомендации сгенерированы успешно',
        interestsCount: interests.length,
        interests: interests,
        deviceLocale: deviceLanguage,
        historyQuestions: historyQuestions,
        recommendationCards: recommendationCards,
        questionEntities: questionEntities,
      );
    } catch (e) {
      debugPrint(
        '[RecommendationsService] Ошибка при генерации рекомендаций: $e',
      );
      return RecommendationResult(
        success: false,
        message: 'Ошибка при регенерации: $e',
        interestsCount: 0,
        deviceLocale: 'error',
      );
    }
  }

  /// Генерирует первичные рекомендации специально для нового пользователя при онбординге
  /// Отличается от regenerateRecommendations тем, что оптимизирован для первого входа
  Future<RecommendationResult> generateInitialRecommendations({
    required List<Interest> userInterests,
    String? userName,
  }) async {
    try {
      debugPrint(
        '[RecommendationsService] Генерация первичных рекомендаций для онбординга',
      );
      debugPrint(
        '[RecommendationsService] Пользователь: ${userName ?? "неизвестно"}',
      );
      debugPrint(
        '[RecommendationsService] Интересы: ${userInterests.map((i) => i.name).join(", ")}',
      );

      // Получаем язык устройства
      final deviceLanguage = _getDeviceLanguage();

      // Для первичных рекомендаций НЕ используем историю вопросов
      // (поскольку пользователь новый)
      final jsonInput = {
        'language': deviceLanguage,
        'interests': userInterests.map((interest) => interest.name).toList(),
        'recent_questions': <String>[], // Пустой массив для новых пользователей
        'is_onboarding': true, // Специальный флаг для онбординга
      };

      // Выводим входной JSON
      debugPrint(
        '[RecommendationsService] Отправляем первичные данные в DeepSeek:',
      );
      debugPrint(jsonEncode(jsonInput));

      // Отправляем в DeepSeek агент recommendator
      final response = await _deepSeekService.sendMessage(
        agentType: AgentType.recommendator,
        message: jsonEncode(jsonInput),
      );

      // Выводим результат от DeepSeek
      debugPrint('[RecommendationsService] Первичный результат от DeepSeek:');
      debugPrint(response);

      // Парсим ответ от DeepSeek
      final recommendationCards = _parseDeepSeekResponse(response);
      debugPrint(
        '[RecommendationsService] Распарсено ${recommendationCards.length} первичных рекомендаций',
      );

      // Создаем QuestionEntity из рекомендаций
      final questionEntities = _createQuestionEntitiesFromRecommendations(
        recommendationCards,
      );
      debugPrint(
        '[RecommendationsService] Создано ${questionEntities.length} первичных QuestionEntity',
      );

      // Обновляем кэш последних сгенерированных QuestionEntity
      _cachedQuestionEntities = questionEntities;

      // Сохраняем первичные рекомендации в основное хранилище
      final savedRecommendations = SavedRecommendations(
        recommendations: recommendationCards,
        generatedAt: DateTime.now(),
        userInterests: userInterests.map((i) => i.name).toList(),
        deviceLanguage: deviceLanguage,
      );

      await _saveMainRecommendations(savedRecommendations);

      return RecommendationResult(
        success: true,
        message: 'Первичные рекомендации для онбординга сгенерированы успешно',
        interestsCount: userInterests.length,
        interests: userInterests,
        deviceLocale: deviceLanguage,
        historyQuestions: <String>[], // Пустой для нового пользователя
        recommendationCards: recommendationCards,
        questionEntities: questionEntities,
      );
    } catch (e) {
      debugPrint(
        '[RecommendationsService] Ошибка при генерации первичных рекомендаций: $e',
      );
      return RecommendationResult(
        success: false,
        message: 'Ошибка при генерации первичных рекомендаций: $e',
        interestsCount: userInterests.length,
        interests: userInterests,
        deviceLocale: 'error',
      );
    }
  }

  /// Генерирует новые рекомендации после гадания на И Дзин и сохраняет их в новое хранилище
  /// При этом выводит в консоль сравнение со старыми рекомендациями
  Future<RecommendationResult>
  generateNewRecommendationsAfterDivination() async {
    try {
      debugPrint(
        '[RecommendationsService] Генерация НОВЫХ рекомендаций после гадания на И Дзин',
      );

      // Загружаем старые (основные) рекомендации для сравнения
      final oldRecommendations = await _loadMainRecommendations();

      // Получаем интересы пользователя и историю вопросов
      final interests = await getUserInterests();
      final historyQuestions = await getChatHistoryQuestions();
      final deviceLanguage = _getDeviceLanguage();

      // Создаем JSON для отправки в DeepSeek
      final jsonInput = {
        'language': deviceLanguage,
        'interests': interests.map((interest) => interest.name).toList(),
        'recent_questions': historyQuestions,
        'is_onboarding': false, // Не онбординг
        'after_divination': true, // Флаг что это после гадания
      };

      debugPrint(
        '[RecommendationsService] Отправляем данные после гадания в DeepSeek:',
      );
      debugPrint(jsonEncode(jsonInput));

      // Отправляем в DeepSeek
      final response = await _deepSeekService.sendMessage(
        agentType: AgentType.recommendator,
        message: jsonEncode(jsonInput),
      );

      debugPrint(
        '[RecommendationsService] Результат новых рекомендаций от DeepSeek:',
      );
      debugPrint(response);

      // Парсим ответ
      final newRecommendationCards = _parseDeepSeekResponse(response);
      debugPrint(
        '[RecommendationsService] Распарсено ${newRecommendationCards.length} новых рекомендаций',
      );

      // Создаем объект для сохранения новых рекомендаций
      final newSavedRecommendations = SavedRecommendations(
        recommendations: newRecommendationCards,
        generatedAt: DateTime.now(),
        userInterests: interests.map((i) => i.name).toList(),
        deviceLanguage: deviceLanguage,
      );

      // Сохраняем в новое хранилище
      await _saveNewRecommendations(newSavedRecommendations);

      // Выводим сравнение старых и новых рекомендаций
      _compareOldAndNewRecommendations(
        oldRecommendations,
        newSavedRecommendations,
      );

      // Создаем QuestionEntity для новых рекомендаций (но НЕ обновляем кэш)
      final newQuestionEntities = _createQuestionEntitiesFromRecommendations(
        newRecommendationCards,
      );

      return RecommendationResult(
        success: true,
        message: 'Новые рекомендации после гадания сгенерированы успешно',
        interestsCount: interests.length,
        interests: interests,
        deviceLocale: deviceLanguage,
        historyQuestions: historyQuestions,
        recommendationCards: newRecommendationCards,
        questionEntities: newQuestionEntities,
      );
    } catch (e) {
      debugPrint(
        '[RecommendationsService] Ошибка при генерации новых рекомендаций после гадания: $e',
      );
      return RecommendationResult(
        success: false,
        message: 'Ошибка при генерации новых рекомендаций: $e',
        interestsCount: 0,
        deviceLocale: 'error',
      );
    }
  }

  /// Сравнивает старые и новые рекомендации и выводит результат в консоль
  void _compareOldAndNewRecommendations(
    SavedRecommendations? oldRecommendations,
    SavedRecommendations newRecommendations,
  ) {
    debugPrint('==================================================');
    debugPrint('[RecommendationsService] СРАВНЕНИЕ РЕКОМЕНДАЦИЙ');
    debugPrint('==================================================');

    if (oldRecommendations == null) {
      debugPrint('[RecommendationsService] СТАРЫЕ рекомендации НЕ НАЙДЕНЫ');
    } else {
      debugPrint(
        '[RecommendationsService] СТАРЫЕ рекомендации (${oldRecommendations.recommendations.length} шт.):',
      );
      for (int i = 0; i < oldRecommendations.recommendations.length; i++) {
        final rec = oldRecommendations.recommendations[i];
        debugPrint('[RecommendationsService] ${i + 1}. "${rec.question}"');
        debugPrint('[RecommendationsService]    Описание: ${rec.description}');
      }
    }

    debugPrint('--------------------------------------------------');
    debugPrint(
      '[RecommendationsService] НОВЫЕ рекомендации (${newRecommendations.recommendations.length} шт.):',
    );
    for (int i = 0; i < newRecommendations.recommendations.length; i++) {
      final rec = newRecommendations.recommendations[i];
      debugPrint('[RecommendationsService] ${i + 1}. "${rec.question}"');
      debugPrint('[RecommendationsService]    Описание: ${rec.description}');
    }

    debugPrint('==================================================');
    debugPrint('[RecommendationsService] КОНЕЦ СРАВНЕНИЯ');
    debugPrint('==================================================');
  }
}

/// Результат операции получения рекомендаций
class RecommendationResult {
  const RecommendationResult({
    required this.success,
    required this.message,
    required this.interestsCount,
    this.interests = const [],
    this.deviceLocale,
    this.historyQuestions = const [],
    this.recommendationCards = const [],
    this.questionEntities = const [],
  });

  /// Успешность операции
  final bool success;

  /// Сообщение о результате
  final String message;

  /// Количество найденных интересов
  final int interestsCount;

  /// Список интересов пользователя
  final List<Interest> interests;

  /// Локаль устройства пользователя
  final String? deviceLocale;

  /// Список всех главных вопросов из истории чатов
  final List<String> historyQuestions;

  /// Рекомендации от DeepSeek (сырые данные)
  final List<RecommendationCard> recommendationCards;

  /// Готовые QuestionEntity для отображения на главном экране
  final List<QuestionEntity> questionEntities;

  @override
  String toString() {
    return 'RecommendationResult(success: $success, message: $message, interestsCount: $interestsCount, deviceLocale: $deviceLocale, historyQuestionsCount: ${historyQuestions.length}, recommendationsCount: ${recommendationCards.length})';
  }
}
