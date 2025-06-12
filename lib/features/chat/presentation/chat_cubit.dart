import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:zhi_ming/core/services/deepseek/deepseek_service.dart';
import 'package:zhi_ming/core/services/deepseek/models/message.dart';
import 'package:zhi_ming/core/services/shake_service/shaker_service_repo.dart';
import 'package:zhi_ming/core/services/user_service.dart';
import 'package:zhi_ming/features/chat/data/badzy_chat_service.dart';
import 'package:zhi_ming/features/chat/domain/chat_entrypoint_entity.dart';
import 'package:zhi_ming/features/chat/domain/message_entity.dart';
import 'package:zhi_ming/features/chat/presentation/models/chat_state.dart';
import 'package:zhi_ming/features/chat/presentation/services/chat_orchestrator_service.dart';
import 'package:zhi_ming/features/chat/presentation/services/chat_validation_service.dart';
import 'package:zhi_ming/features/chat/presentation/services/hexagram_generation_service.dart';
import 'package:zhi_ming/features/history/data/chat_history_service.dart';
import 'package:zhi_ming/features/home/data/recommendations_service.dart';

/// Оптимизированный ChatCubit с делегированием бизнес-логики в сервисы
/// Фокусируется только на управлении состоянием и координации операций
class ChatCubit extends HydratedCubit<ChatState> {
  ChatCubit() : super(const ChatState()) {
    _orchestratorService = ChatOrchestratorService();
    _historyService = ChatHistoryService();
    _userService = UserService();
    _deepSeekService = DeepSeekService();
    _baDzyChatService = BaDzyChatService();
    _recommendationsService = RecommendationsService();
    _initializeServices();
  }

  late final ChatOrchestratorService _orchestratorService;
  late final ChatHistoryService _historyService;
  late final UserService _userService;
  late final DeepSeekService _deepSeekService;
  late final BaDzyChatService _baDzyChatService;
  late final RecommendationsService _recommendationsService;

  /// Текущий entrypoint для чата (сохраняется после инициализации)
  ChatEntrypointEntity? _currentEntrypoint;

  // Поля для новой логики paywall после встряхивания
  HexagramPair? _pendingHexagramPair;
  String? _pendingUserQuestion;
  bool _isFirstReading = false;
  dynamic _backgroundInterpretationResult;

  /// Геттеры для проверки состояния paywall контекста
  bool get hasPendingPaywallContext =>
      _pendingHexagramPair != null && _pendingUserQuestion != null;
  bool get isFirstReadingPending => _isFirstReading;

  /// Инициализация всех сервисов
  Future<void> _initializeServices() async {
    debugPrint('[ChatCubit] Инициализация сервисов');
    await _orchestratorService.initialize();
    await _updateSubscriptionStatus();
    debugPrint('[ChatCubit] Сервисы инициализированы');
  }

  /// Обновление статуса подписки
  Future<void> _updateSubscriptionStatus() async {
    final subscriptionStatus =
        await _orchestratorService.getSubscriptionStatus();
    emit(
      state.copyWith(
        hasActiveSubscription: subscriptionStatus.hasPremiumAccess,
        remainingFreeRequests: subscriptionStatus.remainingFreeRequests,
        hasUsedFreeReading: subscriptionStatus.hasUsedFreeReading,
        remainingFollowUpQuestions:
            subscriptionStatus.remainingFollowUpQuestions,
      ),
    );
  }

  // ===============================================
  // МЕТОДЫ УПРАВЛЕНИЯ ИНТЕРФЕЙСОМ
  // ===============================================

  /// Показ начального сообщения от бота в зависимости от типа entrypoint
  void showInitialMessage(ChatEntrypointEntity entrypoint) {
    debugPrint(
      '[ChatCubit] Показываем начальное сообщение для ${entrypoint.runtimeType}',
    );

    // [ChatCubit] Сохраняем entrypoint для дальнейшего использования
    _currentEntrypoint = entrypoint;

    // [ChatCubit] Если это Ба-Дзы, загружаем существующий чат
    if (entrypoint is BaDzyEntrypointEntity) {
      _loadBaDzyChat();
      return;
    }

    // Обычная логика для других типов entrypoint
    String messageText = '请描述你的问题或你想关注的具体情况。';

    final initialBotMessage = MessageEntity(
      text: messageText,
      isMe: false,
      timestamp: DateTime.now(),
    );

    final updatedMessages = List<MessageEntity>.from(state.messages)
      ..insert(0, initialBotMessage);

    emit(state.copyWith(messages: updatedMessages));
  }

  /// Обновление текущего ввода пользователя
  void updateInput(String text) {
    emit(
      state.copyWith(
        currentInput: text,
        isSendAvailable: text.trim().isNotEmpty,
      ),
    );
  }

  /// Переключение доступности кнопки встряхивания
  void toggleButton(bool available) {
    emit(state.copyWith(isButtonAvailable: available));
  }

  /// Установка состояния загрузки
  void setLoading(bool loading) {
    emit(state.copyWith(isLoading: loading));
  }

  // ===============================================
  // ОСНОВНАЯ БИЗНЕС-ЛОГИКА
  // ===============================================

  /// Отправка сообщения пользователем
  void sendMessage() {
    if (state.currentInput.trim().isEmpty) {
      debugPrint('[ChatCubit] Пустое сообщение, игнорируем');
      return;
    }

    debugPrint('[ChatCubit] Отправка сообщения: ${state.currentInput}');

    // Создаем сообщение пользователя
    final newMessage = MessageEntity(
      text: state.currentInput.trim(),
      isMe: true,
      timestamp: DateTime.now(),
    );

    // Добавляем сообщение в список
    final updatedMessages = List<MessageEntity>.from(state.messages)
      ..insert(0, newMessage);

    // Очищаем ввод
    emit(
      state.copyWith(
        messages: updatedMessages,
        currentInput: '',
        isSendAvailable: false,
      ),
    );

    // [ChatCubit] Сохраняем сообщение в чат Ба-Дзы, если это BaDzy entrypoint
    if (_currentEntrypoint is BaDzyEntrypointEntity) {
      _saveBaDzyMessage(newMessage);
    }

    // Определяем тип обработки сообщения
    if (_currentEntrypoint is BaDzyEntrypointEntity) {
      // [ChatCubit] Специальная обработка для Ба-Дзы
      _handleBaDzyMessage(state.messages[0].text, state.messages);
    } else if (state.hasHexagramContext) {
      // Есть контекст последнего гадания - обрабатываем как последующий вопрос
      debugPrint(
        '[ChatCubit] Обрабатываем как последующий вопрос (есть контекст гадания)',
      );
      _handleFollowUpQuestion(state.messages[0].text);
    } else {
      // Нет контекста - добавляем к текущему контексту вопроса и валидируем
      debugPrint(
        '[ChatCubit] Обрабатываем как новый вопрос (нет контекста гадания)',
      );
      _handleNewQuestion(state.messages[0].text);
    }
  }

