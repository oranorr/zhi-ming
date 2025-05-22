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
      ],
    );
  }
}
