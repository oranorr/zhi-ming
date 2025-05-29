import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:zhi_ming/core/extensions/build_context_extension.dart';
import 'package:zhi_ming/core/services/shake_service/shake_service_impl.dart';
import 'package:zhi_ming/core/theme/theme_colors.dart';
import 'package:zhi_ming/core/widgets/z_button.dart';
import 'package:zhi_ming/core/widgets/z_scaffold.dart';
import 'package:zhi_ming/features/adapty/presentation/paywall.dart';
import 'package:zhi_ming/features/chat/domain/chat_entrypoint_entity.dart';
import 'package:zhi_ming/features/chat/domain/message_entity.dart';
import 'package:zhi_ming/features/chat/presentation/chat_cubit.dart';
import 'package:zhi_ming/features/chat/presentation/models/chat_state.dart';
import 'package:zhi_ming/features/chat/presentation/input_send.dart';
import 'package:zhi_ming/features/home/presentation/home_page.dart';
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
                            final isLoading =
                                state.isLoading &&
                                index == state.messages.length - 1 &&
                                !message.isMe;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: MessageWidget(
                                isMe: message.isMe,
                                isLoading: isLoading,
                                text: message.text,
                                hexagrams: message.hexagrams,
                                message: message,
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
                                  !state.hasHexagramContext) {
                                cubit.toggleButton(true);
                              }
                            });
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

class MessageWidget extends StatefulWidget {
  const MessageWidget({
    required this.isMe,
    required this.text,
    required this.isLoading,
    this.hexagrams,
    this.message, // Передаем весь объект сообщения для доступа к интерпретациям
    super.key,
  });

  final bool isMe;
  final String text;
  final bool isLoading;
  final List<dynamic>? hexagrams;
  final MessageEntity? message; // Полный объект сообщения

  @override
  State<MessageWidget> createState() => _MessageWidgetState();
}