  /// Обработка нового вопроса (валидация)
  Future<void> _handleNewQuestion(String question) async {
    debugPrint('[ChatCubit] Обработка нового вопроса');

    // [ChatCubit] Проверяем, если это BaDzy entrypoint - обрабатываем по-особому
    if (_currentEntrypoint is BaDzyEntrypointEntity) {
      await _handleBaDzyBirthPlace(question);
      return;
    }

    // Обычная обработка для других entrypoint'ов
    // Добавляем вопрос к контексту
    final updatedQuestionContext = List<String>.from(
      state.currentQuestionContext,
    )..add(question);

    // Обновляем состояние с новым контекстом
    emit(state.copyWith(currentQuestionContext: updatedQuestionContext));

    // Создаем индикатор загрузки
    _showLoadingMessage();

    // Валидируем запрос через оркестратор
    final validationResult = await _orchestratorService.validateUserRequest(
      updatedQuestionContext,
    );

    // Обрабатываем результат валидации
    _handleValidationResult(validationResult);
  }

  /// Обработка последующего вопроса
  Future<void> _handleFollowUpQuestion(String question) async {
    debugPrint('[ChatCubit] Обработка последующего вопроса');

    if (state.lastHexagramContext == null) {
      debugPrint('[ChatCubit] ОШИБКА: Нет контекста последнего гадания');
      addBotMessage(
        'Для задания дополнительных вопросов необходимо сначала провести гадание.',
      );
      return;
    }

    // Создаем индикатор загрузки
    _showLoadingMessage();

    // Обрабатываем через оркестратор
    final result = await _orchestratorService.handleFollowUpQuestion(
      question: question,
      context: state.lastHexagramContext!,
      conversationHistory: state.messages,
    );

    // Обрабатываем результат
    if (result.isSuccess) {
      _showResponseMessage(result.response, enableStreaming: true);

      // Обновляем статус подписки
      if (result.updatedSubscriptionStatus != null) {
        emit(
          state.copyWith(
            hasActiveSubscription:
                result.updatedSubscriptionStatus!.hasPremiumAccess,
            remainingFreeRequests:
                result.updatedSubscriptionStatus!.remainingFreeRequests,
            hasUsedFreeReading:
                result.updatedSubscriptionStatus!.hasUsedFreeReading,
            remainingFollowUpQuestions:
                result.updatedSubscriptionStatus!.remainingFollowUpQuestions,
          ),
        );
      }

      // Сохраняем обновленный чат в историю
      await _saveOrUpdateChatHistory();
    } else if (result.requiresPaywall) {
      _showErrorMessage(result.message);
      _navigateToPaywall();
    } else {
      _showErrorMessage(result.message);
    }
  }

  /// Обработка встряхивания
  Future<void> processAfterShaking(ShakerServiceRepo shakerService) async {
    debugPrint('[ChatCubit] Обработка встряхивания - НОВАЯ ЛОГИКА');
    debugPrint(
      '[ChatCubit] Состояние кнопки ДО обработки: isButtonAvailable = ${state.isButtonAvailable}',
    );

    // [ChatCubit] Немедленно скрываем кнопку встряхивания для предотвращения повторных нажатий
    if (state.isButtonAvailable) {
      emit(state.copyWith(isButtonAvailable: false));
      debugPrint('[ChatCubit] Кнопка встряхивания скрыта в начале обработки');
    }

    // Получаем вопрос пользователя
    final userQuestion = _getUserQuestion();
    if (userQuestion.isEmpty) {
      debugPrint('[ChatCubit] ОШИБКА: Нет вопроса пользователя');
      addBotMessage(
        'Не найден вопрос пользователя. Пожалуйста, задайте вопрос заново.',
      );
      return;
    }

    // НОВАЯ ЛОГИКА: Генерируем гексаграммы БЕЗ проверки подписки
    try {
      // Получаем значения линий из сервиса встряхивания
      final List<int> lineValues = shakerService.getLineValues();
      debugPrint('[ChatCubit] Получены значения линий: $lineValues');

      // Если не получены все 6 линий, дополняем до полной гексаграммы
      final List<int> completeLineValues = List<int>.from(lineValues);
      while (completeLineValues.length < 6) {
        completeLineValues.add(8); // молодой инь по умолчанию
      }

      // Генерируем гексаграммы через оркестратор
      final hexagramPair = await _orchestratorService.generateHexagramFromLines(
        completeLineValues,
      );

      debugPrint('[ChatCubit] Сгенерированы гексаграммы:');
      debugPrint(
        '  Основная: ${hexagramPair.primary.number} (${hexagramPair.primary.name})',
      );
      if (hexagramPair.hasChangingLines) {
        debugPrint(
          '  Изменяющаяся: ${hexagramPair.secondary!.number} (${hexagramPair.secondary!.name})',
        );
      }

      // Сбрасываем результаты встряхиваний
      shakerService.resetCoinThrows();

      // Проверяем - первое ли это гадание пользователя
      final subscriptionStatus =
          await _orchestratorService.getSubscriptionStatus();
      final isFirstReading = !subscriptionStatus.hasUsedFreeReading;
      final hasActiveSubscription = subscriptionStatus.hasPremiumAccess;

      debugPrint('[ChatCubit] Первое гадание: $isFirstReading');
      debugPrint('[ChatCubit] Есть подписка: $hasActiveSubscription');

      // НОВАЯ ЛОГИКА: Если есть подписка - показываем результат сразу
      if (hasActiveSubscription) {
        debugPrint('[ChatCubit] Есть подписка - показываем результат сразу');

        // Показываем индикатор загрузки
        _showLoadingMessage();

        try {
          // Получаем интерпретацию от DeepSeek
          final interpretationResult = await _deepSeekService
              .interpretHexagramsStructured(
                question: userQuestion,
                primaryHexagram: hexagramPair.primary,
                secondaryHexagram: hexagramPair.secondary,
              );

          // Создаем результат для показа
          final result = ShakeProcessingResult.success(
            hexagramPair: hexagramPair,
            interpretationResult: interpretationResult,
            userQuestion: userQuestion,
            updatedSubscriptionStatus: subscriptionStatus,
          );

          // Показываем результат
          await _showHexagramResult(result);
        } catch (e) {
          debugPrint('[ChatCubit] Ошибка при получении интерпретации: $e');
          _showErrorMessage(
            'Произошла ошибка при получении интерпретации. Пожалуйста, попробуйте еще раз.',
          );
        }

        return;
      }

      // Если нет подписки - сохраняем контекст для возврата из paywall
      _pendingHexagramPair = hexagramPair;
      _pendingUserQuestion = userQuestion;
      _isFirstReading = isFirstReading;

      // Начинаем фоновую генерацию интерпретации
      _startBackgroundInterpretation(userQuestion, hexagramPair);

      // Показываем paywall
      _navigateToPaywallAfterShaking(isFirstReading: isFirstReading);
    } catch (e) {
      debugPrint('[ChatCubit] Ошибка при генерации гексаграмм: $e');
      addBotMessage(
        'Произошла ошибка при обработке гадания. Пожалуйста, попробуйте еще раз.',
      );
    }
  }

