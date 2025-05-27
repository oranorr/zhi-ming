import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:zhi_ming/core/extensions/build_context_extension.dart';
import 'package:zhi_ming/core/services/shake_service/shake_service_impl.dart';
import 'package:zhi_ming/core/theme/theme_colors.dart';
import 'package:zhi_ming/core/widgets/z_button.dart';
import 'package:zhi_ming/core/widgets/z_scaffold.dart';
import 'package:zhi_ming/features/adapty/presentation/paywall.dart';
import 'package:zhi_ming/features/chat/domain/chat_entrypoint_entity.dart';
import 'package:zhi_ming/features/chat/presentation/chat_cubit.dart';
import 'package:zhi_ming/features/chat/presentation/input_send.dart';
import 'package:zhi_ming/features/home/presentation/home_page.dart';
import 'package:zhi_ming/features/home/presentation/home_screen.dart';
import 'package:zhi_ming/features/iching/widgets/hexagram_widget.dart';
import 'package:zhi_ming/features/iching/widgets/iching_shake_popup.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({required this.entrypoint, super.key});
  final ChatEntrypointEntity entrypoint;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late ChatCubit cubit;
  // Создаем FocusNode для управления фокусом и клавиатурой
  final FocusNode _focusNode = FocusNode();
  // Создаем ScrollController для отслеживания прокрутки
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    cubit = context.read<ChatCubit>();

    // Сбрасываем кнопку при инициализации
    cubit.toggleButton(false);

    // Добавляем слушатель прокрутки для закрытия клавиатуры
    _scrollController.addListener(_onScroll);

    // Показываем начальное сообщение от бота при открытии чата
    WidgetsBinding.instance.addPostFrameCallback((_) {
      cubit.showInitialMessage();

      // Проверяем наличие предварительно заданного вопроса
      final predefinedQuestion = widget.entrypoint.predefinedQuestion;
      if (predefinedQuestion != null && predefinedQuestion.isNotEmpty) {
        // Устанавливаем предварительно заданный вопрос в поле ввода
        cubit.updateInput(predefinedQuestion);

        // Отправляем сообщение
        cubit.sendMessage();
      }
    });
  }

  // Метод для отслеживания прокрутки и закрытия клавиатуры
  void _onScroll() {
    // Если пользователь прокрутил вниз
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      _hideKeyboard();
    }
  }

  @override
  void dispose() {
    // Освобождаем ScrollController при уничтожении экрана
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();

    // Освобождаем FocusNode при уничтожении экрана
    _focusNode.dispose();
    super.dispose();
  }

  // Метод для надежного скрытия клавиатуры
  void _hideKeyboard() {
    // Несколько способов скрыть клавиатуру для большей надежности
    _focusNode.unfocus();
    FocusScope.of(context).unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    // Явно вызываем метод скрытия клавиатуры через системный канал
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChatCubit, ChatState>(
      listener: (context, state) {
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
      },
      child: BlocBuilder<ChatCubit, ChatState>(
        builder: (context, state) {
          return WillPopScope(
            onWillPop: () async {
              // Скрываем клавиатуру
              _hideKeyboard();

              // Даем немного времени для закрытия клавиатуры
              await Future.delayed(const Duration(milliseconds: 100));

              // Полностью очищаем состояние кубита вместо просто очистки сообщений
              await cubit.clear();

              return mounted;
            },
            child: ZScaffold(
              isHome: false,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    SizedBox(height: 35.h),
                    GestureDetector(
                      onTap: () async {
                        // Скрываем клавиатуру
                        _hideKeyboard();

                        // Даем немного времени для закрытия клавиатуры
                        await Future.delayed(const Duration(milliseconds: 100));

                        // Полностью очищаем состояние кубита вместо просто очистки сообщений
                        await cubit.clear();

                        if (widget.entrypoint is OnboardingEntrypointEntity) {
                          await Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => const HomePage(),
                            ),
                          );
                        }

                        // Возвращаемся на предыдущий экран
                        if (mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: Row(
                        children: [
                          SvgPicture.asset('assets/arrow-left.svg'),
                          SizedBox(width: 8.w),
                          Text('首页', style: context.styles.h2),
                        ],
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        // Закрываем клавиатуру при тапе на список
                        onTap: _hideKeyboard,
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: state.messages.length,
                          itemBuilder: (context, index) {
                            final message =
                                state.messages[state.messages.length -
                                    1 -
                                    index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: MessageWidget(
                                isMe: message.isMe,
                                isLoading:
                                    state.isLoading &&
                                    index == state.messages.length - 1 &&
                                    !message.isMe,
                                text: message.text,
                                hexagrams: message.hexagrams,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    if (state.isButtonAvailable)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Zbutton(
                          action: () {
                            showDialog(
                              context: context,
                              barrierColor: Colors.black54,
                              builder: (context) {
                                // Создаем один экземпляр сервиса для использования в обоих местах
                                final shakerService = ShakerServiceImpl();
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
                            );
                          },
                          isLoading: false,
                          isActive: true,
                          text: '抛硬币',
                          textColor: ZColors.white,
                        ),
                      ),
                    InputSendWidget(
                      onSend: () => cubit.sendMessage(),
                      onTextChanged: (text) => cubit.updateInput(text),
                      isSendAvailable: state.isSendAvailable,
                      currentInput: state.currentInput,
                      focusNode:
                          _focusNode, // Передаем FocusNode в InputSendWidget
                    ),
                    SizedBox(height: 35.h),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class MessageWidget extends StatelessWidget {
  const MessageWidget({
    required this.isMe,
    required this.text,
    required this.isLoading,
    this.hexagrams,
    super.key,
  });
  final bool isMe;
  final String text;
  final bool isLoading;
  final List<dynamic>? hexagrams;

  @override
  Widget build(BuildContext context) {
    if (isMe) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: BoxConstraints(maxWidth: 260.w),
          decoration: BoxDecoration(
            color: ZColors.yellowLight,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          child: Text(text, style: context.styles.mDemilight, softWrap: true),
        ),
      );
    } else {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        // color: Colors.amber,
        child: Row(
          crossAxisAlignment:
              isLoading ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: [
            SizedBox.square(
              dimension: 40.w,
              child: Image.asset('assets/ded.png'),
            ),
            SizedBox(width: isLoading ? 16.w : 0),
            if (isLoading)
              SizedBox.square(
                dimension: 20.w,
                child: const CircularProgressIndicator(
                  color: ZColors.blueDark,
                  strokeWidth: 2,
                ),
              )
            else
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    // color: ZColors.black,
                    // borderRadius: BorderRadius.circular(20),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    // vertical: 12.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Текст сообщения - заменяем текст на MarkdownBody для поддержки форматирования
                      if (text.isNotEmpty)
                        MarkdownBody(
                          data: text,
                          styleSheet: MarkdownStyleSheet(
                            p: context.styles.mDemilight,
                            h1: context.styles.h1,
                            h2: context.styles.h2,
                            h3: context.styles.h3,
                            blockquote: context.styles.mRegular.copyWith(
                              fontStyle: FontStyle.italic,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            code: context.styles.mRegular.copyWith(
                              fontFamily: 'monospace',
                              backgroundColor: Colors.grey.shade200,
                            ),
                            codeblockDecoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          selectable: true,
                        ),

                      // Отображаем гексаграммы, если они есть
                      if (hexagrams != null && hexagrams!.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 16.h),
                          child: _buildHexagramsSection(context),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    }
  }

  Widget buildText(String text, BuildContext context, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: isBold ? context.styles.mRegular : context.styles.sDemilight,
        // textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildHexagramsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Отображение гексаграмм в ряд или в столбец в зависимости от количества
        if (hexagrams!.length == 1)
          // Одна гексаграмма - просто размещаем по центру
          Column(
            children: [
              Center(
                child: HexagramWidget(
                  hexagram: hexagrams![0],
                  width: 120.w,
                  lineHeight: 16.h,
                  title: 'Ваша гексаграмма',
                ),
              ),
              if (hexagrams![0].interpretation != null) ...[
                SizedBox(height: 16.h),
                hexagrams![0].buildInterpretation(context),
              ],
            ],
          )
        else
          // Две гексаграммы - размещаем рядом
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: HexagramWidget(
                      hexagram: hexagrams![0],
                      width: 100.w,
                      lineHeight: 12.h,
                      title: 'Исходная',
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: HexagramWidget(
                      hexagram: hexagrams![1],
                      width: 100.w,
                      lineHeight: 12.h,
                      title: 'Изменяющаяся',
                    ),
                  ),
                ],
              ),
              if (hexagrams![0].interpretation != null) ...[
                SizedBox(height: 16.h),
                hexagrams![0].buildInterpretation(context),
              ],
            ],
          ),
      ],
    );
  }
}
