import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:zhi_ming/core/services/adapty/adapty_service.dart';
import 'package:zhi_ming/core/services/adapty/adapty_service_impl.dart';
import 'package:zhi_ming/core/services/deepseek/deepseek_service.dart';
import 'package:zhi_ming/core/services/deepseek/models/message.dart';
import 'package:zhi_ming/core/services/shake_service/shaker_service_repo.dart';
import 'package:zhi_ming/features/chat/domain/message_entity.dart';
import 'package:zhi_ming/features/iching/models/hexagram.dart';

part 'chat_cubit_legacy.g.dart';

@JsonSerializable()
class ChatState extends Equatable {
  const ChatState({
    this.isButtonAvailable = false,
    this.isSendAvailable = false,
    this.isLoading = false,
    this.messages = const [],
    this.currentInput = '',
    this.loadingMessageIndex = -1,
    this.lastHexagramContext, // Добавляем контекст последнего гадания
    this.currentQuestionContext =
        const [], // Контекст текущего формирующегося вопроса
    this.hasActiveSubscription = false, // Статус подписки
    this.remainingFreeRequests = 0, // Количество оставшихся бесплатных запросов
    this.shouldNavigateToPaywall = false, // Флаг для навигации на paywall
  });
  factory ChatState.fromJson(Map<String, dynamic> json) =>
      _$ChatStateFromJson(json);
  final bool isButtonAvailable;
  final bool isSendAvailable;
  final bool isLoading;
  final List<MessageEntity> messages;
  final String currentInput;
  final int loadingMessageIndex; // Индекс сообщения с индикатором загрузки
  final HexagramContext? lastHexagramContext; // Контекст последнего гадания
  final List<String>
  currentQuestionContext; // Накопленный контекст текущего вопроса
  final bool hasActiveSubscription; // Статус подписки
  final int remainingFreeRequests; // Количество оставшихся бесплатных запросов
  final bool shouldNavigateToPaywall; // Флаг для навигации на paywall

  ChatState copyWith({
    bool? isButtonAvailable,
    bool? isSendAvailable,
    bool? isLoading,
    List<MessageEntity>? messages,
    String? currentInput,
    int? loadingMessageIndex,
    HexagramContext? lastHexagramContext,
    List<String>? currentQuestionContext,
    bool? hasActiveSubscription,
    int? remainingFreeRequests,
    bool? shouldNavigateToPaywall,
  }) {
    return ChatState(
      isButtonAvailable: isButtonAvailable ?? this.isButtonAvailable,
      isSendAvailable: isSendAvailable ?? this.isSendAvailable,
      isLoading: isLoading ?? this.isLoading,
      messages: messages ?? this.messages,
      currentInput: currentInput ?? this.currentInput,
      loadingMessageIndex: loadingMessageIndex ?? this.loadingMessageIndex,
      lastHexagramContext: lastHexagramContext ?? this.lastHexagramContext,
      currentQuestionContext:
          currentQuestionContext ?? this.currentQuestionContext,
      hasActiveSubscription:
          hasActiveSubscription ?? this.hasActiveSubscription,
      remainingFreeRequests:
          remainingFreeRequests ?? this.remainingFreeRequests,
      shouldNavigateToPaywall:
          shouldNavigateToPaywall ?? this.shouldNavigateToPaywall,
    );
  }

  Map<String, dynamic> toJson() => _$ChatStateToJson(this);

  @override
  List<Object?> get props => [
    isButtonAvailable,
    isSendAvailable,
    isLoading,
    messages,
    currentInput,
    loadingMessageIndex,
    lastHexagramContext,
    currentQuestionContext,
    hasActiveSubscription,
    remainingFreeRequests,
    shouldNavigateToPaywall,
  ];
}

// Класс для хранения контекста последнего гадания
@JsonSerializable()
class HexagramContext {
  const HexagramContext({
    required this.originalQuestion,
    required this.primaryHexagram,
    required this.interpretation,
    this.secondaryHexagram,
  });

  factory HexagramContext.fromJson(Map<String, dynamic> json) =>
      _$HexagramContextFromJson(json);

  final String originalQuestion;
  final Hexagram primaryHexagram;
  final Hexagram? secondaryHexagram;
  final String interpretation;

  Map<String, dynamic> toJson() => _$HexagramContextToJson(this);
}

