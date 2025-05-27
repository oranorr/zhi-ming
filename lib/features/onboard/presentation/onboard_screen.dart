import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zhi_ming/core/extensions/build_context_extension.dart';
import 'package:zhi_ming/core/widgets/z_button.dart';
import 'package:zhi_ming/core/widgets/z_scaffold.dart';
import 'package:zhi_ming/features/chat/presentation/chat_screen.dart';
import 'package:zhi_ming/features/chat/presentation/input_send.dart';
import 'package:zhi_ming/features/onboard/data/onboard_repo.dart';
import 'package:zhi_ming/features/onboard/domain/onboard_state.dart';
import 'package:zhi_ming/features/onboard/presentation/onboard_cubit.dart';
import 'package:zhi_ming/features/onboard/presentation/onboard_mixin.dart';
import 'package:zhi_ming/features/onboard/presentation/z_date_picker.dart';
import 'package:zhi_ming/features/onboard/presentation/z_time_picker.dart';

class OnboardScreen extends StatefulWidget {
  const OnboardScreen({super.key});

  @override
  State<OnboardScreen> createState() => _OnboardScreenState();
}

class _OnboardScreenState extends State<OnboardScreen> with OnboardMixin {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OnboardCubit, OnboardState>(
      listener: (context, state) {
        // Слушатель событий от cubit
      },
      builder: (context, state) {
        return ZScaffold(
          isHome: false,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                SizedBox(height: 35.h),

                // Заголовок с дедом
                _buildHeader(),

                // Основной контент
                Expanded(
                  child: GestureDetector(
                    onTap: hideKeyboard,
                    child: _buildMainContent(state),
                  ),
                ),

                SizedBox(height: 20.h),

                // Виджет ввода сообщения (если нужен)
                _buildInputWidget(state),
              ],
            ),
          ),
        );
      },
    );
  }

  // Метод для построения заголовка с дедом
  Widget _buildHeader() {
    if (analysisResult != null) {
      return SizedBox(height: 35.h);
    }

    if (isLoading) {
      // При загрузке показываем большого деда с сообщением "думаю"
      return Column(
        children: [
          Image.asset(
            'assets/ded.png',
            width: 200.w,
            height: 200.h,
            fit: BoxFit.cover,
          ),
          SizedBox(height: 8.h),
          const _DedMessage(message: '思考中...'), // "Думаю..."
        ],
      );
    }

    if (birthdateSelected && !boolShowTimePicker) {
      // Горизонтальное расположение (маленький дед + сообщение)
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        child: Row(
          children: [
            Image.asset(
              'assets/ded.png',
              width: 40.w,
              height: 40.h,
              fit: BoxFit.cover,
            ),
            SizedBox(width: 16.w),
            Expanded(child: _DedMessage(message: dedMessage)),
          ],
        ),
      );
    } else {
      // Вертикальное расположение (большой дед, затем сообщение)
      return Column(
        children: [
          Image.asset(
            'assets/ded.png',
            width: 200.w,
            height: 200.h,
            fit: BoxFit.cover,
          ),
          SizedBox(height: 8.h),
          _DedMessage(message: dedMessage),
        ],
      );
    }
  }

  // Метод для построения основного контента
  Widget _buildMainContent(OnboardState state) {
    if (isLoading) {
      return Center(
        child: SizedBox.square(
          dimension: 100.r,
          child: const CircularProgressIndicator(
            color: Color(0xFF7C7CFF),
            strokeWidth: 5,
          ),
        ),
      );
    }

    if (birthdateSelected) {
      // Если анализ уже готов, показываем результат
      if (analysisResult != null) {
        return MessageWidget(
          isMe: false,
          text: analysisResult!.text,
          isLoading: false,
        );
      }

      // Если время рождения выбрано, показываем селектор интересов
      if (birthtimeSelected) {
        return _InterestsSelector(
          interests: OnboardRepo.interests,
          selectedInterests: selectedInterests,
          onInterestSelected: onInterestSelected,
          onSave: saveInterests,
        );
      }
    }

    if (boolShowTimePicker) {
      return _TimePickerWidget(
        selectedTime: selectedTime,
        onTimeChanged: onTimeChanged,
        onSave: saveBirthTime,
        onSkip: skipBirthTime,
      );
    }

    if (boolShowDatePicker) {
      return _DatePickerWidget(
        selectedDate: selectedDate,
        onDateChanged: onDateChanged,
        onSave: saveBirthDate,
      );
    }

    if (userMessage != null) {
      return Column(
        children: [
          // Пустое пространство для смещения сообщения вниз
          const Spacer(),
          // Сообщение пользователя
          MessageWidget(isMe: true, text: userMessage!.text, isLoading: false),
          // Небольшой отступ внизу
          SizedBox(height: 20.h),
        ],
      );
    }

    return Container();
  }

  // Метод для построения виджета ввода
  Widget _buildInputWidget(OnboardState state) {
    // Если у нас есть результат анализа, показываем две кнопки
    if (analysisResult != null) {
      return Row(
        children: [
          // Кнопка перехода на домашний экран
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: Zbutton(
                action: navigateToChat,
                isLoading: false,
                isActive: true,
                text: '继续占卜', // "Продолжить гадание"
                color: const Color(0xFF7C7CFF),
                textColor: Colors.white,
              ),
            ),
          ),

          // Кнопка перехода в чат
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 8.w),
              child: Zbutton(
                action: navigateToHome,
                isLoading: false,
                isActive: true,
                text: '稍后再试', // "Попробовать позже"
                color: const Color(0xffD38DEC),
                textColor: Colors.white,
              ),
            ),
          ),
        ],
      );
    }

    // Стандартная логика отображения поля ввода
    if (!boolShowDatePicker &&
        !boolShowTimePicker &&
        !birthdateSelected &&
        !isLoading) {
      return InputSendWidget(
        onSend: sendMessage,
        onTextChanged: (text) => cubit.updateInput(text),
        isSendAvailable: state.currentInput.trim().isNotEmpty,
        currentInput: state.currentInput,
        focusNode: focusNode,
      );
    }

    return const SizedBox.shrink(); // Пустой виджет, если ввод не нужен
  }
}