class _MessageWidgetState extends State<MessageWidget>
    with TickerProviderStateMixin {
  String _displayedText = '';
  int _currentIndex = 0;
  Timer? _streamingTimer;

  @override
  void initState() {
    super.initState();
    // Если сообщение в режиме streaming и это не пользователь
    if (widget.message?.isStreaming == true &&
        !widget.isMe &&
        widget.text.isNotEmpty) {
      _startStreaming();
    } else {
      _displayedText = widget.text;
    }
  }

  @override
  void didUpdateWidget(MessageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Если streaming завершился, показываем полный текст
    if (oldWidget.message?.isStreaming == true &&
        widget.message?.isStreaming == false) {
      _stopStreaming();
      setState(() {
        _displayedText = widget.text;
      });
    }
    // Если текст изменился (например, заменили loading сообщение на сообщение с текстом)
    else if (oldWidget.text != widget.text) {
      // Если новое сообщение не в режиме streaming, просто обновляем текст
      if (widget.message?.isStreaming != true) {
        setState(() {
          _displayedText = widget.text;
        });
      } else {
        // Если новое сообщение в режиме streaming, запускаем анимацию
        _stopStreaming(); // Останавливаем предыдущий streaming, если был
        _currentIndex = 0;
        _displayedText = '';
        _startStreaming();
      }
    }
  }

  @override
  void dispose() {
    _stopStreaming();
    super.dispose();
  }

  void _startStreaming() {
    if (widget.text.isEmpty) return;

    _streamingTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (_currentIndex < widget.text.length) {
        setState(() {
          _currentIndex++;
          _displayedText = widget.text.substring(0, _currentIndex);
        });
      } else {
        _stopStreaming();
      }
    });
  }

  void _stopStreaming() {
    _streamingTimer?.cancel();
    _streamingTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    // log(widget.message.toString());

    if (widget.isMe) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: BoxConstraints(maxWidth: 260.w),
          decoration: BoxDecoration(
            color: ZColors.yellowLight,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          child: Text(
            _displayedText,
            style: context.styles.mDemilight,
            softWrap: true,
          ),
        ),
      );
    } else {
      // [MessageWidget] Определяем, короткое ли сообщение для центрирования по вертикали
      final isShortMessage =
          widget.text.isNotEmpty &&
          widget.text.length < 50 &&
          widget.hexagrams == null &&
          widget.message?.simpleInterpretation == null &&
          widget.message?.complexInterpretation == null;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: Row(
          crossAxisAlignment:
              widget.isLoading
                  ? CrossAxisAlignment.center
                  : isShortMessage
                  ? CrossAxisAlignment
                      .center // Центрируем короткие сообщения
                  : CrossAxisAlignment
                      .start, // Оставляем длинные сообщения сверху
          children: [
            SizedBox.square(
              dimension: 40.w,
              child: Image.asset('assets/ded.png'),
            ),
            SizedBox(width: widget.isLoading ? 16.w : 0),
            if (widget.isLoading)
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
                  decoration: const BoxDecoration(),
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    // mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (widget.hexagrams != null &&
                          widget.hexagrams!.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 16.h),
                          child: _buildHexagramsSection(context),
                        ),

                      // Отображение структурированной интерпретации или обычного текста
                      if (widget.message?.simpleInterpretation != null)
                        _buildSimpleInterpretation(
                          widget.message!.simpleInterpretation!,
                        )
                      else if (widget.message?.complexInterpretation != null)
                        _buildComplexInterpretation(
                          widget.message!.complexInterpretation!,
                        )
                      else if (widget.text.isNotEmpty)
                        // Новый вариант с поддержкой streaming
                        _buildStreamingText(_displayedText),

                      // Отображаем гексаграммы, если они есть
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    }
  }

  /// Виджет для отображения текста с эффектом streaming
  Widget _buildStreamingText(String text) {
    return Text(text, style: context.styles.mDemilight);
  }

  /// Виджет для простой интерпретации (одна гексаграмма)
  Widget _buildSimpleInterpretation(SimpleInterpretation interpretation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Основной ответ
        _buildSectionTitle('回答'), //ответ
        _buildText(interpretation.answer),

        SizedBox(height: 16.h),

        // Краткая сводка
        _buildSectionTitle('简要总结'), //краткая сводка
        // Позитивные аспекты
        _buildSubSectionTitle('潜在机会'), //потенциальные возможности
        _buildText(interpretation.interpretationSummary.potentialPositive),

        SizedBox(height: 8.h),

        // Негативные аспекты
        _buildSubSectionTitle('潜在挑战'), //потенциальные вызовы
        _buildText(interpretation.interpretationSummary.potentialNegative),

        SizedBox(height: 8.h),

        // Ключевые советы
        _buildSubSectionTitle('关键建议'), //ключевые советы
        ...interpretation.interpretationSummary.keyAdvice.map(
          (advice) => _buildBulletPoint(advice),
        ),

        SizedBox(height: 16.h),

        // Детальная интерпретация
        _buildSectionTitle('详细解释'), //детальная интерпретация
        _buildText(interpretation.detailedInterpretation),
      ],
    );
  }

  /// Виджет для сложной интерпретации (две гексаграммы)
  Widget _buildComplexInterpretation(ComplexInterpretation interpretation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Основной ответ
        _buildSectionTitle('回答'), //ответ
        _buildText(interpretation.answer),

        SizedBox(height: 16.h),

        // Интерпретация первичной гексаграммы
        _buildSectionTitle('初始情况'), //исходная ситуация
        _buildHexagramInterpretation(interpretation.interpretationPrimary),

        SizedBox(height: 16.h),

        // Интерпретация вторичной гексаграммы
        _buildSectionTitle('事态发展'), //развитие ситуации
        _buildHexagramInterpretation(interpretation.interpretationSecondary),

        SizedBox(height: 16.h),

        // Интерпретация изменяющихся линий
        _buildSectionTitle('换线'), //изменяющиеся линии
        _buildText(interpretation.interpretationChangingLines),

        SizedBox(height: 16.h),

        // Общее руководство
        _buildSectionTitle('总体指导'), //общее руководство
        _buildText(interpretation.overallGuidance),
      ],
    );
  }

  /// Виджет для интерпретации отдельной гексаграммы
  Widget _buildHexagramInterpretation(HexagramInterpretation interpretation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Позитивные аспекты
        _buildSubSectionTitle('潜在机会'), //потенциальные возможности
        _buildText(interpretation.summary.potentialPositive),

        SizedBox(height: 8.h),

        // Негативные аспекты
        _buildSubSectionTitle('潜在挑战'), //потенциальные вызовы
        _buildText(interpretation.summary.potentialNegative),

        SizedBox(height: 8.h),

        // Ключевые советы
        _buildSubSectionTitle('关键建议'), //ключевые советы
        ...interpretation.summary.keyAdvice.map(
          (advice) => _buildBulletPoint(advice),
        ),

        SizedBox(height: 12.h),

        // Детали
        _buildSubSectionTitle('详细解释'), //подробности
        _buildText(interpretation.details),
      ],
    );
  }

  /// Заголовок секции
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        title,
        style: context.styles.mDemilight.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  /// Подзаголовок
  Widget _buildSubSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Text(title, style: context.styles.mRegular),
    );
  }

  /// Обычный текст
  Widget _buildText(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(text, style: context.styles.mDemilight, softWrap: true),
    );
  }

  /// Маркированный список
  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h, left: 16.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: context.styles.mDemilight.copyWith(
              color: ZColors.purpleLight,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(text, style: context.styles.mDemilight, softWrap: true),
          ),
        ],
      ),
    );
  }

  Widget buildText(String text, BuildContext context, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: isBold ? context.styles.mRegular : context.styles.sDemilight,
      ),
    );
  }

  Widget _buildHexagramsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Отображение гексаграмм в ряд или в столбец в зависимости от количества
        if (widget.hexagrams!.length == 1)
          // Одна гексаграмма - просто размещаем по центру
          Column(
            children: [
              Center(
                child: HexagramWidget(
                  hexagram: widget.hexagrams![0],
                  width: 120.w,
                  lineHeight: 16.h,
                  title: 'Ваша гексаграмма',
                ),
              ),
              if (widget.hexagrams![0].interpretation != null) ...[
                SizedBox(height: 16.h),
                widget.hexagrams![0].buildInterpretation(context),
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
                      hexagram: widget.hexagrams![0],
                      width: 100.w,
                      lineHeight: 12.h,
                      title: 'Исходная',
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: HexagramWidget(
                      hexagram: widget.hexagrams![1],
                      width: 100.w,
                      lineHeight: 12.h,
                      title: 'Изменяющаяся',
                    ),
                  ),
                ],
              ),
              if (widget.hexagrams![0].interpretation != null) ...[
                SizedBox(height: 16.h),
                widget.hexagrams![0].buildInterpretation(context),
              ],
            ],
          ),
      ],
    );
  }
}