class ChatCubit extends HydratedCubit<ChatState> {
  ChatCubit() : super(const ChatState()) {
    _deepSeekService = DeepSeekService();
    _adaptyService = AdaptyServiceImpl();
    _initializeServices();
  }

  late final DeepSeekService _deepSeekService;
  late final AdaptyService _adaptyService;

  /// Инициализация сервисов и загрузка данных о подписке
  Future<void> _initializeServices() async {
    await _adaptyService.init();
    await _updateSubscriptionStatus();
  }

  /// Обновление статуса подписки и счетчика запросов
  Future<void> _updateSubscriptionStatus() async {
    final hasSubscription = await _adaptyService.hasActiveSubscription();
    final remainingRequests = await _adaptyService.getRemainingFreeRequests();

    emit(
      state.copyWith(
        hasActiveSubscription: hasSubscription,
        remainingFreeRequests: remainingRequests,
      ),
    );
  }

  void showInitialMessage() {
    final initialBotMessage = MessageEntity(
      text: '请描述你的问题或你想关注的具体情况。',
      isMe: false,
      timestamp: DateTime.now(),
    );

    final updatedMessages = List<MessageEntity>.from(state.messages)
      ..insert(0, initialBotMessage);

    emit(state.copyWith(messages: updatedMessages));
  }

  void updateInput(String text) {
    emit(
      state.copyWith(
        currentInput: text,
        isSendAvailable: text.trim().isNotEmpty,
      ),
    );
  }

  void toggleButton(bool available) {
    emit(state.copyWith(isButtonAvailable: available));
  }

  void sendMessage() {
    if (state.currentInput.trim().isEmpty) return;

    final newMessage = MessageEntity(
      text: state.currentInput.trim(),
      isMe: true,
      timestamp: DateTime.now(),
    );

    final updatedMessages = List<MessageEntity>.from(state.messages)
      ..insert(0, newMessage);

    emit(
      state.copyWith(
        messages: updatedMessages,
        currentInput: '',
        isSendAvailable: false,
      ),
    );

    // Проверяем, есть ли контекст последнего гадания
    if (state.lastHexagramContext != null) {
      // Если есть контекст последнего гадания, обрабатываем как последующий вопрос
      handleFollowUpQuestion(state.messages[0].text);
    } else {
      // Если контекста последнего гадания нет, работаем с контекстом текущего вопроса

      // Добавляем новое сообщение к контексту текущего вопроса
      final updatedQuestionContext = List<String>.from(
        state.currentQuestionContext,
      )..add(state.messages[0].text);

      // Обновляем состояние с новым контекстом
      emit(state.copyWith(currentQuestionContext: updatedQuestionContext));

      // Валидируем весь накопленный контекст
      validateUserRequest(updatedQuestionContext);
    }
  }

