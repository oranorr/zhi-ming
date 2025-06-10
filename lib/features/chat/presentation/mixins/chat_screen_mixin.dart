import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zhi_ming/core/services/shake_service/shake_service_impl.dart';
import 'package:zhi_ming/features/adapty/presentation/paywall.dart';
import 'package:zhi_ming/features/chat/domain/chat_entrypoint_entity.dart';
import 'package:zhi_ming/features/chat/domain/message_entity.dart';
import 'package:zhi_ming/features/chat/presentation/chat_cubit.dart';
import 'package:zhi_ming/features/home/presentation/home_screen.dart';
import 'package:zhi_ming/features/iching/widgets/iching_shake_popup.dart';

/// [ChatScreenMixin] Миксин с бизнес-логикой для ChatScreen
mixin ChatScreenMixin<T extends StatefulWidget> on State<T> {
  late ChatCubit cubit;
  // Создаем FocusNode для управления фокусом и клавиатурой
  final FocusNode focusNode = FocusNode();
  // Создаем ScrollController для отслеживания прокрутки
  final ScrollController scrollController = ScrollController();

  /// Entrypoint для чата (должен быть переопределен в виджете)
  ChatEntrypointEntity get entrypoint;

  @override
  void initState() {
    super.initState();
    cubit = context.read<ChatCubit>();

    // Сбрасываем кнопку при инициализации
    cubit.toggleButton(false);

    // Добавляем слушатель прокрутки для закрытия клавиатуры
    scrollController.addListener(onScroll);

    // Инициализация зависит от типа entrypoint
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initializeChat();
    });
  }

  @override
  void dispose() {
    // Освобождаем ScrollController при уничтожении экрана
    scrollController.removeListener(onScroll);
    scrollController.dispose();

    // Освобождаем FocusNode при уничтожении экрана
    focusNode.dispose();
    super.dispose();
  }

  /// [ChatScreenMixin] Инициализация чата в зависимости от типа entrypoint
  void initializeChat() {
    if (entrypoint is HistoryEntrypointEntity) {
      // Режим истории - загружаем сообщения из истории
      loadHistoryMessages();
    } else {
      // Обычный режим - показываем начальное сообщение от бота
      cubit.showInitialMessage(entrypoint);

      // [ChatScreen] Для Ба-Дзы с существующими сообщениями прокручиваем к низу
      if (entrypoint is BaDzyEntrypointEntity) {
        // Небольшая задержка, чтобы дать время на загрузку сообщений
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && cubit.state.messages.length > 1) {
            scrollToBottom(animated: false);
          }
        });
      }

      // Проверяем наличие предварительно заданного вопроса
      final predefinedQuestion = entrypoint.predefinedQuestion;
      if (predefinedQuestion != null && predefinedQuestion.isNotEmpty) {
        // Устанавливаем предварительно заданный вопрос в поле ввода
        cubit.updateInput(predefinedQuestion);
        // Отправляем сообщение
        cubit.sendMessage();
      }
    }
  }

  /// [ChatScreenMixin] Загружает сообщения из истории чата
  void loadHistoryMessages() {
    debugPrint('[ChatScreen] Загружаем сообщения из истории');

    final historyEntrypoint = entrypoint as HistoryEntrypointEntity;
    final messages = historyEntrypoint.chatHistory.messages;

    // Очищаем текущие сообщения перед загрузкой истории
    cubit.clearMessages();

    // Загружаем сообщения из истории в правильном порядке
    // Сообщения в истории хранятся в правильном хронологическом порядке
    messages.forEach(addHistoryMessage);

    debugPrint(
      '[ChatScreen] Загружено ${messages.length} сообщений из истории',
    );
  }

  /// [ChatScreenMixin] Добавляет историческое сообщение в cubit
  void addHistoryMessage(MessageEntity message) {
    // Создаем копию сообщения без streaming для режима только чтения
    final readOnlyMessage = MessageEntity(
      text: message.text,
      isMe: message.isMe,
      timestamp: message.timestamp,
      hexagrams: message.hexagrams,
      simpleInterpretation: message.simpleInterpretation,
      complexInterpretation: message.complexInterpretation,
    );

    // Добавляем сообщение в состояние через метод cubit
    // Используем внутренний метод для прямого добавления без обработки
    final updatedMessages = List<MessageEntity>.from(cubit.state.messages)
      ..insert(0, readOnlyMessage);

    cubit.emit(cubit.state.copyWith(messages: updatedMessages));
  }

  /// [ChatScreenMixin] Метод для отслеживания прокрутки и закрытия клавиатуры
  void onScroll() {
    // Если пользователь прокрутил вниз
    if (scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      hideKeyboard();
    }
  }

  /// [ChatScreenMixin] Метод для надежного скрытия клавиатуры
  void hideKeyboard() {
    // Несколько способов скрыть клавиатуру для большей надежности
    focusNode.unfocus();
    FocusScope.of(context).unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    // Явно вызываем метод скрытия клавиатуры через системный канал
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  /// [ChatScreenMixin] Метод для плавной прокрутки к началу списка (последнему сообщению)
  void scrollToBottom({bool animated = true}) {
    print('[ChatScreenMixin] scrollToBottom вызван, animated: $animated');

    if (scrollController.hasClients) {
      print('[ChatScreenMixin] ScrollController имеет клиентов');
      print(
        '[ChatScreenMixin] Текущая позиция: ${scrollController.position.pixels}',
      );
      print(
        '[ChatScreenMixin] Максимальная позиция: ${scrollController.position.maxScrollExtent}',
      );

      // [ChatScreen] Проверяем валидность позиции прокрутки
      final maxExtent = scrollController.position.maxScrollExtent;
      if (maxExtent <= 0) {
        print(
          '[ChatScreenMixin] Максимальная позиция <= 0, прокрутка пропущена',
        );
        return;
      }

      if (animated) {
        scrollController.animateTo(
          maxExtent, // Прокручиваем к концу списка (последнее сообщение)
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      } else {
        scrollController.jumpTo(maxExtent);
      }
    } else {
      print('[ChatScreenMixin] ScrollController НЕ имеет клиентов');
    }
  }

  /// [ChatScreenMixin] Метод для обработки отправки сообщения с UX улучшениями
  void handleSendMessage() {
    print('[ChatScreenMixin] Отправка сообщения пользователем');

    // Скрываем клавиатуру перед отправкой
    hideKeyboard();

    // Отправляем сообщение
    cubit.sendMessage();

    // Прокручиваем к отправленному сообщению с небольшой задержкой
    // чтобы дать время на обновление UI и показать пользователю его сообщение
    Future.delayed(const Duration(milliseconds: 150), () {
      print('[ChatScreenMixin] Прокрутка к отправленному сообщению');
      scrollToBottom();
    });
  }

  /// [ChatScreenMixin] Обработка нажатия кнопки назад
  Future<void> handleBackPressed() async {
    // Скрываем клавиатуру
    hideKeyboard();

    // Даем немного времени для закрытия клавиатуры
    await Future.delayed(const Duration(milliseconds: 100));

    // В режиме истории не очищаем состояние cubit
    if (!entrypoint.isReadOnlyMode) {
      // Полностью очищаем состояние кубита только в обычном режиме
      await cubit.clear();
    }

    if (entrypoint is OnboardingEntrypointEntity) {
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }

    // Возвращаемся на предыдущий экран
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  /// [ChatScreenMixin] Обработка очистки чата Ба-Дзы в режиме дебага
  Future<void> handleClearBaDzyChat() async {
    debugPrint('[ChatScreen] Очистка чата Ба-Дзы в режиме дебага');

    // Показываем диалог подтверждения
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Очистить чат Ба-Дзы?'),
            content: const Text(
              'Это действие удалит всю историю чата и вернет к начальному сообщению.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Очистить'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await cubit.clearBaDzyChat();
    }
  }

  /// [ChatScreenMixin] Обработка нажатия кнопки встряхивания
  Future<void> handleShakeButtonPressed() async {
    // [ChatScreen] Проверяем возможность начать новое гадание
    final canStart = await cubit.checkCanStartNewReading();
    if (!canStart) {
      return; // Не показываем popup если нельзя начать новое гадание
    }

    // [ChatScreen] Скрываем кнопку сразу при начале ритуала
    cubit.toggleButton(false);

    // Создаем один экземпляр сервиса для использования в обоих местах
    final shakerService = ShakerServiceImpl();

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) {
        return IChingShakePopup(
          shakeService: shakerService,
          onLineGenerated: (lineValue) {
            // Если все 6 линий уже получены (всего нужно 6 бросков монет)
            // каждый бросок состоит из 3 монет, но нам нужны только итоговые линии
            if (shakerService.currentShakeCount >= 6) {
              // Обрабатываем сгенерированную линию и передаем сервис
              cubit.processAfterShaking(shakerService);
            }
          },
          currentLine: 1,
          totalLines: 6,
        );
      },
    ).then((_) {
      // [ChatScreen] Если диалог закрыт, но ритуал не завершен,
      // проверяем нужно ли показать кнопку обратно
      if (shakerService.currentShakeCount < 6 &&
          !cubit.state.hasHexagramContext) {
        cubit.toggleButton(true);
      }
    });
  }

  /// [ChatScreenMixin] Обработка состояний блока
  void handleBlocListener(BuildContext context, state) {
    // [ChatScreenMixin] Убираем автоматическую прокрутку при получении сообщений от агента
    // Оставляем только прокрутку при отправке пользовательских сообщений
    // для лучшего UX согласно Apple Guidelines

    // [ChatScreen] Автоматическая прокрутка для Ба-Дзы при загрузке существующих сообщений
    if (entrypoint is BaDzyEntrypointEntity &&
        state.messages.isNotEmpty &&
        !state.isLoading) {
      // Проверяем, что это не начальное состояние (только приветственное сообщение)
      final hasConversation =
          state.messages.length > 1 ||
          (state.messages.length == 1 && state.messages.first.isMe);

      if (hasConversation) {
        // Небольшая задержка для рендеринга UI
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && scrollController.hasClients) {
            scrollToBottom(animated: false);
          }
        });
      }
    }

    // Слушаем флаг навигации на paywall
    if (state.shouldNavigateToPaywall) {
      // Сбрасываем флаг
      cubit.resetPaywallNavigation();

      // Переходим на paywall
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const Paywall()),
        (route) => false,
      );
    }
  }
}
