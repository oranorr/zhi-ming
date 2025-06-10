import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhi_ming/features/chat/domain/message_entity.dart';

/// Сервис для работы с единственным чатом Ба-Дзы пользователя
/// Отдельно хранится от обычной истории чатов
class BaDzyChatService {
  static const String _badzyMessagesKey = 'badzy_chat_messages';
  static const String _badzyLastUpdatedKey = 'badzy_chat_last_updated';
  static const String _badzyHoroscopeKey = 'badzy_horoscope';
  static const String _badzyHoroscopeDateKey = 'badzy_horoscope_date';

  /// Загрузка сообщений чата Ба-Дзы
  Future<List<MessageEntity>> loadBaDzyMessages() async {
    try {
      debugPrint('[BaDzyChatService] Загружаем сообщения чата Ба-Дзы');

      final prefs = await SharedPreferences.getInstance();
      final messagesJson = prefs.getString(_badzyMessagesKey);

      if (messagesJson == null) {
        debugPrint(
          '[BaDzyChatService] Чат Ба-Дзы не найден, возвращаем пустой список',
        );
        return [];
      }

      final List<dynamic> messagesList = json.decode(messagesJson);
      final messages =
          messagesList
              .map(
                (jsonItem) =>
                    MessageEntity.fromMap(jsonItem as Map<String, dynamic>),
              )
              .toList();

      debugPrint(
        '[BaDzyChatService] Загружено ${messages.length} сообщений Ба-Дзы',
      );
      return messages;
    } catch (e, stackTrace) {
      debugPrint('[BaDzyChatService] ОШИБКА при загрузке чата Ба-Дзы: $e');
      debugPrint('[BaDzyChatService] StackTrace: $stackTrace');
      return [];
    }
  }

  /// Сохранение сообщений чата Ба-Дзы
  Future<bool> saveBaDzyMessages(List<MessageEntity> messages) async {
    try {
      debugPrint(
        '[BaDzyChatService] Сохраняем ${messages.length} сообщений Ба-Дзы',
      );

      final prefs = await SharedPreferences.getInstance();

      // Конвертируем сообщения в JSON
      final messagesJson = json.encode(
        messages.map((message) => message.toMap()).toList(),
      );

      // Сохраняем сообщения и время последнего обновления
      final success = await prefs.setString(_badzyMessagesKey, messagesJson);
      await prefs.setString(
        _badzyLastUpdatedKey,
        DateTime.now().toIso8601String(),
      );

      if (success) {
        debugPrint('[BaDzyChatService] Чат Ба-Дзы успешно сохранен');
      } else {
        debugPrint('[BaDzyChatService] ОШИБКА при сохранении чата Ба-Дзы');
      }

      return success;
    } catch (e, stackTrace) {
      debugPrint('[BaDzyChatService] ОШИБКА при сохранении чата Ба-Дзы: $e');
      debugPrint('[BaDzyChatService] StackTrace: $stackTrace');
      return false;
    }
  }

  /// Добавление нового сообщения к чату Ба-Дзы
  Future<bool> addMessageToBaDzyChat(MessageEntity message) async {
    try {
      debugPrint('[BaDzyChatService] Добавляем новое сообщение в чат Ба-Дзы');

      // Загружаем существующие сообщения
      final existingMessages = await loadBaDzyMessages();

      // [BaDzyChatService] Проверяем на дублирование сообщений
      // Ищем сообщение с тем же текстом, автором и временем (±1 секунда)
      final isDuplicate = existingMessages.any((existingMessage) {
        final textMatches = existingMessage.text == message.text;
        final authorMatches = existingMessage.isMe == message.isMe;
        final timeDiff =
            existingMessage.timestamp
                .difference(message.timestamp)
                .inSeconds
                .abs();
        final timeMatches = timeDiff <= 1; // Разрешаем разницу в 1 секунду

        return textMatches && authorMatches && timeMatches;
      });

      if (isDuplicate) {
        debugPrint(
          '[BaDzyChatService] Сообщение уже существует, пропускаем дублирование',
        );

        // Если это обновление isStreaming статуса, обновляем существующее сообщение
        if (!message.isStreaming) {
          final updatedMessages =
              existingMessages.map((existingMessage) {
                final textMatches = existingMessage.text == message.text;
                final authorMatches = existingMessage.isMe == message.isMe;
                final timeDiff =
                    existingMessage.timestamp
                        .difference(message.timestamp)
                        .inSeconds
                        .abs();
                final timeMatches = timeDiff <= 1;

                if (textMatches &&
                    authorMatches &&
                    timeMatches &&
                    existingMessage.isStreaming) {
                  debugPrint(
                    '[BaDzyChatService] Обновляем isStreaming статус сообщения',
                  );
                  return existingMessage.copyWith(isStreaming: false);
                }
                return existingMessage;
              }).toList();

          return await saveBaDzyMessages(updatedMessages);
        }

        return true; // Возвращаем успех, так как сообщение уже есть
      }

      // Добавляем новое сообщение в начало списка (как в чате)
      final updatedMessages = [message, ...existingMessages];

      // Сохраняем обновленный список
      return await saveBaDzyMessages(updatedMessages);
    } catch (e, stackTrace) {
      debugPrint('[BaDzyChatService] ОШИБКА при добавлении сообщения: $e');
      debugPrint('[BaDzyChatService] StackTrace: $stackTrace');
      return false;
    }
  }

