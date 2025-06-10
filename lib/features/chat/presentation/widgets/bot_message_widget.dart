import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zhi_ming/core/extensions/build_context_extension.dart';
import 'package:zhi_ming/core/theme/theme_colors.dart';
import 'package:zhi_ming/features/chat/domain/message_entity.dart';
import 'package:zhi_ming/features/chat/presentation/widgets/hexagram_section.dart';
import 'package:zhi_ming/features/chat/presentation/widgets/interpretation_widget.dart';

/// [BotMessageWidget] Виджет для отображения сообщений бота
class BotMessageWidget extends StatelessWidget {
  const BotMessageWidget({
    required this.text,
    required this.isLoading,
    this.hexagrams,
    this.message,
    super.key,
  });

  final String text;
  final bool isLoading;
  final List<dynamic>? hexagrams;
  final MessageEntity? message;

  @override
  Widget build(BuildContext context) {
    // [BotMessageWidget] Определяем, короткое ли сообщение для центрирования по вертикали
    final isShortMessage =
        text.isNotEmpty &&
        text.length < 50 &&
        hexagrams == null &&
        message?.simpleInterpretation == null &&
        message?.complexInterpretation == null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Row(
        crossAxisAlignment:
            isLoading
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
                decoration: const BoxDecoration(),
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Отображение гексаграмм, если они есть
                    if (hexagrams != null && hexagrams!.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 16.h),
                        child: HexagramSection(hexagrams: hexagrams!),
                      ),

                    // Отображение структурированной интерпретации или обычного текста
                    if (message?.simpleInterpretation != null)
                      InterpretationWidget.simple(
                        interpretation: message!.simpleInterpretation!,
                      )
                    else if (message?.complexInterpretation != null)
                      InterpretationWidget.complex(
                        interpretation: message!.complexInterpretation!,
                      )
                    else if (text.isNotEmpty)
                      _buildSimpleText(context),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// [BotMessageWidget] Виджет для отображения простого текста
  Widget _buildSimpleText(BuildContext context) {
    return Text(text, style: context.styles.mDemilight);
  }
}