// Виджет сообщения от деда
class _DedMessage extends StatelessWidget {
  const _DedMessage({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: context.styles.mRegular.copyWith(height: 1.4),
      textAlign: TextAlign.center,
    );
  }
}

// Виджет выбора даты
class _DatePickerWidget extends StatelessWidget {
  const _DatePickerWidget({
    required this.selectedDate,
    required this.onDateChanged,
    required this.onSave,
  });

  final DateTime selectedDate;
  final Function(DateTime) onDateChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(),
        ZDatePicker(onDateChanged: onDateChanged, initialDate: selectedDate),
        const Spacer(),
        Zbutton(
          action: onSave,
          isLoading: false,
          isActive: true,
          text: '保存',
          color: const Color(0xFF7C7CFF),
          textColor: Colors.white,
        ),
      ],
    );
  }
}

// Виджет выбора времени
class _TimePickerWidget extends StatelessWidget {
  const _TimePickerWidget({
    required this.selectedTime,
    required this.onTimeChanged,
    required this.onSave,
    required this.onSkip,
  });

  final TimeOfDay selectedTime;
  final Function(TimeOfDay) onTimeChanged;
  final VoidCallback onSave;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(),
        ZTimePicker(onTimeChanged: onTimeChanged, initialTime: selectedTime),
        const Spacer(),
        Zbutton(
          action: onSave,
          isLoading: false,
          isActive: true,
          text: '保存',
          color: const Color(0xFF7C7CFF),
          textColor: Colors.white,
        ),
        SizedBox(height: 16.h),
        TextButton(
          onPressed: onSkip,
          child: Text('跳过', style: context.styles.lRegular.copyWith()),
        ),
      ],
    );
  }
}

// Виджет выбора интересов
class _InterestsSelector extends StatelessWidget {
  const _InterestsSelector({
    required this.interests,
    required this.selectedInterests,
    required this.onInterestSelected,
    required this.onSave,
  });

  final List<Interest> interests;
  final List<Interest> selectedInterests;
  final Function(Interest, bool) onInterestSelected;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SizedBox.expand(
            child: Wrap(
              spacing: 12.w,
              runSpacing: 10.h,
              children: [
                for (final interest in interests)
                  InterestChip(
                    interest: interest,
                    isSelected: selectedInterests.contains(interest),
                    onSelectionChanged: onInterestSelected,
                    key: ValueKey(interest.name),
                  ),
              ],
            ),
          ),
        ),
        SizedBox(height: 20.h),
        Zbutton(
          action: onSave,
          isLoading: false,
          isActive: true,
          text: '选择',
          color: const Color(0xFF7C7CFF),
          textColor: Colors.white,
        ),
      ],
    );
  }
}
