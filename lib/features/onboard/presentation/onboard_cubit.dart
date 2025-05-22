import 'package:flutter/services.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:intl/intl.dart';
import 'package:zhi_ming/features/chat/domain/message_entity.dart';
import 'package:zhi_ming/features/onboard/domain/onboard_questions.dart';
import 'package:zhi_ming/features/onboard/domain/onboard_state.dart';

class OnboardCubit extends HydratedCubit<OnboardState> {
  OnboardCubit() : super(const OnboardState());

  @override
  OnboardState? fromJson(Map<String, dynamic> json) {
    try {
      return OnboardState.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  @override
  Map<String, dynamic>? toJson(OnboardState state) {
    return null;
  }

  Future<void> showInitialMessage() async {
    if (state.messages.isNotEmpty) return;

    // Показываем индикатор загрузки
    emit(state.copyWith(isLoading: true));

    // Отправляем начальное сообщение
    final initialBotMessage = MessageEntity(
      text: '你好，流浪者',
      isMe: false,
      timestamp: DateTime.now(),
    );

    final updatedMessages = List<MessageEntity>.from(state.messages)
      ..insert(0, initialBotMessage);

    emit(state.copyWith(messages: updatedMessages, isLoading: false));

    // Задержка перед первым вопросом
    await Future.delayed(const Duration(milliseconds: 1500));

    // Показываем первый вопрос
    await _showNextQuestion();

    // После первого вопроса, отправляем сразу и второй
    if (OnboardQuestions.questions.length > 1) {
      emit(state.copyWith(currentQuestionIndex: 1));
      await _showNextQuestion();
    }
  }

  void updateInput(String text) {
    emit(state.copyWith(currentInput: text));
  }

  Future<void> sendMessage() async {
    if (state.currentInput.trim().isEmpty) return;

    final newMessage = MessageEntity(
      text: state.currentInput,
      isMe: true,
      timestamp: DateTime.now(),
    );

    final updatedMessages = List<MessageEntity>.from(state.messages)
      ..insert(0, newMessage);

    emit(state.copyWith(messages: updatedMessages, currentInput: ''));

    // После ответа пользователя проверяем, нужно ли показать следующий вопрос
    // или открыть дейт-пикер
    await _processAfterUserAnswer();
  }

  Future<void> _processAfterUserAnswer() async {
    final nextQuestionIndex = state.currentQuestionIndex + 1;

    // Если пользователь ответил на три вопроса, показываем сообщение о дате рождения
    if (nextQuestionIndex >= OnboardQuestions.questions.length) {
      await _showDatePickerPrompt();
    } else {
      // Иначе показываем следующий вопрос
      emit(state.copyWith(currentQuestionIndex: nextQuestionIndex));
      await _showNextQuestion();
    }
  }

  Future<void> _showNextQuestion() async {
    // Показываем индикатор загрузки
    emit(state.copyWith(isLoading: true));

    // Задержка перед отправкой следующего сообщения
    await Future.delayed(const Duration(milliseconds: 1500));

    // Проверяем, что индекс вопроса не выходит за пределы массива
    if (state.currentQuestionIndex >= OnboardQuestions.questions.length) {
      emit(state.copyWith(isLoading: false));
      return;
    }

    final question = OnboardQuestions.questions[state.currentQuestionIndex];

    final botMessage = MessageEntity(
      text: question.text,
      isMe: false,
      timestamp: DateTime.now(),
    );

    final updatedMessages = List<MessageEntity>.from(state.messages)
      ..insert(0, botMessage);

    emit(state.copyWith(messages: updatedMessages, isLoading: false));
  }

  Future<void> _showDatePickerPrompt() async {
    // Показываем индикатор загрузки
    emit(state.copyWith(isLoading: true));

    // Задержка перед отправкой сообщения
    await Future.delayed(const Duration(milliseconds: 1500));

    final botMessage = MessageEntity(
      text: '现在，请向我敞开命运之门——你降临此世的时刻。你的出生日期是？',
      isMe: false,
      timestamp: DateTime.now(),
    );

    final updatedMessages = List<MessageEntity>.from(state.messages)
      ..insert(0, botMessage);

    emit(
      state.copyWith(
        messages: updatedMessages,
        isDatePickerVisible: true,
        isLoading: false,
      ),
    );
  }

  void showDatePicker() {
    // Этот метод вызывается при нажатии кнопки
    // В UI компоненте будет показан DatePicker
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  Future<void> selectBirthDate(DateTime date) async {
    // Показываем индикатор загрузки
    emit(state.copyWith(isLoading: true));

    // Форматируем дату для отображения
    final formattedDate = DateFormat('dd.MM.yyyy').format(date);

    // Добавляем сообщение с выбранной датой
    final userMessage = MessageEntity(
      text: formattedDate,
      isMe: true,
      timestamp: DateTime.now(),
    );

    final updatedMessages = List<MessageEntity>.from(state.messages)
      ..insert(0, userMessage);

    emit(
      state.copyWith(
        messages: updatedMessages,
        birthDate: date,
        isDatePickerVisible: false,
        isLoading: true,
      ),
    );

    // Задержка перед отправкой заключительного сообщения
    await Future.delayed(const Duration(milliseconds: 1500));

    // Добавляем завершающее сообщение
    final botMessage = MessageEntity(
      text:
          'Спасибо! Ваш профиль настроен. Теперь вы можете использовать все возможности приложения.',
      isMe: false,
      timestamp: DateTime.now(),
    );

    updatedMessages.insert(0, botMessage);

    emit(
      state.copyWith(
        messages: updatedMessages,
        isLoading: false,
        isCompleted: true,
      ),
    );
  }

  void resetOnboarding() {
    emit(const OnboardState());
  }
}