  Future<void> handleFollowUpQuestion(String question) async {
    debugPrint(
      '[handleFollowUpQuestion] Начало обработки последующего вопроса: $question',
    );

    // Проверяем наличие контекста последнего гадания
    if (state.lastHexagramContext == null) {
      debugPrint(
        '[handleFollowUpQuestion] ОШИБКА: Нет контекста последнего гадания',
      );
      addBotMessage(
        'Для задания дополнительных вопросов необходимо сначала провести гадание.',
      );
      return;
    }

    // Проверяем возможность выполнения запроса
    final canMakeRequest =
        state.hasActiveSubscription || state.remainingFreeRequests > 0;

    if (!canMakeRequest) {
      debugPrint(
        '[handleFollowUpQuestion] БЛОКИРУЕМ ЗАПРОС - нет подписки и закончились бесплатные запросы',
      );
      addBotMessage(
        'Вы исчерпали все бесплатные запросы. Для продолжения необходимо оформить подписку.',
      );
      navigateToPaywall();
      return;
    }

    // Создаем сообщение с индикатором загрузки
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

    try {
      // Получаем контекст последнего гадания
      final context = state.lastHexagramContext!;

      // Формируем историю диалога для контекста
      final conversationHistory =
          state.messages
              .where(
                (m) => !m.isMe && m.hexagrams == null,
              ) // Исключаем сообщения с гексаграммами
              .map((m) => DeepSeekMessage(role: 'assistant', content: m.text))
              .toList();

      // Отправляем запрос на обработку последующего вопроса
      final response = await _deepSeekService.handleFollowUpQuestion(
        question: question,
        originalQuestion: context.originalQuestion,
        primaryHexagram: context.primaryHexagram,
        secondaryHexagram: context.secondaryHexagram,
        previousInterpretation: context.interpretation,
        conversationHistory: conversationHistory,
      );

      // Уменьшаем счетчик бесплатных запросов после успешного ответа
      await _adaptyService.decrementFreeRequests();
      await _updateSubscriptionStatus();

      // Создаем сообщение с ответом и включаем streaming
      final responseMessage = MessageEntity(
        text: response,
        isMe: false,
        timestamp: DateTime.now(),
        isStreaming: true, // Включаем streaming эффект
      );

      final messagesWithResponse = List<MessageEntity>.from(state.messages);
      if (state.loadingMessageIndex >= 0 &&
          state.loadingMessageIndex < messagesWithResponse.length) {
        messagesWithResponse[state.loadingMessageIndex] = responseMessage;
      }

      emit(
        state.copyWith(
          messages: messagesWithResponse,
          isLoading: false,
          loadingMessageIndex: -1,
        ),
      );

      // Отключаем streaming через рассчитанное время
      Future.delayed(Duration(milliseconds: response.length * 30 + 500), () {
        if (state.messages.isNotEmpty &&
            state.messages.any((m) => m.text == response && m.isStreaming)) {
          final updatedStreamingMessages = List<MessageEntity>.from(
            state.messages,
          );
          final messageIndex = updatedStreamingMessages.indexWhere(
            (m) => m.text == response && m.isStreaming,
          );
          if (messageIndex != -1) {
            updatedStreamingMessages[messageIndex] =
                updatedStreamingMessages[messageIndex].copyWith(
                  isStreaming: false,
                );
            emit(state.copyWith(messages: updatedStreamingMessages));
          }
        }
      });
    } catch (e) {
      debugPrint('Ошибка при обработке последующего вопроса: $e');

      final errorMessage = MessageEntity(
        text:
            'Произошла ошибка при обработке вашего вопроса. Пожалуйста, попробуйте сформулировать его иначе.',
        isMe: false,
        timestamp: DateTime.now(),
      );

      final messagesWithError = List<MessageEntity>.from(state.messages);
      if (state.loadingMessageIndex >= 0 &&
          state.loadingMessageIndex < messagesWithError.length) {
        messagesWithError[state.loadingMessageIndex] = errorMessage;
      }

      emit(
        state.copyWith(
          messages: messagesWithError,
          isLoading: false,
          loadingMessageIndex: -1,
        ),
      );
    }
  }

