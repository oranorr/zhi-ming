import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zhi_ming/features/iching/widgets/hexagram_widget.dart';

/// [HexagramSection] Виджет для отображения секции с гексаграммами
class HexagramSection extends StatelessWidget {
  const HexagramSection({required this.hexagrams, super.key});

  final List<dynamic> hexagrams;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Отображение гексаграмм в ряд или в столбец в зависимости от количества
        if (hexagrams.length == 1)
          // Одна гексаграмма - просто размещаем по центру
          _buildSingleHexagram(context)
        else
          // Две гексаграммы - размещаем рядом
          _buildDoubleHexagrams(context),
      ],
    );
  }

  /// [HexagramSection] Виджет для отображения одной гексаграммы
  Widget _buildSingleHexagram(BuildContext context) {
    return Column(
      children: [
        Center(
          child: HexagramWidget(
            hexagram: hexagrams[0],
            width: 120.w,
            lineHeight: 16.h,
            title: 'Ваша гексаграмма',
          ),
        ),
        if (hexagrams[0].interpretation != null) ...[
          SizedBox(height: 16.h),
          hexagrams[0].buildInterpretation(context),
        ],
      ],
    );
  }

  /// [HexagramSection] Виджет для отображения двух гексаграмм
  Widget _buildDoubleHexagrams(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: HexagramWidget(
                hexagram: hexagrams[0],
                width: 100.w,
                lineHeight: 12.h,
                title: 'Исходная',
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: HexagramWidget(
                hexagram: hexagrams[1],
                width: 100.w,
                lineHeight: 12.h,
                title: 'Изменяющаяся',
              ),
            ),
          ],
        ),
        if (hexagrams[0].interpretation != null) ...[
          SizedBox(height: 16.h),
          hexagrams[0].buildInterpretation(context),
        ],
      ],
    );
  }
}
