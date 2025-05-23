import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:zhi_ming/features/iching/models/hexagram.dart';

class HexagramLineWidget extends StatelessWidget {
  const HexagramLineWidget({
    required this.line,
    super.key,
    // this.width = 80,
    // this.height = 12,
    // this.color = Colors.black,
  });
  final Line line;
  // final Color color;

  @override
  Widget build(BuildContext context) {
    final double width = 110.w;
    final double height = 16.h;
    const LinearGradient gradient = LinearGradient(
      stops: [0.1, 0.9],
      colors: [Color(0xFfB4D5A4), Color(0xffC4F2B5)],
    );

    final decoration = BoxDecoration(
      gradient: gradient,
      borderRadius: const BorderRadius.all(Radius.circular(4)),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4),
      ],
    );
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Основа линии (сплошная или прерывистая)
          if (line.isYang)
            // Сплошная линия (ян)
            Container(width: width, height: height, decoration: decoration)
          else
            // Прерывистая линия (инь)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: width * 0.45,
                  height: height,
                  decoration: decoration,
                ),
                Container(
                  width: width * 0.45,
                  height: height,
                  decoration: decoration,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
