import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhi_ming/core/services/deepseek/deepseek_service.dart';
import 'package:zhi_ming/features/chat/domain/chat_entrypoint_entity.dart';
import 'package:zhi_ming/features/chat/domain/message_entity.dart';
import 'package:zhi_ming/features/chat/presentation/chat_screen.dart';
import 'package:zhi_ming/features/home/presentation/home_page.dart';
import 'package:zhi_ming/features/onboard/data/onboard_repo.dart';
import 'package:zhi_ming/features/onboard/presentation/onboard_cubit.dart';
import 'dart:convert';

/// Миксин для управления состоянием экрана онбординга
mixin OnboardMixin<T extends StatefulWidget> on State<T> {
  // Константа для ключа в SharedPreferences
  static const String _onboardingCompletedKey = 'onboarding_completed';

  // Кубит для управления состоянием
  late OnboardCubit cubit;

  // Сервис для работы с DeepSeek API
  late DeepSeekService _deepSeekService;

  // Контроллеры
  final FocusNode focusNode = FocusNode();
  final ScrollController scrollController = ScrollController();

  // Состояние для сообщений и имени пользователя
  String userName = '';
  String dedMessage = '嗨！怎么称呼你呀？'; // Начальное сообщение от деда
  MessageEntity? userMessage;
  bool boolShowDatePicker = false;
  DateTime selectedDate = DateTime(1990);
  bool birthdateSelected =
      false; // Флаг для отслеживания, выбрана ли уже дата рождения

  // Состояние для выбора времени рождения
  bool boolShowTimePicker = false;
  TimeOfDay selectedTime = const TimeOfDay(hour: 12, minute: 0);
  bool birthtimeSelected =
      false; // Флаг для отслеживания, выбрано ли время рождения

  // Состояние для интересов
  final List<Interest> selectedInterests = [];

  // Состояние загрузки
  bool isLoading = false;

  // Результат анализа от DeepSeek
  MessageEntity? analysisResult;

  // Второе сообщение от агента
  MessageEntity? secondMessage;

  @override
  void initState() {
    super.initState();
    cubit = context.read<OnboardCubit>();
    _deepSeekService = DeepSeekService();

    // Проверяем статус онбординга при инициализации
    _checkOnboardingStatus();
  }

  /// Проверяет, был ли пройден онбординг, и перенаправляет пользователя, если да
  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingCompleted = prefs.getBool(_onboardingCompletedKey) ?? false;

    if (onboardingCompleted && mounted) {
      // Если онбординг был пройден, переходим на домашний экран
      // Используем прямой Navigator.pushReplacement чтобы избежать повторного сохранения статуса
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    }
  }

  /// Сохраняет статус завершения онбординга
  Future<void> _saveOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompletedKey, true);
  }

  @override
  void dispose() {
    scrollController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  /// Метод для скрытия клавиатуры
  void hideKeyboard() {
    focusNode.unfocus();
    FocusScope.of(context).unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  /// Метод для отправки сообщения
  void sendMessage() {
    if (cubit.state.currentInput.trim().isEmpty) return;

    final newMessage = MessageEntity(
      text: cubit.state.currentInput.trim(),
      isMe: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      userMessage = newMessage;
      userName = newMessage.text;
    });

    // Очищаем поле ввода
    cubit.updateInput('');

    // Добавляем задержку перед изменением сообщения деда
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          // Меняем сообщение деда после получения имени
          dedMessage = '很高兴认识你，$userName。为了更准确地解读，我需要你的出生日期。请填写吧。';
          // Скрываем сообщение пользователя и показываем датапикер
          boolShowDatePicker = true;
        });
      }
    });
  }

  /// Метод для сохранения выбранной даты
  void saveBirthDate() {
    // Сохраняем дату в кубит, но переходим к выбору времени
    cubit.emit(cubit.state.copyWith(birthDate: selectedDate));

    // Меняем состояние экрана: скрываем датапикер и показываем выбор времени
    setState(() {
      boolShowDatePicker = false;
      boolShowTimePicker = true;
      dedMessage =
          '很好！现在请选择你的出生时间。'; // "Отлично! Теперь выберите время рождения."
      userMessage = null; // Очищаем сообщение пользователя
      birthdateSelected = true; // Устанавливаем флаг, что дата рождения выбрана
    });
  }

  /// Обработчик изменения выбранной даты
  void onDateChanged(DateTime date) {
    setState(() {
      selectedDate = date;
    });
  }

  /// Метод для сохранения выбранного времени
  void saveBirthTime() {
    // Сохраняем время в кубит
    cubit.emit(cubit.state.copyWith(birthTime: selectedTime));

    // Меняем состояние экрана: скрываем выбор времени и переходим к интересам
    setState(() {
      boolShowTimePicker = false;
      dedMessage =
          '谢谢！那你现在最关心的是什么呢？'; // "Спасибо! Что вас сейчас больше всего интересует?"
      userMessage = null; // Очищаем сообщение пользователя
      birthtimeSelected =
          true; // Устанавливаем флаг, что время рождения выбрано
    });
  }

  /// Метод для пропуска выбора времени рождения
  void skipBirthTime() {
    // Не сохраняем время в кубит, переходим к интересам
    setState(() {
      boolShowTimePicker = false;
      dedMessage =
          '谢谢！那你现在最关心的是什么呢？'; // "Спасибо! Что вас сейчас больше всего интересует?"
      userMessage = null; // Очищаем сообщение пользователя
      birthtimeSelected =
          true; // Устанавливаем флаг, что время рождения выбрано (пропущено)
    });
  }

  /// Обработчик изменения выбранного времени
  void onTimeChanged(TimeOfDay time) {
    setState(() {
      selectedTime = time;
    });
  }

  /// Обработчик выбора интересов
  void onInterestSelected(Interest interest, bool isSelected) {
    setState(() {
      if (isSelected && !selectedInterests.contains(interest)) {
        selectedInterests.add(interest);
      } else if (!isSelected && selectedInterests.contains(interest)) {
        selectedInterests.remove(interest);
      }
    });
  }

  /// Метод для сохранения выбранных интересов
  Future<void> saveInterests() async {
    // Показываем индикатор загрузки
    setState(() {
      isLoading = true;
    });

    try {
      // Формируем данные пользователя для отправки в DeepSeek
      final Map<String, dynamic> userData = {
        'name': userName,
        'birthdate':
            '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
        'interests':
            selectedInterests.map((interest) => interest.name).toList(),
      };

      // Добавляем время рождения только если оно было выбрано (не пропущено)
      if (cubit.state.birthTime != null) {
        userData['birthtime'] =
            '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
      }

      // Отправляем данные в DeepSeek для анализа
      final response = await _deepSeekService.sendMessage(
        agentType: AgentType.onboarding,
        message: jsonEncode(userData),
      );

      // Создаем сообщение с результатом анализа
      final resultMessage = MessageEntity(
        text: response,
        isMe: false,
        timestamp: DateTime.now(),
      );

      // Обновляем состояние
      if (mounted) {
        setState(() {
          isLoading = false;
          analysisResult = resultMessage;
          dedMessage =
              '分析已完成！这是你的个性描述。'; // "Анализ завершен! Вот описание вашей личности."

          // Сразу добавляем второе сообщение без задержек
          secondMessage = MessageEntity(
            text: '这只是一个大致的概念。你想尝试易经占卜，以便对具体问题得到答案吗？',
            isMe: false,
            timestamp: DateTime.now(),
          );
        });
      }
    } catch (e) {
      // В случае ошибки выводим сообщение и продолжаем
      print('[saveInterests] Ошибка при анализе данных: $e');

      if (mounted) {
        setState(() {
          isLoading = false;
          dedMessage =
              '对不起，分析过程中出现了问题。'; // "Извините, возникла проблема при анализе."
          // Даже при ошибке создаем пустое сообщение, чтобы показать кнопки
          analysisResult = MessageEntity(
            text: 'Не удалось получить анализ личности.',
            isMe: false,
            timestamp: DateTime.now(),
          );

          // Сразу добавляем второе сообщение без задержки
          secondMessage = MessageEntity(
            text: '这只是一个大致的概念。你想尝试易经占卜，以便对具体问题得到答案吗？',
            isMe: false,
            timestamp: DateTime.now(),
          );
        });
      }
    }
  }

  /// Метод для перехода на домашний экран
  Future<void> navigateToHome() async {
    // Сохраняем статус завершения онбординга перед переходом
    await _saveOnboardingCompleted();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    }
  }

  /// Метод для перехода на экран чата
  Future<void> navigateToChat() async {
    // Сохраняем статус завершения онбординга перед переходом
    await _saveOnboardingCompleted();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) => ChatScreen(entrypoint: OnboardingEntrypointEntity()),
        ),
      );
    }
  }
}