  // ===============================================
  // МЕТОДЫ РАБОТЫ С ИСТОРИЕЙ ЧАТОВ
  // ===============================================

  /// Создание или обновление чата в истории
  Future<void> _saveOrUpdateChatHistory() async {
    try {
      debugPrint('[ChatCubit] Начинаем сохранение истории чата');

      // [ChatCubit] НЕ сохраняем чаты Ба-Дзы в обычной истории
      if (_currentEntrypoint is BaDzyEntrypointEntity) {
        debugPrint('[ChatCubit] Чат Ба-Дзы не сохраняется в обычной истории');
        return;
      }

      // Исключаем streaming сообщения
      final filteredMessages =
          state.messages.where((message) => !message.isStreaming).toList();

      debugPrint('[ChatCubit] Всего сообщений: ${state.messages.length}');
      debugPrint(
        '[ChatCubit] Отфильтрованных сообщений: ${filteredMessages.length}',
      );

      if (filteredMessages.isEmpty) {
        debugPrint('[ChatCubit] Нет сообщений для сохранения в истории');
        return;
      }

      // НОВАЯ ПРОВЕРКА: Сохраняем только если есть успешная интерпретация
      // Проверяем есть ли сообщения от бота (не пользователя)
      final hasBotMessages = filteredMessages.any((message) => !message.isMe);

      // Проверяем есть ли контекст гексаграммы (значит была успешная интерпретация)
      // или есть ли сообщения с гексаграммами
      final hasSuccessfulInterpretation =
          state.hasHexagramContext ||
          filteredMessages.any(
            (message) =>
                !message.isMe &&
                (message.hexagrams?.isNotEmpty == true ||
                    message.simpleInterpretation != null ||
                    message.complexInterpretation != null),
          );

      if (!hasBotMessages || !hasSuccessfulInterpretation) {
        debugPrint(
          '[ChatCubit] Чат не содержит успешной интерпретации, пропускаем сохранение',
        );
        debugPrint(
          '[ChatCubit] hasBotMessages: $hasBotMessages, hasSuccessfulInterpretation: $hasSuccessfulInterpretation',
        );
        return;
      }

      // Находим первое сообщение пользователя для заголовка
      final userMessage = filteredMessages.firstWhere(
        (message) => message.isMe,
        orElse:
            () => MessageEntity(
              text: 'Вопрос пользователя',
              isMe: true,
              timestamp: DateTime.now(),
            ),
      );

      debugPrint(
        '[ChatCubit] Главный вопрос для заголовка: "${userMessage.text}"',
      );
      debugPrint('[ChatCubit] Текущий chatId: ${state.currentChatId}');

      if (state.currentChatId == null) {
        // Создаем новый чат
        debugPrint('[ChatCubit] Создаем новый чат в истории');
        final newChat = await _historyService.createChatFromUserMessage(
          userMessage.text,
          filteredMessages.reversed
              .toList(), // Разворачиваем для правильного порядка
        );

        if (newChat != null) {
          emit(state.copyWith(currentChatId: newChat.id));
          debugPrint('[ChatCubit] ✅ Новый чат создан с ID: ${newChat.id}');
        } else {
          debugPrint('[ChatCubit] ❌ Не удалось создать новый чат');
        }
      } else {
        // Обновляем существующий чат
        debugPrint(
          '[ChatCubit] Обновляем существующий чат: ${state.currentChatId}',
        );
        await _historyService.updateChatMessages(
          state.currentChatId!,
          filteredMessages.reversed
              .toList(), // Разворачиваем для правильного порядка
        );
        debugPrint('[ChatCubit] ✅ Чат обновлен в истории');
      }
    } catch (e, stackTrace) {
      debugPrint('[ChatCubit] ❌ Ошибка сохранения истории чата: $e');
      debugPrint('[ChatCubit] StackTrace: $stackTrace');
    }
  }

  // ===============================================
  // ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ
  // ===============================================

  /// Создание сообщения с индикатором загрузки
  void _showLoadingMessage() {
    final loadingMessage = MessageEntity(
      text: '',
      isMe: false,
      timestamp: DateTime.now(),
    );

    final updatedMessages = List<MessageEntity>.from(state.messages)
      ..insert(0, loadingMessage);

    emit(
      state.copyWith(
        messages: updatedMessages,
        isLoading: true,
        loadingMessageIndex: 0,
      ),
    );
  }

  /// Показ ответного сообщения
  void _showResponseMessage(String text, {bool enableStreaming = false}) {
    final responseMessage = MessageEntity(
      text: text,
      isMe: false,
      timestamp: DateTime.now(),
      isStreaming: enableStreaming,
    );

    _replaceLoadingMessage(responseMessage);

    // [ChatCubit] Сохраняем ответ в чат Ба-Дзы, если это BaDzy entrypoint
    // НО ТОЛЬКО если НЕ включен streaming (иначе будет дублирование при завершении)
    if (_currentEntrypoint is BaDzyEntrypointEntity && !enableStreaming) {
      _saveBaDzyMessage(responseMessage);
    }

    // Настраиваем streaming, если нужно
    if (enableStreaming) {
      _orchestratorService.setupMessageStreaming(
        message: responseMessage,
        onStreamingComplete: () => _stopMessageStreaming(responseMessage),
      );
    }
  }

