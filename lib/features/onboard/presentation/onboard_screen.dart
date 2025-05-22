import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:zhi_ming/core/extensions/build_context_extension.dart';
import 'package:zhi_ming/core/theme/theme_colors.dart';
import 'package:zhi_ming/core/widgets/z_button.dart';
import 'package:zhi_ming/core/widgets/z_scaffold.dart';
import 'package:zhi_ming/features/chat/presentation/chat_screen.dart';
import 'package:zhi_ming/features/chat/presentation/input_send.dart';
import 'package:zhi_ming/features/home/presentation/home_page.dart';
import 'package:zhi_ming/features/onboard/domain/onboard_state.dart';
import 'package:zhi_ming/features/onboard/presentation/onboard_cubit.dart';
import 'package:zhi_ming/features/onboard/presentation/z_date_picker.dart';

class OnboardScreen extends StatefulWidget {
  const OnboardScreen({super.key});

  @override
  State<OnboardScreen> createState() => _OnboardScreenState();
}

class _OnboardScreenState extends State<OnboardScreen> {
  late OnboardCubit cubit;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    cubit = context.read<OnboardCubit>();

    // Добавляем слушатель прокрутки для закрытия клавиатуры
    _scrollController.addListener(_onScroll);

    // Показываем начальное сообщение
    WidgetsBinding.instance.addPostFrameCallback((_) {
      cubit.showInitialMessage();
    });
  }

  // Метод для отслеживания прокрутки и закрытия клавиатуры
  void _onScroll() {
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      _hideKeyboard();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // Метод для скрытия клавиатуры
  void _hideKeyboard() {
    _focusNode.unfocus();
    FocusScope.of(context).unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  Future<void> _showDatePicker(BuildContext context) async {
    _hideKeyboard();

    final DateTime? pickedDate = await showDialog<DateTime>(
      context: context,
      builder:
          (BuildContext context) => Dialog(
            insetPadding: EdgeInsets.symmetric(
              horizontal: 20.w,
              vertical: 24.h,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: const ZDatePicker(),
          ),
    );
    // showDatePicker(
    //   context: context,
    //   initialDate: DateTime(2000),
    //   firstDate: DateTime(1900),
    //   lastDate: DateTime.now(),
    //   builder: (BuildContext context, Widget? child) {
    //     return Theme(
    //       data: ThemeData.light().copyWith(
    //         colorScheme: const ColorScheme.light(
    //           primary: ZColors.purpleLight,
    //           onPrimary: ZColors.white,
    //           surface: ZColors.white,
    //           onSurface: ZColors.purpleLight,
    //         ),
    //         dialogTheme: const DialogThemeData(backgroundColor: ZColors.white),
    //       ),
    //       child: child!,
    //     );
    //   },
    // );

    if (pickedDate != null && mounted) {
      cubit.selectBirthDate(pickedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OnboardCubit, OnboardState>(
      listener: (context, state) {
        if (state.isCompleted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Перейти на главный экран после завершения
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          });
        }
      },
      builder: (context, state) {
        return ZScaffold(
          isHome: false,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                SizedBox(height: 35.h),
                Expanded(
                  child: GestureDetector(
                    onTap: _hideKeyboard,
                    child: ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      itemCount: state.messages.length,
                      itemBuilder: (context, index) {
                        final message = state.messages[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: MessageWidget(
                            isMe: message.isMe,
                            isLoading: false,
                            text: message.text,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                if (state.isDatePickerVisible)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Zbutton(
                      action: () async => _showDatePicker(context),
                      isLoading: false,
                      isActive: true,
                      text: '输入出生日期',
                      textColor: ZColors.white,
                    ),
                  ),
                InputSendWidget(
                  onSend: () => cubit.sendMessage(),
                  onTextChanged: (text) => cubit.updateInput(text),
                  isSendAvailable: state.currentInput.trim().isNotEmpty,
                  currentInput: state.currentInput,
                  focusNode: _focusNode,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
