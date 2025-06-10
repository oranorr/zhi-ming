import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zhi_ming/core/extensions/build_context_extension.dart';
import 'package:zhi_ming/core/theme/theme_colors.dart';
import 'package:zhi_ming/features/chat/domain/message_entity.dart';

/// [InterpretationWidget] Виджет для отображения интерпретаций И-Цзин
class InterpretationWidget extends StatelessWidget {
  const InterpretationWidget._({
    this.simpleInterpretation,
    this.complexInterpretation,
    super.key,
  });

  /// Конструктор для простой интерпретации (одна гексаграмма)
  const InterpretationWidget.simple({
    required SimpleInterpretation interpretation,
    Key? key,
  }) : this._(simpleInterpretation: interpretation, key: key);

  /// Конструктор для сложной интерпретации (две гексаграммы)
  const InterpretationWidget.complex({
    required ComplexInterpretation interpretation,
    Key? key,
  }) : this._(complexInterpretation: interpretation, key: key);

  final SimpleInterpretation? simpleInterpretation;
  final ComplexInterpretation? complexInterpretation;

  @override
  Widget build(BuildContext context) {
    if (simpleInterpretation != null) {
      return _buildSimpleInterpretation(context, simpleInterpretation!);
    } else if (complexInterpretation != null) {
      return _buildComplexInterpretation(context, complexInterpretation!);
    } else {
      return const SizedBox.shrink();
    }
  }

  /// [InterpretationWidget] Виджет для простой интерпретации (одна гексаграмма)
  Widget _buildSimpleInterpretation(
    BuildContext context,
    SimpleInterpretation interpretation,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Основной ответ
        _buildSectionTitle(context, '回答'), //ответ
        _buildText(context, interpretation.answer),

        SizedBox(height: 16.h),

        // Краткая сводка
        _buildSectionTitle(context, '简要总结'), //краткая сводка
        // Позитивные аспекты
        _buildSubSectionTitle(context, '潜在机会'), //потенциальные возможности
        _buildText(
          context,
          interpretation.interpretationSummary.potentialPositive,
        ),

        SizedBox(height: 8.h),

        // Негативные аспекты
        _buildSubSectionTitle(context, '潜在挑战'), //потенциальные вызовы
        _buildText(
          context,
          interpretation.interpretationSummary.potentialNegative,
        ),

        SizedBox(height: 8.h),

        // Ключевые советы
        _buildSubSectionTitle(context, '关键建议'), //ключевые советы
        ...interpretation.interpretationSummary.keyAdvice.map(
          (advice) => _buildBulletPoint(context, advice),
        ),

        SizedBox(height: 16.h),

        // Детальная интерпретация
        _buildSectionTitle(context, '详细解释'), //детальная интерпретация
        _buildText(context, interpretation.detailedInterpretation),
      ],
    );
  }

  /// [InterpretationWidget] Виджет для сложной интерпретации (две гексаграммы)
  Widget _buildComplexInterpretation(
    BuildContext context,
    ComplexInterpretation interpretation,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Основной ответ
        _buildSectionTitle(context, '回答'), //ответ
        _buildText(context, interpretation.answer),

        SizedBox(height: 16.h),

        // Интерпретация первичной гексаграммы
        _buildSectionTitle(context, '初始情况'), //исходная ситуация
        _buildHexagramInterpretation(
          context,
          interpretation.interpretationPrimary,
        ),

        SizedBox(height: 16.h),

        // Интерпретация вторичной гексаграммы
        _buildSectionTitle(context, '事态发展'), //развитие ситуации
        _buildHexagramInterpretation(
          context,
          interpretation.interpretationSecondary,
        ),

        SizedBox(height: 16.h),

        // Интерпретация изменяющихся линий
        _buildSectionTitle(context, '换线'), //изменяющиеся линии
        _buildText(context, interpretation.interpretationChangingLines),

        SizedBox(height: 16.h),

        // Общее руководство
        _buildSectionTitle(context, '总体指导'), //общее руководство
        _buildText(context, interpretation.overallGuidance),
      ],
    );
  }

  /// [InterpretationWidget] Виджет для интерпретации отдельной гексаграммы
  Widget _buildHexagramInterpretation(
    BuildContext context,
    HexagramInterpretation interpretation,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Позитивные аспекты
        _buildSubSectionTitle(context, '潜在机会'), //потенциальные возможности
        _buildText(context, interpretation.summary.potentialPositive),

        SizedBox(height: 8.h),

        // Негативные аспекты
        _buildSubSectionTitle(context, '潜在挑战'), //потенциальные вызовы
        _buildText(context, interpretation.summary.potentialNegative),

        SizedBox(height: 8.h),

        // Ключевые советы
        _buildSubSectionTitle(context, '关键建议'), //ключевые советы
        ...interpretation.summary.keyAdvice.map(
          (advice) => _buildBulletPoint(context, advice),
        ),

        SizedBox(height: 12.h),

        // Детали
        _buildSubSectionTitle(context, '详细解释'), //подробности
        _buildText(context, interpretation.details),
      ],
    );
  }

  /// [InterpretationWidget] Заголовок секции
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        title,
        style: context.styles.mDemilight.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  /// [InterpretationWidget] Подзаголовок
  Widget _buildSubSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Text(title, style: context.styles.mRegular),
    );
  }

  /// [InterpretationWidget] Обычный текст
  Widget _buildText(BuildContext context, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(text, style: context.styles.mDemilight, softWrap: true),
    );
  }

  /// [InterpretationWidget] Маркированный список
  Widget _buildBulletPoint(BuildContext context, String text) {
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
}