  /// Показ сообщения об ошибке
  void _showErrorMessage(String text) {
    final errorMessage = MessageEntity(
      text: text,
      isMe: false,
      timestamp: DateTime.now(),
    );

    _replaceLoadingMessage(errorMessage);
  }

  /// Показ результата гексаграммы
  Future<void> _showHexagramResult(ShakeProcessingResult result) async {
    debugPrint('[ChatCubit] Начинаем показ результата гексаграммы');
    debugPrint(
      '[ChatCubit] Состояние ДО обновления: isButtonAvailable = ${state.isButtonAvailable}, hasHexagramContext = ${state.hasHexagramContext}',
    );

    // Создаем сообщение с гексаграммами и интерпретацией
    MessageEntity resultMessage;

    if (result.interpretationResult is SimpleInterpretation) {
      resultMessage = MessageEntity(
        text: '',
        isMe: false,
        timestamp: DateTime.now(),
        hexagrams: [result.hexagramPair!.primary],
        simpleInterpretation: result.interpretationResult,
      );
    } else if (result.interpretationResult is ComplexInterpretation) {
      final hexagrams =
          result.hexagramPair!.hasChangingLines
              ? [result.hexagramPair!.primary, result.hexagramPair!.secondary!]
              : [result.hexagramPair!.primary];

      resultMessage = MessageEntity(
        text: '',
        isMe: false,
        timestamp: DateTime.now(),
        hexagrams: hexagrams,
        complexInterpretation: result.interpretationResult,
      );
    } else {
      // Fallback для обратной совместимости
      final interpretation = result.interpretationResult.toString();
      final interpretedPrimary = result.hexagramPair!.primary.copyWith(
        interpretation: interpretation,
      );

      final hexagrams =
          result.hexagramPair!.hasChangingLines
              ? [
                interpretedPrimary,
                result.hexagramPair!.secondary!.copyWith(
                  interpretation: interpretation,
                ),
              ]
              : [interpretedPrimary];

      resultMessage = MessageEntity(
        text: '',
        isMe: false,
        timestamp: DateTime.now(),
        hexagrams: hexagrams,
      );
    }

    // Сохраняем контекст гадания
    final contextInterpretation = _extractInterpretationText(
      result.interpretationResult,
    );

    final hexagramContext = HexagramContext(
      originalQuestion: result.userQuestion,
      primaryHexagram: result.hexagramPair!.primary,
      secondaryHexagram: result.hexagramPair!.secondary,
      interpretation: contextInterpretation,
    );

    // Объединяем обновление сообщений и установку контекста в один emit
    final updatedMessages = List<MessageEntity>.from(state.messages);
    if (state.loadingMessageIndex >= 0 &&
        state.loadingMessageIndex < updatedMessages.length) {
      updatedMessages[state.loadingMessageIndex] = resultMessage;
    }

    // Обновляем состояние одним emit()
    emit(
      state.copyWith(
        messages: updatedMessages,
        isLoading: false,
        loadingMessageIndex: -1,
        lastHexagramContext: hexagramContext,
        currentQuestionContext: const [], // Очищаем контекст вопроса
        isButtonAvailable:
            false, // ВАЖНО: скрываем кнопку встряхивания после получения результата
        hasActiveSubscription:
            result.updatedSubscriptionStatus!.hasPremiumAccess,
        remainingFreeRequests:
            result.updatedSubscriptionStatus!.remainingFreeRequests,
        hasUsedFreeReading:
            result.updatedSubscriptionStatus!.hasUsedFreeReading,
        remainingFollowUpQuestions:
            result.updatedSubscriptionStatus!.remainingFollowUpQuestions,
      ),
    );

    debugPrint(
      '[ChatCubit] Кнопка встряхивания скрыта после гадания: isButtonAvailable = false',
    );
    debugPrint(
      '[ChatCubit] Установлен контекст гадания: ${hexagramContext.debugDescription}',
    );
    debugPrint(
      '[ChatCubit] Текущее состояние: hasHexagramContext = ${state.hasHexagramContext}',
    );

    // Сохраняем чат в историю после получения результата гексаграммы
    await _saveOrUpdateChatHistory();

    // ГЕНЕРИРУЕМ НОВЫЕ РЕКОМЕНДАЦИИ ПОСЛЕ УСПЕШНОГО ГАДАНИЯ
    _generateNewRecommendationsAfterDivination();

    // Добавляем пояснительное сообщение
    Future.delayed(const Duration(seconds: 1), () {
      addBotMessage('您可以提出另一个问题或继续对话。', enableStreaming: true);
    });
  }

  /// Замена сообщения с загрузкой на результат
  void _replaceLoadingMessage(MessageEntity newMessage) {
    final updatedMessages = List<MessageEntity>.from(state.messages);

    if (state.loadingMessageIndex >= 0 &&
        state.loadingMessageIndex < updatedMessages.length) {
      updatedMessages[state.loadingMessageIndex] = newMessage;
    }

    emit(
      state.copyWith(
        messages: updatedMessages,
        isLoading: false,
        loadingMessageIndex: -1,
      ),
    );
  }