  Future<void> validateUserRequest(List<String> questionContext) async {
    // Проверяем, может ли пользователь сделать запрос
    final canMakeRequest = await _adaptyService.canMakeRequest();

    if (!canMakeRequest) {
      // Если пользователь не может сделать запрос, показываем сообщение и переходим на paywall
      final limitMessage = MessageEntity(
        text:
            'Вы исчерпали все бесплатные запросы. Для продолжения необходимо оформить подписку.',
        isMe: false,
        timestamp: DateTime.now(),
      );

      final updatedMessages = List<MessageEntity>.from(state.messages)
        ..insert(0, limitMessage);

      emit(
        state.copyWith(
          messages: updatedMessages,
          isLoading: false,
          loadingMessageIndex: -1,
          isButtonAvailable: false,
        ),
      );

      // Переходим на paywall через небольшую задержку
      Future.delayed(const Duration(seconds: 1), () {
        navigateToPaywall();
      });
      return;
    }

    // Создаем сообщение-индикатор загрузки
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

    // Отправляем весь контекст на валидацию в DeepSeekService
    final validationResponse = await _deepSeekService.validateRequest(
      questionContext,
    );

    print('Получен ответ валидации: $validationResponse');

    // Явно скрываем клавиатуру перед показом результата
    SystemChannels.textInput.invokeMethod('TextInput.hide');

    // Обрабатываем результат валидации
    if (validationResponse.status == 'valid') {
      // Если запрос валидный, предлагаем пользователю продолжить с встряхиванием
      final promptMessage = MessageEntity(
        text: '很好，现在请专注你的问题，摇动手机六次进行投币。',
        isMe: false,
        timestamp: DateTime.now(),
      );

      final messagesWithPrompt = List<MessageEntity>.from(state.messages);
      if (state.loadingMessageIndex >= 0 &&
          state.loadingMessageIndex < messagesWithPrompt.length) {
        messagesWithPrompt[state.loadingMessageIndex] = promptMessage;
      }

      emit(
        state.copyWith(
          messages: messagesWithPrompt,
          isButtonAvailable: true,
          isLoading: false,
          loadingMessageIndex: -1,
          // Очищаем контекст текущего вопроса, так как он стал валидным
          currentQuestionContext: const [],
        ),
      );
    } else if (validationResponse.status == 'invalid') {
      // Если запрос не валидный, показываем сообщение с причиной
      // НЕ очищаем currentQuestionContext - пользователь может добавить уточнение
      final errorMessage = MessageEntity(
        text:
            validationResponse.reasonMessage.isNotEmpty
                ? validationResponse.reasonMessage
                : 'Ваш вопрос не подходит для гадания. Пожалуйста, сформулируйте его иначе.',
        isMe: false,
        timestamp: DateTime.now(),
      );

      final messagesWithError = List<MessageEntity>.from(state.messages);
      if (state.loadingMessageIndex >= 0 &&
          state.loadingMessageIndex < messagesWithError.length) {
        messagesWithError[state.loadingMessageIndex] = errorMessage;
      }

      emit(
        state.copyWith(
          messages: messagesWithError,
          isLoading: false,
          loadingMessageIndex: -1,
          // Не показываем кнопку для встряхивания
          isButtonAvailable: false,
          // НЕ очищаем currentQuestionContext - оставляем для дальнейших уточнений
        ),
      );
    } else {
      // Обработка других статусов (ошибки, неизвестные ответы)
      final errorMessage = MessageEntity(
        text:
            'Извините, произошла ошибка при обработке вашего вопроса. Пожалуйста, попробуйте еще раз или сформулируйте вопрос иначе.',
        isMe: false,
        timestamp: DateTime.now(),
      );

      final messagesWithError = List<MessageEntity>.from(state.messages);
      if (state.loadingMessageIndex >= 0 &&
          state.loadingMessageIndex < messagesWithError.length) {
        messagesWithError[state.loadingMessageIndex] = errorMessage;
      }

      emit(
        state.copyWith(
          messages: messagesWithError,
          isLoading: false,
          loadingMessageIndex: -1,
          isButtonAvailable: false,
          // В случае ошибки очищаем контекст, чтобы пользователь начал заново
          currentQuestionContext: const [],
        ),
      );
    }
  }

  /// Навигация на экран paywall
  void navigateToPaywall() {
    debugPrint('=== ПЕРЕХОД НА PAYWALL - ОЧИСТКА СОСТОЯНИЯ ===');

    // Очищаем состояние чата перед переходом на paywall
    clearMessages();

    // Устанавливаем флаг для навигации на paywall с дополнительной очисткой
    emit(
      state.copyWith(
        isLoading: false,
        isButtonAvailable: false,
        shouldNavigateToPaywall: true,
        currentQuestionContext:
            const [], // Дополнительно очищаем контекст вопроса
      ),
    );

    debugPrint('=== СОСТОЯНИЕ ОЧИЩЕНО ПЕРЕД PAYWALL ===');
  }

  /// Сброс флага навигации на paywall
  void resetPaywallNavigation() {
    emit(state.copyWith(shouldNavigateToPaywall: false));
  }

