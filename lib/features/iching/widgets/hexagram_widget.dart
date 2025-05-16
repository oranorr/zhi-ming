import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zhi_ming/core/extensions/build_context_extension.dart';
import 'package:zhi_ming/features/iching/models/hexagram.dart';
import 'package:zhi_ming/features/iching/widgets/hexagram_line.dart';

class HexagramWidget extends StatelessWidget {
  const HexagramWidget({
    required this.hexagram,
    super.key,
    this.width = 80,
    this.lineHeight = 12,
    this.lineSpacing = 8,
    this.color = Colors.black,
    this.title,
  });
  final Hexagram hexagram;
  final double width;
  final double lineHeight;
  final double lineSpacing;
  final Color color;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок гексаграммы (если есть)
        // if (title != null)
        //   Padding(
        //     padding: const EdgeInsets.only(bottom: 16),
        //     child: Text(
        //       title!,
        //       style: TextStyle(
        //         fontSize: 18,
        //         fontWeight: FontWeight.bold,
        //         color: color,
        //       ),
        //       textAlign: TextAlign.center,
        //     ),
        //   ),

        // Номер гексаграммы и имя
        // if (hexagram.number != null || hexagram.name != null)
        //   Padding(
        //     padding: const EdgeInsets.only(bottom: 8),
        //     child: Text(
        //       [
        //         if (hexagram.number != null) '№${hexagram.number}',
        //         if (hexagram.name != null) hexagram.name!,
        //       ].join(' '),
        //       style: TextStyle(
        //         fontSize: 16,
        //         fontWeight: FontWeight.bold,
        //         color: color,
        //       ),
        //       textAlign: TextAlign.center,
        //     ),
        //   ),

        // Линии гексаграммы (снизу вверх)
        ...List.generate(
          6,
          (index) => Padding(
            padding: EdgeInsets.only(bottom: index < 6 ? lineSpacing : 0),
            // padding: EdgeInsets.only(bottom: index < 5 ? lineSpacing : 0),
            child: HexagramLineWidget(
              line:
                  hexagram.lines[5 -
                      index], // Переворачиваем для отображения снизу вверх
              width: width,
              height: lineHeight,
              color: color,
            ),
          ),
        ).reversed, // Отображаем снизу вверх
        // SizedBox(height: 5.h),
        // buildText('所得卦象:', context, isBold: true),
        // buildText(theTitle, context),
        // SizedBox(height: 10.h),
        // buildText('核心含义:', context, isBold: true),
        // buildText(
        //   'здесь очень длинный текст описания, который может быть очень длинным и сложным для понимания',
        //   context,
        // ),

        // Описание гексаграммы (если есть)
        // if (hexagram.description != null)
        //   Padding(
        //     padding: const EdgeInsets.only(top: 16),
        //     child: Text(
        //       hexagram.description!,
        //       style: TextStyle(fontSize: 14, color: color.withOpacity(0.8)),
        //       textAlign: TextAlign.center,
        //     ),
        //   ),
      ],
    );
  }
}
