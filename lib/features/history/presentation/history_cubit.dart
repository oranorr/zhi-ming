import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zhi_ming/features/history/data/chat_history_service.dart';
import 'package:zhi_ming/features/history/domain/chat_history_entity.dart';
import 'package:zhi_ming/features/chat/domain/message_entity.dart';

/// Состояние истории чатов
class HistoryState extends Equatable {
  const HistoryState({
    this.chats = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  /// Список всех чатов
  final List<ChatHistoryEntity> chats;

  /// Флаг загрузки
  final bool isLoading;

  /// Сообщение об ошибке
  final String? errorMessage;

  /// Проверяем, пуста ли история
  bool get isEmpty => chats.isEmpty && !isLoading;

  HistoryState copyWith({
    List<ChatHistoryEntity>? chats,
    bool? isLoading,
    String? errorMessage,
  }) {
    return HistoryState(
      chats: chats ?? this.chats,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [chats, isLoading, errorMessage];
}

/// Cubit для управления историей чатов
class HistoryCubit extends Cubit<HistoryState> {
  HistoryCubit() : super(const HistoryState()) {
    _historyService = ChatHistoryService();
  }

  late final ChatHistoryService _historyService;

  /// Загрузка истории чатов с мок-данными для тестирования
  Future<void> loadHistory() async {
    try {
      debugPrint('[HistoryCubit] Загружаем историю чатов');
      emit(state.copyWith(isLoading: true));

      // Закомментированные реальные данные для тестирования
      final chats = await _historyService.getAllChats();

      // ВРЕМЕННЫЕ МОК-ДАННЫЕ для разработки и тестирования
      // final chats = _generateMockChatHistory();

      emit(state.copyWith(chats: chats, isLoading: false));

      debugPrint('[HistoryCubit] История загружена: ${chats.length} чатов');
    } catch (e) {
      debugPrint('[HistoryCubit] Ошибка загрузки истории: $e');
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Ошибка загрузки истории чатов',
        ),
      );
    }
  }

  /// Генерация мок-данных для тестирования UI
  /// Создает 20 записей чатов с разными временными рамками и типичными вопросами для И Цзин
  List<ChatHistoryEntity> _generateMockChatHistory() {
    final now = DateTime.now();

    // Типичные вопросы для И Цзин гадания
    final questions = [
      '我应该换工作吗？',
      '我的爱情何时到来？',
      '投资这个项目是否明智？',
      '我的健康状况如何？',
      '家庭关系能否改善？',
      '我应该搬到新城市吗？',
      '这次合作会成功吗？',
      '我的事业前景如何？',
      '是否应该结束这段关系？',
      '学习新技能的时机对吗？',
      '买房是否是正确的决定？',
      '与朋友的误会如何解决？',
      '我的创业想法可行吗？',
      '孩子的教育方向对吗？',
      '是否应该原谅他人？',
      '我的内心为何如此不安？',
      '财务困难如何解决？',
      '这次考试能否通过？',
      '与父母的关系如何修复？',
      '我的人生方向是否正确？',
    ];

    // AI回复模板
    final responses = [
      '根据卦象显示，当前正处于变化的关键时期，需要谨慎考虑...',
      '易经指示现在不是行动的最佳时机，需要等待更好的机会...',
      '卦象表明你内心已有答案，要相信自己的直觉...',
      '当前形势复杂，建议先观察再做决定...',
      '易经显示吉利的征象，但需要付出更多努力...',
      '卦象提醒要平衡各方面的关系，不可偏激...',
      '现在是积累实力的时期，暂时的困难会过去...',
      '易经建议保持谦逊的态度，避免过于急躁...',
    ];

    final List<ChatHistoryEntity> mockChats = [];

    for (int i = 0; i < 20; i++) {
      // 生成不同的时间范围
      late DateTime chatTime;

      if (i < 3) {
        // 今天的聊天 (0-2)
        chatTime = now.subtract(Duration(hours: i * 2 + 1));
      } else if (i < 6) {
        // 昨天的聊天 (3-5)
        chatTime = now.subtract(Duration(days: 1, hours: (i - 3) * 4 + 2));
      } else if (i < 10) {
        // 本周的聊天 (6-9)
        chatTime = now.subtract(Duration(days: i - 4, hours: 10));
      } else if (i < 15) {
        // 本月的聊天 (10-14)
        chatTime = now.subtract(Duration(days: (i - 10) * 3 + 8, hours: 14));
      } else {
        // 更早的聊天 (15-19)
        chatTime = now.subtract(Duration(days: (i - 15) * 7 + 30, hours: 9));
      }

      // 创建1-2个消息
      final messageCount = (i % 3) + 1; // 1, 2, или 3 сообщения
      final List<MessageEntity> messages = [];

      // Пользователь всегда первый
      messages.add(
        MessageEntity(text: questions[i], isMe: true, timestamp: chatTime),
      );

      // Иногда добавляем ответ бота
      if (messageCount > 1) {
        messages.add(
          MessageEntity(
            text: responses[i % responses.length],
            isMe: false,
            timestamp: chatTime.add(const Duration(minutes: 2)),
          ),
        );
      }

      // Редко добавляем еще одно сообщение пользователя
      if (messageCount > 2) {
        messages.add(
          MessageEntity(
            text: '感谢指导，我明白了',
            isMe: true,
            timestamp: chatTime.add(const Duration(minutes: 5)),
          ),
        );
      }

      final chat = ChatHistoryEntity(
        id: 'mock_chat_${i + 1}',
        mainQuestion: questions[i],
        createdAt: chatTime,
        messages: messages,
        updatedAt:
            messageCount > 1 ? chatTime.add(const Duration(minutes: 5)) : null,
      );

      mockChats.add(chat);
    }

    // Сортируем по времени создания (новые первые)
    mockChats.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    debugPrint('[HistoryCubit] Сгенерировано ${mockChats.length} мок-чатов');
    return mockChats;
  }

  /// Обновление истории (перезагрузка)
  Future<void> refreshHistory() async {
    await loadHistory();
  }

  /// Удаление чата
  Future<void> deleteChat(String chatId) async {
    try {
      debugPrint('[HistoryCubit] Удаляем чат: $chatId');

      await _historyService.deleteChat(chatId);

      // Обновляем состояние, удаляя чат из списка
      final updatedChats =
          state.chats.where((chat) => chat.id != chatId).toList();

      emit(state.copyWith(chats: updatedChats));

      debugPrint('[HistoryCubit] Чат удален из состояния');
    } catch (e) {
      debugPrint('[HistoryCubit] Ошибка удаления чата: $e');
      emit(state.copyWith(errorMessage: 'Ошибка удаления чата'));
    }
  }

  /// Очистка ошибки
  void clearError() {
    emit(state.copyWith());
  }
}