  /// Обработка результата валидации
  void _handleValidationResult(ValidationResult result) {
    if (result.isValid) {
      // Валидация успешна - показываем приглашение к встряхиванию
      _showResponseMessage(result.message);

      // ИСПРАВЛЕНИЕ: Кнопка должна включаться только если нет контекста последнего гадания
      // Если есть контекст гадания, значит это новый вопрос после получения результата
      final shouldShowButton =
          result.shouldEnableShaking && state.lastHexagramContext == null;

      debugPrint(
        '[ChatCubit] Обработка валидации: shouldEnableShaking=${result.shouldEnableShaking}, '
        'hasHexagramContext=${state.lastHexagramContext != null}, '
        'finalButtonState=$shouldShowButton',
      );

      emit(
        state.copyWith(
          isButtonAvailable: shouldShowButton,
          currentQuestionContext:
              result.shouldClearContext
                  ? const []
                  : state.currentQuestionContext,
        ),
      );
    } else if (result.isError) {
      // Обычная ошибка валидации (больше НЕ проверяем paywall - он показывается только после встряхивания)
      _showErrorMessage(result.message);
      emit(
        state.copyWith(
          isButtonAvailable: result.shouldEnableShaking,
          currentQuestionContext:
              result.shouldClearContext
                  ? const []
                  : state.currentQuestionContext,
        ),
      );
    } else {
      // Обычная ошибка валидации
      _showErrorMessage(result.message);
      emit(
        state.copyWith(
          isButtonAvailable: result.shouldEnableShaking,
          currentQuestionContext:
              result.shouldClearContext
                  ? const []
                  : state.currentQuestionContext,
        ),
      );
    }
  }

  /// Остановка streaming для сообщения
  void _stopMessageStreaming(MessageEntity message) {
    final updatedMessages = List<MessageEntity>.from(state.messages);
    final messageIndex = updatedMessages.indexWhere(
      (m) =>
          m.text == message.text &&
          m.timestamp == message.timestamp &&
          m.isStreaming,
    );

    if (messageIndex != -1) {
      final updatedMessage = updatedMessages[messageIndex].copyWith(
        isStreaming: false,
      );
      updatedMessages[messageIndex] = updatedMessage;

      emit(state.copyWith(messages: updatedMessages));

      // [ChatCubit] Обновляем сообщение в чате Ба-Дзы после завершения streaming
      if (_currentEntrypoint is BaDzyEntrypointEntity) {
        _saveBaDzyMessage(updatedMessage);

        // [ChatCubit] Дополнительно сохраняем как гороскоп, если это первый ответ от агента
        _saveBaDzyHoroscopeIfNeeded(updatedMessage);
      }

      // Сохраняем чат в историю после завершения streaming
      _saveOrUpdateChatHistory();
    }
  }

  /// Получение вопроса пользователя из истории сообщений
  String _getUserQuestion() {
    final userMessage = state.messages.firstWhere(
      (m) => m.isMe,
      orElse:
          () => MessageEntity(text: '', isMe: true, timestamp: DateTime.now()),
    );
    return userMessage.text;
  }

  /// Извлечение текста интерпретации из результата
  String _extractInterpretationText(interpretationResult) {
    if (interpretationResult is SimpleInterpretation) {
      return interpretationResult.answer;
    } else if (interpretationResult is ComplexInterpretation) {
      return interpretationResult.answer;
    } else {
      return interpretationResult.toString();
    }
  }

  // ===============================================
  // СПЕЦИАЛЬНАЯ ОБРАБОТКА ДЛЯ БА-ДЗЫ
  // ===============================================

  /// Обработка сообщения для Ба-Дзы (может быть первое место рождения или последующий вопрос)
  Future<void> _handleBaDzyMessage(
    String message,
    List<MessageEntity> currentMessages,
  ) async {
    debugPrint('[ChatCubit] Обработка сообщения Ба-Дзы: $message');

    try {
      // [ChatCubit] Проверяем, есть ли уже гороскоп (значит это последующий вопрос)
      final hasHoroscope = await _baDzyChatService.hasBaDzyHoroscope();

      if (hasHoroscope) {
        // [ChatCubit] Есть гороскоп - обрабатываем как последующий вопрос с историей
        await _handleBaDzyFollowUpQuestion(message, currentMessages);
      } else {
        // [ChatCubit] Нет гороскопа - обрабатываем как первое сообщение с местом рождения
        await _handleBaDzyBirthPlace(message);
      }
    } catch (e) {
      debugPrint('[ChatCubit] ОШИБКА при обработке сообщения Ба-Дзы: $e');
      addBotMessage(
        'Произошла ошибка при обработке сообщения. Пожалуйста, попробуйте еще раз.',
      );
    }
  }

  /// Обработка последующего вопроса для Ба-Дзы с использованием истории чата
  Future<void> _handleBaDzyFollowUpQuestion(
    String question,
    List<MessageEntity> currentMessages,
  ) async {
    debugPrint('[ChatCubit] Обработка последующего вопроса Ба-Дзы: $question');

    try {
      // [ChatCubit] Показываем индикатор загрузки
      _showLoadingMessage();

      // [ChatCubit] Преобразуем историю сообщений в формат DeepSeek
      final conversationHistory = _convertMessagesToDeepSeekHistory(
        currentMessages,
      );

      debugPrint(
        '[ChatCubit] История чата Ба-Дзы: ${conversationHistory.length} сообщений',
      );

      // [ChatCubit] Отправляем вопрос агенту с полной историей
      final response = await _deepSeekService.sendMessage(
        agentType: AgentType.bazsu,
        message: question,
        history: conversationHistory,
      );

      debugPrint(
        '[ChatCubit] Получен ответ от агента Ба-Дзы на последующий вопрос',
      );

      // [ChatCubit] Показываем ответ пользователю
      _showResponseMessage(response, enableStreaming: true);
    } catch (e, stackTrace) {
      debugPrint(
        '[ChatCubit] ОШИБКА при обработке последующего вопроса Ба-Дзы: $e',
      );
      debugPrint('[ChatCubit] StackTrace: $stackTrace');

      addBotMessage(
        'Произошла ошибка при обработке вашего вопроса. Пожалуйста, попробуйте еще раз.',
      );
    }
  }

