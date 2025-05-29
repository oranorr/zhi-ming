import 'package:flutter/foundation.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:zhi_ming/core/services/shake_service/shaker_service_repo.dart';
import 'package:zhi_ming/features/chat/domain/message_entity.dart';
import 'package:zhi_ming/features/chat/presentation/models/chat_state.dart';
import 'package:zhi_ming/features/chat/presentation/services/chat_orchestrator_service.dart';
import 'package:zhi_ming/features/chat/presentation/services/chat_validation_service.dart';

/// Оптимизированный ChatCubit с делегированием бизнес-логики в сервисы
/// Фокусируется только на управлении состоянием и координации операций
class ChatCubit extends HydratedCubit<ChatState> {
  ChatCubit() : super(const ChatState()) {
    _orchestratorService = ChatOrchestratorService();
    _initializeServices();
  }

  late final ChatOrchestratorService _orchestratorService;

  /// Инициализация всех сервисов
  Future<void> _initializeServices() async {
    debugPrint('[ChatCubit] Инициализация сервисов');
    await _orchestratorService.initialize();
    await _updateSubscriptionStatus();
    debugPrint('[ChatCubit] Сервисы инициализированы');
  }

  /// Обновление статуса подписки
  Future<void> _updateSubscriptionStatus() async {
    final status = await _orchestratorService.getSubscriptionStatus();
    emit(
      state.copyWith(
        hasActiveSubscription: status.hasActiveSubscription,
        remainingFreeRequests: status.remainingFreeRequests,
      ),
    );
  }

  // ===============================================
  // МЕТОДЫ УПРАВЛЕНИЯ ИНТЕРФЕЙСОМ
  // ===============================================

  /// Показ начального сообщения от бота
  void showInitialMessage() {
    debugPrint('[ChatCubit] Показываем начальное сообщение');

    final initialBotMessage = MessageEntity(
      text: '请描述你的问题或你想关注的具体情况。',
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

    // Определяем тип обработки сообщения
    if (state.hasHexagramContext) {
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
                result.updatedSubscriptionStatus!.hasActiveSubscription,
            remainingFreeRequests:
                result.updatedSubscriptionStatus!.remainingFreeRequests,
          ),
        );
      }
    } else if (result.requiresPaywall) {
      _showErrorMessage(result.message);
      _navigateToPaywall();
    } else {
      _showErrorMessage(result.message);
    }
  }

  /// Обработка встряхивания
  Future<void> processAfterShaking(ShakerServiceRepo shakerService) async {
    debugPrint('[ChatCubit] Обработка встряхивания');
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

    // Создаем индикатор загрузки
    _showLoadingMessage();

    // Задержка для UX
    await Future.delayed(const Duration(seconds: 2));

    // Обрабатываем через оркестратор
    final result = await _orchestratorService.processAfterShaking(
      shakerService: shakerService,
      userQuestion: userQuestion,
    );

    // Обрабатываем результат
    if (result.isSuccess) {
      _showHexagramResult(result);
    } else if (result.requiresPaywall) {
      _showErrorMessage(result.message);
      _navigateToPaywall();
    } else {
      _showErrorMessage(result.message);
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
  void _showHexagramResult(ShakeProcessingResult result) {
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

    // ИСПРАВЛЕНИЕ: Убираем отдельный вызов _replaceLoadingMessage
    // _replaceLoadingMessage(resultMessage);

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

    // ИСПРАВЛЕНИЕ: Объединяем обновление сообщений и установку контекста в один emit
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
            result.updatedSubscriptionStatus!.hasActiveSubscription,
        remainingFreeRequests:
            result.updatedSubscriptionStatus!.remainingFreeRequests,
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
    } else if (result.isError &&
        _orchestratorService.shouldNavigateToPaywall(
          hasActiveSubscription: state.hasActiveSubscription,
          remainingFreeRequests: state.remainingFreeRequests,
        )) {
      // Ошибка из-за лимитов - переходим на paywall
      _showErrorMessage(result.message);
      _navigateToPaywall();
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
      updatedMessages[messageIndex] = updatedMessages[messageIndex].copyWith(
        isStreaming: false,
      );
      emit(state.copyWith(messages: updatedMessages));
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

    // Настраиваем streaming, если нужно
    if (enableStreaming) {
      _orchestratorService.setupMessageStreaming(
        message: newMessage,
        onStreamingComplete: () => _stopMessageStreaming(newMessage),
      );
    }
  }

  /// Очистка сообщений
  void clearMessages() {
    debugPrint('[ChatCubit] Очистка сообщений');
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
      ),
    );
  }

  /// Начало нового вопроса
  void startNewQuestion() {
    debugPrint('[ChatCubit] Начало нового вопроса');
    emit(
      state.copyWith(
        currentQuestionContext: const [],
        clearLastHexagramContext: true,
        isButtonAvailable: false,
      ),
    );
  }

  /// Навигация на экран оплаты
  void _navigateToPaywall() {
    debugPrint('[ChatCubit] Переход на paywall');
    clearMessages();
    emit(state.copyWith(shouldNavigateToPaywall: true));
  }

  /// Сброс флага навигации на paywall
  void resetPaywallNavigation() {
    emit(state.copyWith(shouldNavigateToPaywall: false));
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

    // Сбрасываем состояние
    emit(const ChatState());

    // Вызываем очистку в родительском классе
    await super.clear();

    // Обновляем статус подписки
    await _updateSubscriptionStatus();

    debugPrint('[ChatCubit] Состояние полностью очищено');
  }

  @override
  Future<void> close() async {
    debugPrint('[ChatCubit] Закрытие кубита');
    _orchestratorService.dispose();
    return super.close();
  }
}