  Future<void> processAfterShaking(ShakerServiceRepo shakerService) async {
    // Явно скрываем клавиатуру
    SystemChannels.textInput.invokeMethod('TextInput.hide');

    // ПРОВЕРЯЕМ ПОДПИСКУ И БЕСПЛАТНЫЕ ЗАПРОСЫ ПЕРЕД НАЧАЛОМ ОБРАБОТКИ
    debugPrint('=== ПРОВЕРКА ПОДПИСКИ В processAfterShaking ===');
    final hasSubscription = await _adaptyService.hasActiveSubscription();
    final remainingRequests = await _adaptyService.getRemainingFreeRequests();
    debugPrint('Активная подписка: $hasSubscription');
    debugPrint('Оставшиеся бесплатные запросы: $remainingRequests');

    final canMakeRequest = await _adaptyService.canMakeRequest();
    debugPrint('Может ли сделать запрос: $canMakeRequest');

    if (!canMakeRequest) {
      debugPrint(
        'БЛОКИРУЕМ ЗАПРОС - нет подписки и закончились бесплатные запросы',
      );
      // Если пользователь не может сделать запрос, показываем сообщение и переходим на paywall
      final limitMessage = MessageEntity(
        text:
            'Вы исчерпали все бесплатные запросы. Для продолжения необходимо оформить подписку.',
        isMe: false,
        timestamp: DateTime.now(),
      );

      final updatedMessages = List<MessageEntity>.from(state.messages)
        ..insert(0, limitMessage);

      emit(
        state.copyWith(
          messages: updatedMessages,
          isLoading: false,
          loadingMessageIndex: -1,
          isButtonAvailable: false,
        ),
      );

      // Переходим на paywall через небольшую задержку
      Future.delayed(const Duration(seconds: 1), () {
        navigateToPaywall();
      });
      return;
    }

    debugPrint('РАЗРЕШАЕМ ЗАПРОС - продолжаем обработку гексаграмм');

    // Создаем пустое сообщение от бота, которое будет показывать индикатор загрузки
    final loadingMessage = MessageEntity(
      text: '', // Текст будет пустым, так как мы показываем только индикатор
      isMe: false,
      timestamp: DateTime.now(),
    );

    // Добавляем сообщение с индикатором загрузки и убираем кнопку
    final updatedMessages = List<MessageEntity>.from(state.messages)
      ..insert(0, loadingMessage);

    // Устанавливаем состояние загрузки и сохраняем индекс сообщения с загрузкой
    emit(
      state.copyWith(
        messages: updatedMessages,
        isLoading: true,
        isButtonAvailable: false,
        loadingMessageIndex: 0, // Индекс первого сообщения в списке
      ),
    );

    // Задержка перед финальным ответом
    Future.delayed(const Duration(seconds: 2), () async {
      // Уменьшаем счетчик бесплатных запросов после успешного гадания
      await _adaptyService.decrementFreeRequests();
      await _updateSubscriptionStatus();

      // Получаем значения линий (суммы бросков) из ShakerService
      final List<int> lineValues = shakerService.getLineValues();

      print('Chat: получены значения линий: $lineValues');

      // Получаем все броски (для отладки)
      final List<List<int>> coinThrows = shakerService.getCoinThrows();
      print('Chat: исходные броски монет: $coinThrows');

      // Если не получены все 6 линий, добавляем недостающие для полноты гексаграммы
      final List<int> completeLineValues = List<int>.from(lineValues);
      while (completeLineValues.length < 6) {
        // Добавляем значение по умолчанию (8 - молодой инь) для недостающих линий
        completeLineValues.add(8);
      }

      print(
        'Chat: использую значения линий для генерации гексаграммы: $completeLineValues',
      );

      // Загружаем данные о гексаграммах
      await _loadHexagramsData();

      // Генерируем гексаграмму на основе значений линий
      final originalHexagram = _generateHexagramFromLines(completeLineValues);
      print(
        'Chat: сгенерирована гексаграмма: ${originalHexagram.number} (${originalHexagram.name})',
      );

      // Создаем измененную гексаграмму
      Hexagram? changedHexagram;
      if (originalHexagram.lines.any((line) => line.isChanging)) {
        // Получаем измененные линии
        final changedLines =
            originalHexagram.lines.map((line) => line.changedLine).toList();

        // Создаем бинарное представление измененной гексаграммы
        String binaryRepresentation = '';
        for (int i = changedLines.length - 1; i >= 0; i--) {
          binaryRepresentation += changedLines[i].isYang ? '1' : '0';
        }

        print(
          'Бинарное представление измененной гексаграммы: $binaryRepresentation',
        );

        // Ищем информацию об измененной гексаграмме
        final hexagramInfo = _findHexagramByBinary(binaryRepresentation);

        if (hexagramInfo != null && hexagramInfo.isNotEmpty) {
          changedHexagram = Hexagram(
            lines: changedLines,
            number: hexagramInfo['number'],
            name: hexagramInfo['name'],
            description: hexagramInfo['description'],
          );

          print(
            'Chat: изменяющаяся гексаграмма: ${changedHexagram.number} (${changedHexagram.name})',
          );
        }
      }

      // Получаем вопрос пользователя (первое сообщение в истории)
      final userQuestion =
          state.messages
              .firstWhere(
                (m) => m.isMe,
                orElse:
                    () => MessageEntity(
                      text: '',
                      isMe: true,
                      timestamp: DateTime.now(),
                    ),
              )
              .text;

      print('=== Начало обработки интерпретации ===');
      print('Отправляем на интерпретацию:');
      print('- Вопрос: $userQuestion');
      print(
        '- Первичная гексаграмма: ${originalHexagram.number} (${originalHexagram.name})',
      );
      if (changedHexagram != null) {
        print(
          '- Вторичная гексаграмма: ${changedHexagram.number} (${changedHexagram.name})',
        );
      }

      // Отправляем гексаграммы на интерпретацию с новым структурированным API
      final interpretationResult = await _deepSeekService
          .interpretHexagramsStructured(
            question: userQuestion,
            primaryHexagram: originalHexagram,
            secondaryHexagram: changedHexagram,
          );

      print('Получена интерпретация:');
      print(interpretationResult.runtimeType);

      // Определяем тип интерпретации и создаем соответствующее сообщение
      MessageEntity resultMessage;

      if (interpretationResult is SimpleInterpretation) {
        print('Получена простая интерпретация');
        resultMessage = MessageEntity(
          text:
              '', // Текст пустой, так как используем структурированную интерпретацию
          isMe: false,
          timestamp: DateTime.now(),
          hexagrams: [originalHexagram], // Только одна гексаграмма
          simpleInterpretation: interpretationResult,
        );
      } else if (interpretationResult is ComplexInterpretation) {
        print('Получена сложная интерпретация');
        resultMessage = MessageEntity(
          text:
              '', // Текст пустой, так как используем структурированную интерпретацию
          isMe: false,
          timestamp: DateTime.now(),
          hexagrams:
              changedHexagram != null
                  ? [originalHexagram, changedHexagram]
                  : [originalHexagram],
          complexInterpretation: interpretationResult,
        );
      } else {
        // Fallback для обратной совместимости - если получили обычный текст
        print('Получена текстовая интерпретация (fallback)');
        final interpretation = interpretationResult.toString();

        // Обновляем гексаграммы с интерпретацией (старый способ)
        final interpretedOriginalHexagram = originalHexagram.copyWith(
          interpretation: interpretation,
        );

        final interpretedChangedHexagram = changedHexagram?.copyWith(
          interpretation: interpretation,
        );

        resultMessage = MessageEntity(
          text: '', // Текст пустой, так как интерпретация будет в гексаграммах
          isMe: false,
          timestamp: DateTime.now(),
          hexagrams:
              interpretedChangedHexagram != null
                  ? [interpretedOriginalHexagram, interpretedChangedHexagram]
                  : [interpretedOriginalHexagram],
        );
      }

      print('Создано сообщение с результатом');
      print('=== Конец обработки интерпретации ===');

      final updatedMessages = List<MessageEntity>.from(state.messages);
      if (state.loadingMessageIndex >= 0 &&
          state.loadingMessageIndex < updatedMessages.length) {
        // Заменяем сообщение с загрузкой на сообщение с гексаграммами и интерпретацией
        updatedMessages[state.loadingMessageIndex] = resultMessage;
      }

      // После получения интерпретации сохраняем контекст
      // Для контекста используем текстовое представление интерпретации
      String contextInterpretation;
      if (interpretationResult is SimpleInterpretation) {
        contextInterpretation = interpretationResult.answer;
      } else if (interpretationResult is ComplexInterpretation) {
        contextInterpretation = interpretationResult.answer;
      } else {
        contextInterpretation = interpretationResult.toString();
      }

      final hexagramContext = HexagramContext(
        originalQuestion: userQuestion,
        primaryHexagram: originalHexagram,
        secondaryHexagram: changedHexagram,
        interpretation: contextInterpretation,
      );

      // Обновляем состояние с сохранением контекста
      emit(
        state.copyWith(
          messages: updatedMessages,
          isLoading: false,
          loadingMessageIndex: -1,
          lastHexagramContext: hexagramContext, // Сохраняем контекст
          currentQuestionContext:
              const [], // Очищаем контекст текущего вопроса, так как гадание завершено
        ),
      );

      // Сбрасываем результаты встряхиваний для следующего сеанса гадания
      shakerService.resetCoinThrows();

      // Добавляем пояснение через небольшую задержку
      Future.delayed(const Duration(seconds: 1), () {
        addBotMessage(
          '您可以提出另一个问题或继续对话。',
          enableStreaming:
              true, // Включаем streaming для пояснительного сообщения
        );
      });
    });
  }