  /// Преобразование MessageEntity в DeepSeekMessage с умным усечением истории
  List<DeepSeekMessage> _convertMessagesToDeepSeekHistory(
    List<MessageEntity> messages,
  ) {
    debugPrint('[ChatCubit] Преобразование истории сообщений для Ба-Дзы');

    // [ChatCubit] Фильтруем только завершенные сообщения (не streaming)
    final filteredMessages =
        messages.where((message) => !message.isStreaming).toList();

    debugPrint(
      '[ChatCubit] Отфильтрованных сообщений: ${filteredMessages.length}',
    );

    // [ChatCubit] Реверсируем для хронологического порядка (oldest to newest)
    final chronologicalMessages = filteredMessages.reversed.toList();

    List<MessageEntity> messagesToConvert;

    // [ChatCubit] Применяем умное усечение если больше 50 сообщений
    if (chronologicalMessages.length > 50) {
      debugPrint(
        '[ChatCubit] Применяем умное усечение истории: ${chronologicalMessages.length} сообщений',
      );

      // [ChatCubit] Берем первые 3 сообщения + последние 50 сообщений
      final firstThree = chronologicalMessages.take(3).toList();
      final lastFifty =
          chronologicalMessages
              .skip(chronologicalMessages.length - 50)
              .toList();

      // [ChatCubit] Объединяем, избегая дублирования
      messagesToConvert = <MessageEntity>[];
      messagesToConvert.addAll(firstThree);

      // [ChatCubit] Добавляем последние 50, только если они не пересекаются с первыми 3
      for (final message in lastFifty) {
        if (!firstThree.contains(message)) {
          messagesToConvert.add(message);
        }
      }

      debugPrint(
        '[ChatCubit] После усечения: ${messagesToConvert.length} сообщений',
      );
      debugPrint(
        '[ChatCubit] Первые 3: ${firstThree.length}, последние уникальные: ${messagesToConvert.length - firstThree.length}',
      );
    } else {
      messagesToConvert = chronologicalMessages;
      debugPrint(
        '[ChatCubit] Усечение не требуется: ${messagesToConvert.length} сообщений',
      );
    }

    // [ChatCubit] Преобразуем в DeepSeekMessage
    final deepSeekMessages =
        messagesToConvert.map((message) {
          return DeepSeekMessage(
            role: message.isMe ? 'user' : 'assistant',
            content: message.text,
          );
        }).toList();

    debugPrint(
      '[ChatCubit] Конвертировано в DeepSeek формат: ${deepSeekMessages.length} сообщений',
    );

    return deepSeekMessages;
  }

  /// Загрузка существующего чата Ба-Дзы или создание нового
  Future<void> _loadBaDzyChat() async {
    try {
      debugPrint('[ChatCubit] Загружаем чат Ба-Дзы');

      // [ChatCubit] Загружаем существующие сообщения Ба-Дзы
      final existingMessages = await _baDzyChatService.loadBaDzyMessages();

      if (existingMessages.isNotEmpty) {
        // Есть существующий чат - загружаем его
        debugPrint(
          '[ChatCubit] Найден существующий чат Ба-Дзы с ${existingMessages.length} сообщениями',
        );

        // [ChatCubit] Убираем флаг streaming у всех загруженных сообщений
        // чтобы избежать повторного запуска стриминга при повторном входе
        final messagesWithoutStreaming =
            existingMessages.map((message) {
              return message.copyWith(isStreaming: false);
            }).toList();

        emit(state.copyWith(messages: messagesWithoutStreaming));
      } else {
        // Нет существующего чата - создаем новый с приветственным сообщением
        debugPrint('[ChatCubit] Создаем новый чат Ба-Дзы');

        final initialBotMessage = MessageEntity(
          text: 'пожалуйста напиши место своего рождения',
          isMe: false,
          timestamp: DateTime.now(),
        );

        final messages = [initialBotMessage];

        // Сохраняем приветственное сообщение в чат Ба-Дзы
        await _baDzyChatService.saveBaDzyMessages(messages);

        emit(state.copyWith(messages: messages));
      }
    } catch (e, stackTrace) {
      debugPrint('[ChatCubit] ОШИБКА при загрузке чата Ба-Дзы: $e');
      debugPrint('[ChatCubit] StackTrace: $stackTrace');

      // В случае ошибки показываем стандартное сообщение
      final initialBotMessage = MessageEntity(
        text: 'пожалуйста напиши место своего рождения',
        isMe: false,
        timestamp: DateTime.now(),
      );

      emit(state.copyWith(messages: [initialBotMessage]));
    }
  }

  /// Сохранение сообщения в чат Ба-Дзы
  Future<void> _saveBaDzyMessage(MessageEntity message) async {
    try {
      debugPrint('[ChatCubit] Сохраняем сообщение в чат Ба-Дзы');
      await _baDzyChatService.addMessageToBaDzyChat(message);
    } catch (e) {
      debugPrint('[ChatCubit] ОШИБКА при сохранении сообщения Ба-Дзы: $e');
    }
  }

  /// Сохранение гороскопа Ба-Дзы, если это первый ответ от агента
  Future<void> _saveBaDzyHoroscopeIfNeeded(MessageEntity message) async {
    try {
      // [ChatCubit] Проверяем, что это сообщение от бота (не от пользователя)
      if (message.isMe) {
        return;
      }

      // [ChatCubit] Проверяем, есть ли уже сохраненный гороскоп
      final hasExistingHoroscope = await _baDzyChatService.hasBaDzyHoroscope();
      if (hasExistingHoroscope) {
        debugPrint(
          '[ChatCubit] Гороскоп уже существует, пропускаем сохранение',
        );
        return;
      }

      // [ChatCubit] Проверяем, что это содержательный ответ (не приветственное сообщение)
      if (message.text.contains('место своего рождения') ||
          message.text.length < 50) {
        debugPrint(
          '[ChatCubit] Сообщение слишком короткое для гороскопа, пропускаем',
        );
        return;
      }

      // [ChatCubit] Проверяем, что в чате есть сообщение пользователя (место рождения)
      final userMessages = state.messages.where((m) => m.isMe).toList();
      if (userMessages.isEmpty) {
        debugPrint(
          '[ChatCubit] Нет сообщений пользователя, пропускаем сохранение гороскопа',
        );
        return;
      }

      debugPrint('[ChatCubit] Сохраняем сообщение как гороскоп Ба-Дзы');
      await _baDzyChatService.saveBaDzyHoroscope(message);
      debugPrint('[ChatCubit] Гороскоп Ба-Дзы успешно сохранен');
    } catch (e) {
      debugPrint('[ChatCubit] ОШИБКА при сохранении гороскопа Ба-Дзы: $e');
    }
  }