  /// Очистка чата Ба-Дзы
  Future<bool> clearBaDzyChat() async {
    try {
      debugPrint('[BaDzyChatService] Очищаем чат Ба-Дзы');

      final prefs = await SharedPreferences.getInstance();

      final success1 = await prefs.remove(_badzyMessagesKey);
      final success2 = await prefs.remove(_badzyLastUpdatedKey);

      // [BaDzyChatService] Также очищаем гороскоп при очистке чата
      final success3 = await prefs.remove(_badzyHoroscopeKey);
      final success4 = await prefs.remove(_badzyHoroscopeDateKey);

      final allSuccess = success1 && success2 && success3 && success4;

      if (allSuccess) {
        debugPrint('[BaDzyChatService] Чат Ба-Дзы и гороскоп успешно очищены');
      } else {
        debugPrint(
          '[BaDzyChatService] ОШИБКА при очистке чата Ба-Дзы или гороскопа',
        );
      }

      return allSuccess;
    } catch (e, stackTrace) {
      debugPrint('[BaDzyChatService] ОШИБКА при очистке чата Ба-Дзы: $e');
      debugPrint('[BaDzyChatService] StackTrace: $stackTrace');
      return false;
    }
  }

  /// Получение времени последнего обновления чата Ба-Дзы
  Future<DateTime?> getLastUpdated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdatedString = prefs.getString(_badzyLastUpdatedKey);

      if (lastUpdatedString == null) {
        return null;
      }

      return DateTime.parse(lastUpdatedString);
    } catch (e) {
      debugPrint(
        '[BaDzyChatService] ОШИБКА при получении времени обновления: $e',
      );
      return null;
    }
  }

  /// Сохранение гороскопа Ба-Дзы (интерпретации)
  Future<bool> saveBaDzyHoroscope(MessageEntity horoscopeMessage) async {
    try {
      debugPrint('[BaDzyChatService] Сохраняем гороскоп Ба-Дзы');

      final prefs = await SharedPreferences.getInstance();

      // Сохраняем сообщение с гороскопом
      final horoscopeJson = json.encode(horoscopeMessage.toMap());
      final success1 = await prefs.setString(_badzyHoroscopeKey, horoscopeJson);

      // Сохраняем дату создания гороскопа
      final success2 = await prefs.setString(
        _badzyHoroscopeDateKey,
        DateTime.now().toIso8601String(),
      );

      if (success1 && success2) {
        debugPrint('[BaDzyChatService] Гороскоп Ба-Дзы успешно сохранен');
      } else {
        debugPrint('[BaDzyChatService] ОШИБКА при сохранении гороскопа Ба-Дзы');
      }

      return success1 && success2;
    } catch (e, stackTrace) {
      debugPrint(
        '[BaDzyChatService] ОШИБКА при сохранении гороскопа Ба-Дзы: $e',
      );
      debugPrint('[BaDzyChatService] StackTrace: $stackTrace');
      return false;
    }
  }

  /// Загрузка гороскопа Ба-Дзы
  Future<MessageEntity?> loadBaDzyHoroscope() async {
    try {
      debugPrint('[BaDzyChatService] Загружаем гороскоп Ба-Дзы');

      final prefs = await SharedPreferences.getInstance();
      final horoscopeJson = prefs.getString(_badzyHoroscopeKey);

      if (horoscopeJson == null) {
        debugPrint('[BaDzyChatService] Гороскоп Ба-Дзы не найден');
        return null;
      }

      final horoscopeMap = json.decode(horoscopeJson) as Map<String, dynamic>;
      final horoscopeMessage = MessageEntity.fromMap(horoscopeMap);

      debugPrint('[BaDzyChatService] Гороскоп Ба-Дзы успешно загружен');
      return horoscopeMessage;
    } catch (e, stackTrace) {
      debugPrint('[BaDzyChatService] ОШИБКА при загрузке гороскопа Ба-Дзы: $e');
      debugPrint('[BaDzyChatService] StackTrace: $stackTrace');
      return null;
    }
  }

  /// Получение даты создания гороскопа
  Future<DateTime?> getBaDzyHoroscopeDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateString = prefs.getString(_badzyHoroscopeDateKey);

      if (dateString == null) {
        return null;
      }

      return DateTime.parse(dateString);
    } catch (e) {
      debugPrint('[BaDzyChatService] ОШИБКА при получении даты гороскопа: $e');
      return null;
    }
  }

  /// Проверка существования гороскопа Ба-Дзы
  Future<bool> hasBaDzyHoroscope() async {
    try {
      final horoscope = await loadBaDzyHoroscope();
      return horoscope != null;
    } catch (e) {
      return false;
    }
  }

  /// Очистка гороскопа Ба-Дзы (используется при очистке всего чата)
  Future<bool> clearBaDzyHoroscope() async {
    try {
      debugPrint('[BaDzyChatService] Очищаем гороскоп Ба-Дзы');

      final prefs = await SharedPreferences.getInstance();

      final success1 = await prefs.remove(_badzyHoroscopeKey);
      final success2 = await prefs.remove(_badzyHoroscopeDateKey);

      if (success1 && success2) {
        debugPrint('[BaDzyChatService] Гороскоп Ба-Дзы успешно очищен');
      } else {
        debugPrint('[BaDzyChatService] ОШИБКА при очистке гороскопа Ба-Дзы');
      }

      return success1 && success2;
    } catch (e, stackTrace) {
      debugPrint('[BaDzyChatService] ОШИБКА при очистке гороскопа Ба-Дзы: $e');
      debugPrint('[BaDzyChatService] StackTrace: $stackTrace');
      return false;
    }
  }

  /// Проверка существования чата Ба-Дзы
  Future<bool> hasBaDzyChat() async {
    try {
      final messages = await loadBaDzyMessages();
      return messages.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
