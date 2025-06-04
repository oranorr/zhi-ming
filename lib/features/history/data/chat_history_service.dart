import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhi_ming/features/chat/domain/message_entity.dart';
import 'package:zhi_ming/features/history/domain/chat_history_entity.dart';

/// Сервис для работы с историей чатов
/// Сохраняет и загружает историю чатов из локального хранилища
class ChatHistoryService {
  static const String _historyKey = 'chat_history';
  static const String _currentChatIdKey = 'current_chat_id';

  /// Получение всех сохраненных чатов
  Future<List<ChatHistoryEntity>> getAllChats() async {
    try {
      debugPrint('[ChatHistoryService] Загружаем все чаты');
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_historyKey);

      if (historyJson == null) {
        debugPrint('[ChatHistoryService] История чатов пуста');
        return [];
      }

      final List<dynamic> historyList = jsonDecode(historyJson);
      final chats =
          historyList
              .map((chatJson) => ChatHistoryEntity.fromJson(chatJson))
              .toList();

      // Сортируем по дате создания (новые первые)
      chats.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      debugPrint('[ChatHistoryService] Загружено ${chats.length} чатов');
      return chats;
    } catch (e) {
      debugPrint('[ChatHistoryService] Ошибка загрузки истории: $e');
      return [];
    }
  }

  /// Сохранение нового чата
  Future<void> saveNewChat(ChatHistoryEntity chat) async {
    try {
      debugPrint('[ChatHistoryService] Сохраняем новый чат: ${chat.id}');
      debugPrint('[ChatHistoryService] Главный вопрос: "${chat.mainQuestion}"');
      debugPrint(
        '[ChatHistoryService] Количество сообщений в чате: ${chat.messages.length}',
      );

      final allChats = await getAllChats();
      debugPrint(
        '[ChatHistoryService] Загружено существующих чатов: ${allChats.length}',
      );

      allChats.insert(0, chat); // Добавляем в начало списка
      debugPrint(
        '[ChatHistoryService] Добавлен новый чат, всего чатов: ${allChats.length}',
      );

      await _saveAllChats(allChats);
      debugPrint('[ChatHistoryService] Все чаты сохранены в SharedPreferences');

      // Устанавливаем как текущий чат
      await _setCurrentChatId(chat.id);
      debugPrint(
        '[ChatHistoryService] ✅ Новый чат сохранен и установлен как текущий',
      );
    } catch (e, stackTrace) {
      debugPrint('[ChatHistoryService] ❌ Ошибка сохранения нового чата: $e');
      debugPrint('[ChatHistoryService] StackTrace: $stackTrace');
    }
  }

  /// Обновление существующего чата
  Future<void> updateChat(ChatHistoryEntity updatedChat) async {
    try {
      debugPrint('[ChatHistoryService] Обновляем чат: ${updatedChat.id}');
      final allChats = await getAllChats();
      final index = allChats.indexWhere((chat) => chat.id == updatedChat.id);

      if (index != -1) {
        allChats[index] = updatedChat.copyWith(updatedAt: DateTime.now());
        await _saveAllChats(allChats);
        debugPrint('[ChatHistoryService] Чат обновлен');
      } else {
        debugPrint('[ChatHistoryService] Чат не найден для обновления');
      }
    } catch (e) {
      debugPrint('[ChatHistoryService] Ошибка обновления чата: $e');
    }
  }

  /// Создание нового чата на основе первого вопроса пользователя
  Future<ChatHistoryEntity?> createChatFromUserMessage(
    String userQuestion,
    List<MessageEntity> currentMessages,
  ) async {
    try {
      debugPrint('[ChatHistoryService] Создаем чат из вопроса: $userQuestion');
      debugPrint(
        '[ChatHistoryService] Количество сообщений: ${currentMessages.length}',
      );

      // Фильтруем сообщения (исключаем streaming)
      final filteredMessages =
          currentMessages.where((message) => !message.isStreaming).toList();

      debugPrint(
        '[ChatHistoryService] После фильтрации сообщений: ${filteredMessages.length}',
      );

      if (filteredMessages.isEmpty) {
        debugPrint('[ChatHistoryService] Нет сообщений для сохранения');
        return null;
      }

      final chatId = _generateChatId();
      debugPrint('[ChatHistoryService] Сгенерирован ID чата: $chatId');

      final chat = ChatHistoryEntity(
        id: chatId,
        mainQuestion: userQuestion,
        createdAt: DateTime.now(),
        messages: filteredMessages,
      );

      debugPrint(
        '[ChatHistoryService] Создан объект чата, вызываем saveNewChat',
      );
      await saveNewChat(chat);
      debugPrint('[ChatHistoryService] ✅ Чат успешно создан и сохранен');
      return chat;
    } catch (e, stackTrace) {
      debugPrint('[ChatHistoryService] ❌ Ошибка создания чата: $e');
      debugPrint('[ChatHistoryService] StackTrace: $stackTrace');
      return null;
    }
  }

  /// Обновление чата с новыми сообщениями
  Future<void> updateChatMessages(
    String chatId,
    List<MessageEntity> newMessages,
  ) async {
    try {
      debugPrint('[ChatHistoryService] Обновляем сообщения в чате: $chatId');
      final allChats = await getAllChats();
      final chatIndex = allChats.indexWhere((chat) => chat.id == chatId);

      if (chatIndex == -1) {
        debugPrint('[ChatHistoryService] Чат не найден: $chatId');
        return;
      }

      // Фильтруем сообщения (исключаем streaming)
      final filteredMessages =
          newMessages.where((message) => !message.isStreaming).toList();

      final updatedChat = allChats[chatIndex].copyWith(
        messages: filteredMessages,
        updatedAt: DateTime.now(),
      );

      allChats[chatIndex] = updatedChat;
      await _saveAllChats(allChats);
      debugPrint('[ChatHistoryService] Сообщения чата обновлены');
    } catch (e) {
      debugPrint('[ChatHistoryService] Ошибка обновления сообщений: $e');
    }
  }

  /// Получение текущего активного чата
  Future<String?> getCurrentChatId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_currentChatIdKey);
    } catch (e) {
      debugPrint('[ChatHistoryService] Ошибка получения текущего чата: $e');
      return null;
    }
  }

  /// Очистка текущего чата (при начале нового)
  Future<void> clearCurrentChat() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentChatIdKey);
      debugPrint('[ChatHistoryService] Текущий чат очищен');
    } catch (e) {
      debugPrint('[ChatHistoryService] Ошибка очистки текущего чата: $e');
    }
  }

  /// Удаление чата
  Future<void> deleteChat(String chatId) async {
    try {
      debugPrint('[ChatHistoryService] Удаляем чат: $chatId');
      final allChats = await getAllChats();
      allChats.removeWhere((chat) => chat.id == chatId);
      await _saveAllChats(allChats);

      // Если удаляем текущий чат, очищаем его
      final currentChatId = await getCurrentChatId();
      if (currentChatId == chatId) {
        await clearCurrentChat();
      }

      debugPrint('[ChatHistoryService] Чат удален');
    } catch (e) {
      debugPrint('[ChatHistoryService] Ошибка удаления чата: $e');
    }
  }

  /// Приватные методы

  Future<void> _saveAllChats(List<ChatHistoryEntity> chats) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = jsonEncode(chats.map((chat) => chat.toJson()).toList());
    await prefs.setString(_historyKey, historyJson);
  }

  Future<void> _setCurrentChatId(String chatId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentChatIdKey, chatId);
  }

  String _generateChatId() {
    return 'chat_${DateTime.now().millisecondsSinceEpoch}';
  }
}