  /// Обработка места рождения для Ба-Дзы гадания
  Future<void> _handleBaDzyBirthPlace(String birthPlace) async {
    debugPrint('[ChatCubit] Обработка места рождения для Ба-Дзы: $birthPlace');

    try {
      // [ChatCubit] Показываем индикатор загрузки
      _showLoadingMessage();

      // [ChatCubit] Получаем данные пользователя (дата и время рождения)
      final userProfile = await _userService.getUserProfile();

      if (userProfile == null) {
        debugPrint('[ChatCubit] ОШИБКА: Профиль пользователя не найден');
        addBotMessage(
          'Не удалось получить данные о вашем рождении. Пожалуйста, заполните профиль в настройках.',
        );
        return;
      }

      // [ChatCubit] Формируем данные для отправки агенту
      final baDzyData = {
        'birthDate': userProfile.formattedBirthDate,
        'birthTime': userProfile.formattedBirthTime ?? 'неизвестно',
        'birthPlace': birthPlace.trim(),
      };

      debugPrint('[ChatCubit] Отправляем данные Ба-Дзы агенту: $baDzyData');

      // [ChatCubit] Отправляем данные агенту bazsu
      final response = await _deepSeekService.sendMessage(
        agentType: AgentType.bazsu,
        message: json.encode(baDzyData),
      );

      debugPrint('[ChatCubit] Получен ответ от агента Ба-Дзы');

      // [ChatCubit] Показываем ответ пользователю
      _showResponseMessage(response, enableStreaming: true);
    } catch (e, stackTrace) {
      debugPrint('[ChatCubit] ОШИБКА при обработке Ба-Дзы: $e');
      debugPrint('[ChatCubit] StackTrace: $stackTrace');

      addBotMessage(
        'Произошла ошибка при анализе ваших данных. Пожалуйста, попробуйте еще раз.',
      );
    }
  }

  // ===============================================
  // ПУБЛИЧНЫЕ МЕТОДЫ ДЛЯ UI
  // ===============================================

  /// Добавление сообщения от бота
  void addBotMessage(String text, {bool enableStreaming = false}) {
    final newMessage = MessageEntity(
      text: text,
      isMe: false,
      timestamp: DateTime.now(),
      isStreaming: enableStreaming,
    );

    final updatedMessages = List<MessageEntity>.from(state.messages)
      ..insert(0, newMessage);

    // ИСПРАВЛЕНИЕ: Не изменяем isLoading если уже false, чтобы не влиять на состояние кнопки
    emit(
      state.copyWith(
        messages: updatedMessages,
        isLoading: state.isLoading ? false : state.isLoading,
      ),
    );

    // [ChatCubit] Сохраняем сообщение бота в чат Ба-Дзы, если это BaDzy entrypoint
    if (_currentEntrypoint is BaDzyEntrypointEntity) {
      _saveBaDzyMessage(newMessage);
    }

    // Настраиваем streaming, если нужно
    if (enableStreaming) {
      _orchestratorService.setupMessageStreaming(
        message: newMessage,
        onStreamingComplete: () => _stopMessageStreaming(newMessage),
      );
    }
  }

  /// Загрузка гороскопа Ба-Дзы
  Future<MessageEntity?> loadBaDzyHoroscope() async {
    try {
      return await _baDzyChatService.loadBaDzyHoroscope();
    } catch (e) {
      debugPrint('[ChatCubit] ОШИБКА при загрузке гороскопа Ба-Дзы: $e');
      return null;
    }
  }

  /// Проверка существования гороскопа Ба-Дзы
  Future<bool> hasBaDzyHoroscope() async {
    try {
      return await _baDzyChatService.hasBaDzyHoroscope();
    } catch (e) {
      debugPrint('[ChatCubit] ОШИБКА при проверке гороскопа Ба-Дзы: $e');
      return false;
    }
  }

  /// Получение даты создания гороскопа Ба-Дзы
  Future<DateTime?> getBaDzyHoroscopeDate() async {
    try {
      return await _baDzyChatService.getBaDzyHoroscopeDate();
    } catch (e) {
      debugPrint('[ChatCubit] ОШИБКА при получении даты гороскопа Ба-Дзы: $e');
      return null;
    }
  }

  /// Очистка чата Ба-Дзы в режиме дебага
  Future<void> clearBaDzyChat() async {
    if (_currentEntrypoint is! BaDzyEntrypointEntity) {
      debugPrint('[ChatCubit] Попытка очистки Ба-Дзы для не-Ба-Дзы entrypoint');
      return;
    }

    try {
      debugPrint('[ChatCubit] Очищаем чат Ба-Дзы');

      // Очищаем сохраненный чат (включая гороскоп)
      await _baDzyChatService.clearBaDzyChat();

      // Создаем новое начальное сообщение
      final initialBotMessage = MessageEntity(
        text: 'пожалуйста напиши место своего рождения',
        isMe: false,
        timestamp: DateTime.now(),
      );

      final messages = [initialBotMessage];

      // Сохраняем новое начальное сообщение
      await _baDzyChatService.saveBaDzyMessages(messages);

      // Обновляем состояние
      emit(state.copyWith(messages: messages));

      debugPrint('[ChatCubit] Чат Ба-Дзы успешно очищен и сброшен');
    } catch (e) {
      debugPrint('[ChatCubit] ОШИБКА при очистке чата Ба-Дзы: $e');
    }
  }

  /// Очистка сообщений
  void clearMessages() {
    debugPrint('[ChatCubit] Очистка сообщений');

    // Очищаем текущий чат ID в сервисе истории
    _historyService.clearCurrentChat();

    emit(
      state.copyWith(
        messages: const [],
        currentInput: '',
        isSendAvailable: false,
        isButtonAvailable: false,
        isLoading: false,
        loadingMessageIndex: -1,
        currentQuestionContext: const [],
        clearLastHexagramContext: true,
        clearCurrentChatId: true,
      ),
    );
  }

  /// Начало нового вопроса
  void startNewQuestion() {
    debugPrint('[ChatCubit] Начало нового вопроса');

    // Очищаем текущий чат ID для создания нового чата
    _historyService.clearCurrentChat();

    emit(
      state.copyWith(
        currentQuestionContext: const [],
        clearLastHexagramContext: true,
        isButtonAvailable: false,
        clearCurrentChatId: true,
      ),
    );
  }

  /// Проверка возможности начать новое гадание - НОВАЯ ЛОГИКА: ВСЕГДА разрешаем
  Future<bool> checkCanStartNewReading() async {
    debugPrint('[ChatCubit] НОВАЯ ЛОГИКА: Всегда разрешаем начать гадание');
    debugPrint(
      '[ChatCubit] Проверка подписки происходит ТОЛЬКО после бросков монет',
    );

    // НОВАЯ ЛОГИКА: ВСЕГДА разрешаем начать гадание
    // Проверка подписки будет происходить в processAfterShaking
    return true;
  }

