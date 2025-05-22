import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:zhi_ming/core/services/deepseek/deepseek_service.dart';
import 'package:zhi_ming/core/services/deepseek/models/message.dart';
import 'package:zhi_ming/core/services/shake_service/shaker_service_repo.dart';
import 'package:zhi_ming/features/chat/domain/message_entity.dart';
import 'package:zhi_ming/features/iching/models/hexagram.dart';

part 'chat_cubit.g.dart';

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

  ChatState copyWith({
    bool? isButtonAvailable,
    bool? isSendAvailable,
    bool? isLoading,
    List<MessageEntity>? messages,
    String? currentInput,
    int? loadingMessageIndex,
    HexagramContext? lastHexagramContext,
  }) {
    return ChatState(
      isButtonAvailable: isButtonAvailable ?? this.isButtonAvailable,
      isSendAvailable: isSendAvailable ?? this.isSendAvailable,
      isLoading: isLoading ?? this.isLoading,
      messages: messages ?? this.messages,
      currentInput: currentInput ?? this.currentInput,
      loadingMessageIndex: loadingMessageIndex ?? this.loadingMessageIndex,
      lastHexagramContext: lastHexagramContext ?? this.lastHexagramContext,
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
  }

  late final DeepSeekService _deepSeekService;

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
      // Если есть контекст, обрабатываем как последующий вопрос
      handleFollowUpQuestion(state.messages[0].text);
    } else {
      // Если контекста нет, обрабатываем как новый запрос
      validateUserRequest(state.messages[0].text);
    }
  }

  Future<void> handleFollowUpQuestion(String question) async {
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

      // Обновляем сообщение с ответом
      final responseMessage = MessageEntity(
        text: response,
        isMe: false,
        timestamp: DateTime.now(),
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

  Future<void> validateUserRequest(String question) async {
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

    // Отправляем запрос на валидацию в DeepSeekService
    final validationResponse = await _deepSeekService.validateRequest(question);

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
        ),
      );
    } else if (validationResponse.status == 'invalid') {
      // Если запрос не валидный, показываем сообщение с причиной
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
        ),
      );
    }
  }

  void processAfterShaking(ShakerServiceRepo shakerService) {
    // Явно скрываем клавиатуру
    SystemChannels.textInput.invokeMethod('TextInput.hide');

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

      // Отправляем гексаграммы на интерпретацию
      final interpretation = await _deepSeekService.interpretHexagrams(
        question: userQuestion,
        primaryHexagram: originalHexagram,
        secondaryHexagram: changedHexagram,
      );

      print('Получена интерпретация:');
      print(interpretation);

      // Обновляем гексаграммы с интерпретацией
      final interpretedOriginalHexagram = originalHexagram.copyWith(
        interpretation: interpretation,
      );

      final interpretedChangedHexagram = changedHexagram?.copyWith(
        interpretation: interpretation,
      );

      print('Гексаграммы обновлены с интерпретацией');
      print('=== Конец обработки интерпретации ===');

      // Создаем сообщение с результатами гадания и интерпретацией
      final resultMessage = MessageEntity(
        text:
            '', // Теперь текст пустой, так как интерпретация будет в гексаграммах
        isMe: false,
        timestamp: DateTime.now(),
        hexagrams:
            interpretedChangedHexagram != null
                ? [interpretedOriginalHexagram, interpretedChangedHexagram]
                : [interpretedOriginalHexagram],
      );

      final updatedMessages = List<MessageEntity>.from(state.messages);
      if (state.loadingMessageIndex >= 0 &&
          state.loadingMessageIndex < updatedMessages.length) {
        // Заменяем сообщение с загрузкой на сообщение с гексаграммами и интерпретацией
        updatedMessages[state.loadingMessageIndex] = resultMessage;
      }

      // После получения интерпретации сохраняем контекст
      final hexagramContext = HexagramContext(
        originalQuestion: userQuestion,
        primaryHexagram: interpretedOriginalHexagram,
        secondaryHexagram: interpretedChangedHexagram,
        interpretation: interpretation,
      );

      // Обновляем состояние с сохранением контекста
      emit(
        state.copyWith(
          messages: updatedMessages,
          isLoading: false,
          loadingMessageIndex: -1,
          lastHexagramContext: hexagramContext, // Сохраняем контекст
        ),
      );

      // Сбрасываем результаты встряхиваний для следующего сеанса гадания
      shakerService.resetCoinThrows();

      // Добавляем пояснение через небольшую задержку
      Future.delayed(const Duration(seconds: 1), () {
        addBotMessage(
          'Вы можете задать еще один вопрос или продолжить беседу.',
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

  void addBotMessage(String text) {
    final newMessage = MessageEntity(
      text: text,
      isMe: false,
      timestamp: DateTime.now(),
    );

    final updatedMessages = List<MessageEntity>.from(state.messages)
      ..insert(0, newMessage);

    emit(state.copyWith(messages: updatedMessages, isLoading: false));
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

    // Сбрасываем состояние еще раз для надежности
    emit(const ChatState());

    debugPrint('==== Состояние сброшено до начального ====');
  }
}