  // Метод для генерации гексаграммы на основе значений линий (6, 7, 8, 9)
  Hexagram _generateHexagramFromLines(List<int> lineValues) {
    // Преобразуем значения линий в объекты Line
    print(
      '_generateHexagramFromLines: начинаю генерацию гексаграммы из значений линий: $lineValues',
    );

    final lines = List<Line>.generate(6, (index) {
      if (index < lineValues.length) {
        final value = lineValues[index];
        Line line;
        switch (value) {
          case 6: // старый инь (изменяющийся)
            line = const Line(6);
            print(
              'Line ${index + 1}: значение линии $value -> 6 (инь, изменяющаяся)',
            );
            break;
          case 7: // молодой ян (неизменяющийся)
            line = const Line(7);
            print(
              'Line ${index + 1}: значение линии $value -> 7 (ян, неизменяющаяся)',
            );
            break;
          case 8: // молодой инь (неизменяющийся)
            line = const Line(8);
            print(
              'Line ${index + 1}: значение линии $value -> 8 (инь, неизменяющаяся)',
            );
            break;
          case 9: // старый ян (изменяющийся)
            line = const Line(9);
            print(
              'Line ${index + 1}: значение линии $value -> 9 (ян, изменяющаяся)',
            );
            break;
          default:
            line = const Line(8); // По умолчанию: инь, неизменяющаяся
            print(
              'Line ${index + 1}: неизвестное значение $value, использую по умолчанию -> 8 (инь, неизменяющаяся)',
            );
        }
        return line;
      } else {
        // Если данных от пользователя недостаточно, используем значение по умолчанию
        print(
          'Line ${index + 1}: недостаточно данных, использую значение по умолчанию -> 8 (инь, неизменяющаяся)',
        );
        return const Line(8); // инь, неизменяющаяся
      }
    });

    // Создаем бинарное представление гексаграммы (для поиска в JSON)
    // ВАЖНО: Порядок линий в бинарном представлении - СНИЗУ ВВЕРХ
    String binaryRepresentation = '';
    for (int i = lines.length - 1; i >= 0; i--) {
      binaryRepresentation += lines[i].isYang ? '1' : '0';
    }

    print(
      'Бинарное представление гексаграммы (снизу вверх): $binaryRepresentation',
    );

    // Ищем информацию о гексаграмме по бинарному представлению
    final hexagramInfo = _findHexagramByBinary(binaryRepresentation);

    if (hexagramInfo != null && hexagramInfo.isNotEmpty) {
      // Если нашли информацию, используем ее
      print(
        'Найдена гексаграмма по бинарному представлению: ${hexagramInfo['number']} (${hexagramInfo['name']})',
      );
      return Hexagram(
        lines: lines,
        number: hexagramInfo['number'],
        name: hexagramInfo['name'],
        description: hexagramInfo['description'],
      );
    } else {
      // Если не нашли, вычисляем номер и используем временные данные
      int hexagramNumber = 1;
      int binaryValue = 0;

      // Вычисляем двоичное значение (снизу вверх)
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].isYang) {
          binaryValue |= 1 << i;
        }
      }

      // Преобразуем в номер гексаграммы (1-64)
      hexagramNumber = binaryValue + 1;

      print(
        'Не найдена гексаграмма по бинарному представлению, вычисляю номер: $hexagramNumber (двоичное: $binaryValue)',
      );

      // Ищем информацию по номеру (на всякий случай)
      final hexagramInfoByNumber = _findHexagramByNumber(hexagramNumber);

      if (hexagramInfoByNumber != null && hexagramInfoByNumber.isNotEmpty) {
        print(
          'Найдена гексаграмма по номеру: ${hexagramInfoByNumber['number']} (${hexagramInfoByNumber['name']})',
        );
        return Hexagram(
          lines: lines,
          number: hexagramInfoByNumber['number'],
          name: hexagramInfoByNumber['name'],
          description: hexagramInfoByNumber['description'],
        );
      }

      // Если всё равно не нашли, используем временные данные
      print(
        'Не найдена гексаграмма ни по бинарному представлению, ни по номеру. Использую временные данные.',
      );
      return Hexagram(
        lines: lines,
        number: hexagramNumber,
        name: '第$hexagramNumber卦', // Временное имя: "Гексаграмма номер X"
        description:
            '此卦基于您的六次投币生成。', // "Эта гексаграмма создана на основе ваших шести бросков монет"
      );
    }
  }

  // Список данных о гексаграммах из JSON-файла
  List<Map<String, dynamic>> _hexagramsData = [];

  // Загружаем данные о гексаграммах из JSON-файла
  Future<void> _loadHexagramsData() async {
    if (_hexagramsData.isNotEmpty) return; // Если данные уже загружены, выходим

    try {
      // Загружаем JSON-файл из assets
      final jsonString = await rootBundle.loadString(
        'assets/data/hexagrams.json',
      );
      // Парсим JSON и сохраняем данные о гексаграммах
      final List<dynamic> jsonData = jsonDecode(jsonString);
      _hexagramsData = jsonData.cast<Map<String, dynamic>>();
    } catch (e) {
      // В случае ошибки выводим сообщение и используем пустой список
      print('Ошибка загрузки данных о гексаграммах: $e');
      _hexagramsData = [];
    }
  }

  // Поиск информации о гексаграмме по номеру
  Map<String, dynamic>? _findHexagramByNumber(int number) {
    if (_hexagramsData.isEmpty) return null;

    try {
      return _hexagramsData.firstWhere(
        (hexagram) => hexagram['number'] == number,
        orElse: () => {},
      );
    } catch (e) {
      print('Ошибка поиска гексаграммы по номеру: $e');
      return null;
    }
  }

  // Поиск информации о гексаграмме по бинарному представлению
  Map<String, dynamic>? _findHexagramByBinary(String binary) {
    if (_hexagramsData.isEmpty) return null;

    try {
      return _hexagramsData.firstWhere(
        (hexagram) => hexagram['binary'] == binary,
        orElse: () => {},
      );
    } catch (e) {
      print('Ошибка поиска гексаграммы по бинарному представлению: $e');
      return null;
    }
  }

  void addBotMessage(String text, {bool enableStreaming = false}) {
    final newMessage = MessageEntity(
      text: text,
      isMe: false,
      timestamp: DateTime.now(),
      isStreaming: enableStreaming,
    );

    final updatedMessages = List<MessageEntity>.from(state.messages)
      ..insert(0, newMessage);

    emit(state.copyWith(messages: updatedMessages, isLoading: false));

    // Если включен streaming, через некоторое время отключаем его
    if (enableStreaming) {
      Future.delayed(Duration(milliseconds: text.length * 30 + 500), () {
        if (state.messages.isNotEmpty &&
            state.messages[0].text == text &&
            state.messages[0].isStreaming) {
          final updatedStreamingMessages = List<MessageEntity>.from(
            state.messages,
          );
          updatedStreamingMessages[0] = updatedStreamingMessages[0].copyWith(
            isStreaming: false,
          );
          emit(state.copyWith(messages: updatedStreamingMessages));
        }
      });
    }
  }

  void setLoading(bool loading) {
    emit(state.copyWith(isLoading: loading));
  }

  void clearMessages() {
    emit(
      state.copyWith(
        messages: const [],
        currentInput: '',
        isSendAvailable: false,
        isButtonAvailable: false,
        isLoading: false,
        loadingMessageIndex: -1,
        currentQuestionContext: const [], // Очищаем контекст текущего вопроса
      ),
    );
  }

  void startNewQuestion() {
    // Очищаем контекст текущего вопроса и контекст последнего гадания
    emit(
      state.copyWith(
        currentQuestionContext: const [],
        isButtonAvailable: false,
      ),
    );
  }

  @override
  ChatState? fromJson(Map<String, dynamic> json) => ChatState.fromJson(json);

  @override
  Map<String, dynamic>? toJson(ChatState state) => state.toJson();

  @override
  Future<void> clear() async {
    debugPrint('==== Полная очистка состояния ChatCubit ====');

    // Сбрасываем состояние на начальное
    emit(const ChatState());

    // Вызываем очистку в родительском классе
    await super.clear();

    // Обновляем статус подписки после очистки
    await _updateSubscriptionStatus();

    debugPrint('==== Состояние сброшено до начального ====');
  }
}