  /// Навигация на экран оплаты
  void _navigateToPaywall() {
    debugPrint('[ChatCubit] Переход на paywall');
    clearMessages();
    emit(state.copyWith(shouldNavigateToPaywall: true));
  }

  /// Навигация на экран оплаты после встряхивания (новая логика)
  void _navigateToPaywallAfterShaking({required bool isFirstReading}) {
    debugPrint(
      '[ChatCubit] Переход на paywall после встряхивания, первое гадание: $isFirstReading',
    );

    // НЕ очищаем сообщения - оставляем чат как есть
    // Устанавливаем специальный флаг для paywall после встряхивания
    emit(
      state.copyWith(
        shouldNavigateToPaywall: true,
        // Можно добавить дополнительную информацию о типе paywall
      ),
    );
  }

  /// Запуск фоновой генерации интерпретации
  void _startBackgroundInterpretation(
    String userQuestion,
    HexagramPair hexagramPair,
  ) {
    debugPrint('[ChatCubit] Запуск фоновой генерации интерпретации');

    // Запускаем асинхронно в фоне
    () async {
      try {
        debugPrint('[ChatCubit] Начинаем фоновую генерацию интерпретации');

        // Получаем интерпретацию от DeepSeek
        final interpretationResult = await _deepSeekService
            .interpretHexagramsStructured(
              question: userQuestion,
              primaryHexagram: hexagramPair.primary,
              secondaryHexagram: hexagramPair.secondary,
            );

        // Сохраняем результат
        _backgroundInterpretationResult = interpretationResult;

        debugPrint('[ChatCubit] Фоновая интерпретация завершена');
      } catch (e) {
        debugPrint('[ChatCubit] Ошибка фоновой интерпретации: $e');
        _backgroundInterpretationResult = null;
      }
    }();
  }

  /// Сброс флага навигации на paywall
  void resetPaywallNavigation() {
    emit(state.copyWith(shouldNavigateToPaywall: false));
  }

  /// Обработка возврата из paywall после встряхивания
  Future<void> handleReturnFromPaywallAfterShaking() async {
    debugPrint('[ChatCubit] Обработка возврата из paywall после встряхивания');

    if (_pendingHexagramPair == null || _pendingUserQuestion == null) {
      debugPrint(
        '[ChatCubit] Нет сохраненного контекста для возврата из paywall',
      );
      return;
    }

    // Создаем индикатор загрузки
    _showLoadingMessage();

    try {
      // Проверяем есть ли готовая интерпретация из фона
      dynamic interpretationResult = _backgroundInterpretationResult;

      if (interpretationResult == null) {
        debugPrint(
          '[ChatCubit] Фоновая интерпретация не готова, запрашиваем заново',
        );

        // Получаем интерпретацию от DeepSeek
        interpretationResult = await _deepSeekService
            .interpretHexagramsStructured(
              question: _pendingUserQuestion!,
              primaryHexagram: _pendingHexagramPair!.primary,
              secondaryHexagram: _pendingHexagramPair!.secondary,
            );
      } else {
        debugPrint('[ChatCubit] Используем готовую фоновую интерпретацию');
      }

      // Создаем результат для показа
      final result = ShakeProcessingResult.success(
        hexagramPair: _pendingHexagramPair!,
        interpretationResult: interpretationResult,
        userQuestion: _pendingUserQuestion!,
        updatedSubscriptionStatus:
            await _orchestratorService.getSubscriptionStatus(),
      );

      // Показываем результат
      await _showHexagramResult(result);

      // Устанавливаем флаг использования бесплатного гадания ПОСЛЕ покупки подписки
      // Это необходимо для пользователей, которые ранее не делали гаданий
      if (_isFirstReading) {
        await _orchestratorService.markFreeReadingAsUsed();
        await _updateSubscriptionStatus();
        debugPrint(
          '[ChatCubit] Бесплатное гадание помечено как использованное после покупки',
        );
      }
    } catch (e) {
      debugPrint('[ChatCubit] Ошибка при обработке возврата из paywall: $e');
      _showErrorMessage(
        'Произошла ошибка при получении интерпретации. Пожалуйста, попробуйте еще раз.',
      );
    } finally {
      // Очищаем временные данные
      _pendingHexagramPair = null;
      _pendingUserQuestion = null;
      _isFirstReading = false;
      _backgroundInterpretationResult = null;
    }
  }

  // ===============================================
  // HYDRATED BLOC МЕТОДЫ
  // ===============================================

  @override
  ChatState? fromJson(Map<String, dynamic> json) => ChatState.fromJson(json);

  @override
  Map<String, dynamic>? toJson(ChatState state) => state.toJson();

  @override
  Future<void> clear() async {
    debugPrint('[ChatCubit] Полная очистка состояния');

    // Останавливаем все streaming
    _orchestratorService.stopAllStreaming();

    // Очищаем текущий чат в истории
    await _historyService.clearCurrentChat();

    // Сбрасываем состояние
    emit(const ChatState());

    // Вызываем очистку в родительском классе
    await super.clear();

    // Обновляем статус подписки
    await _updateSubscriptionStatus();

    debugPrint('[ChatCubit] Состояние полностью очищено');
  }

  /// Генерация новых рекомендаций после успешного гадания на И Дзин
  void _generateNewRecommendationsAfterDivination() {
    debugPrint(
      '[ChatCubit] Запускаем генерацию новых рекомендаций после гадания',
    );

    // Запускаем генерацию в фоне, не блокируя UI
    _recommendationsService
        .generateNewRecommendationsAfterDivination()
        .then((result) {
          if (result.success) {
            debugPrint(
              '[ChatCubit] Новые рекомендации после гадания сгенерированы успешно',
            );
          } else {
            debugPrint(
              '[ChatCubit] Ошибка при генерации новых рекомендаций: ${result.message}',
            );
          }
        })
        .catchError((error) {
          debugPrint(
            '[ChatCubit] Исключение при генерации новых рекомендаций: $error',
          );
        });
  }

  @override
  Future<void> close() async {
    debugPrint('[ChatCubit] Закрытие кубита');
    _orchestratorService.dispose();
    return super.close();
  }
}
