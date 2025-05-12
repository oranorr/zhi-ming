import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:zhi_ming/features/chat/domain/message_entity.dart';

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
  });
  factory ChatState.fromJson(Map<String, dynamic> json) =>
      _$ChatStateFromJson(json);
  final bool isButtonAvailable;
  final bool isSendAvailable;
  final bool isLoading;
  final List<MessageEntity> messages;
  final String currentInput;
  final int loadingMessageIndex; // Индекс сообщения с индикатором загрузки

  ChatState copyWith({
    bool? isButtonAvailable,
    bool? isSendAvailable,
    bool? isLoading,
    List<MessageEntity>? messages,
    String? currentInput,
    int? loadingMessageIndex,
  }) {
    return ChatState(
      isButtonAvailable: isButtonAvailable ?? this.isButtonAvailable,
      isSendAvailable: isSendAvailable ?? this.isSendAvailable,
      isLoading: isLoading ?? this.isLoading,
      messages: messages ?? this.messages,
      currentInput: currentInput ?? this.currentInput,
      loadingMessageIndex: loadingMessageIndex ?? this.loadingMessageIndex,
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
  ];
}

class ChatCubit extends HydratedCubit<ChatState> {
  ChatCubit() : super(const ChatState());

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
      text: state.currentInput,
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

    // Имитируем процесс загрузки
    simulateLoadingAndShowButton();
  }

  Future<void> simulateLoadingAndShowButton() async {
    // Создаем пустое сообщение от бота, которое будет показывать индикатор загрузки
    final loadingMessage = MessageEntity(
      text: '', // Текст будет пустым, так как мы показываем только индикатор
      isMe: false,
      timestamp: DateTime.now(),
    );

    // Добавляем сообщение с индикатором загрузки
    final updatedMessages = List<MessageEntity>.from(state.messages)
      ..insert(0, loadingMessage);

    // Устанавливаем состояние загрузки и сохраняем индекс сообщения с загрузкой
    emit(
      state.copyWith(
        messages: updatedMessages,
        isLoading: true,
        loadingMessageIndex: 0, // Индекс первого сообщения в списке
      ),
    );

    // Задержка для имитации загрузки
    await Future.delayed(const Duration(seconds: 2));

    // Явно скрываем клавиатуру перед показом кнопки
    SystemChannels.textInput.invokeMethod('TextInput.hide');

    // После задержки не удаляем сообщение, а заменяем его на новое с инструкцией
    // и показываем кнопку "бросить монету"
    final promptMessage = MessageEntity(
      text: '很好，现在请专注你的问题，摇动手机六次进行投币。',
      isMe: false,
      timestamp: DateTime.now(),
    );

    final messagesWithInstruction = List<MessageEntity>.from(state.messages);
    if (state.loadingMessageIndex >= 0 &&
        state.loadingMessageIndex < messagesWithInstruction.length) {
      // Заменяем сообщение с загрузкой на сообщение с инструкцией
      messagesWithInstruction[state.loadingMessageIndex] = promptMessage;
    }

    emit(
      state.copyWith(
        messages: messagesWithInstruction,
        isButtonAvailable: true,
        isLoading: false,
        loadingMessageIndex: -1, // Сбрасываем индекс
      ),
    );
  }

  void processAfterShaking() {
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
    Future.delayed(const Duration(seconds: 2), () {
      // Обновляем сообщение с индикатором загрузки вместо добавления нового
      final successMessage = MessageEntity(
        text: 'Поздравляю, ты потряс телефон!',
        isMe: false,
        timestamp: DateTime.now(),
      );

      final updatedMessages = List<MessageEntity>.from(state.messages);
      if (state.loadingMessageIndex >= 0 &&
          state.loadingMessageIndex < updatedMessages.length) {
        // Заменяем сообщение с загрузкой на сообщение с успехом
        updatedMessages[state.loadingMessageIndex] = successMessage;
      }

      emit(
        state.copyWith(
          messages: updatedMessages,
          isLoading: false,
          loadingMessageIndex: -1, // Сбрасываем индекс
        ),
      );

      // Для возможного продолжения диалога можно добавить дополнительное сообщение
      Future.delayed(const Duration(seconds: 1), () {
        addBotMessage(
          'Вы можете задать еще один вопрос или продолжить беседу.',
        );
      });
    });
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
}
