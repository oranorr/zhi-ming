import 'package:flutter/material.dart';

import 'package:zhi_ming/features/iching/models/hexagram.dart';

class HexagramLineWidget extends StatelessWidget {
  const HexagramLineWidget({
    required this.line,
    super.key,
    this.width = 80,
    this.height = 12,
    this.color = Colors.black,
  });
  final Line line;
  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Основа линии (сплошная или прерывистая)
          if (line.isYang)
            // Сплошная линия (ян)
            Container(width: width, height: height, color: color)
          else
            // Прерывистая линия (инь)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(width: width * 0.45, height: height, color: color),
                Container(width: width * 0.45, height: height, color: color),
              ],
            ),

          // Метка для изменяющейся линии
          // if (line.isChanging)
          //   Container(
          //     width: height * 1.5,
          //     height: height * 1.5,
          //     decoration: BoxDecoration(
          //       color: Colors.white,
          //       shape: BoxShape.circle,
          //       border: Border.all(color: color, width: 2),
          //     ),
          //     alignment: Alignment.center,
          //   ),
        ],
      ),
    );
  }
}
