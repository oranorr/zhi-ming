// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zhi_ming/core/extensions/build_context_extension.dart';
import 'package:zhi_ming/core/theme/theme_colors.dart';
import 'package:zhi_ming/features/adapty/domain/models/subscription_product.dart';

/// Виджет карточки плана подписки с адаптивным дизайном
///
/// **Apple HIG дизайн принципы:**
/// - Плавные анимации при выборе плана
/// - Хэптик фидбек для всех взаимодействий
/// - Четкая визуальная иерархия с выделением важных элементов
/// - Использование системных иконок и паттернов
/// - Accessibility и читаемость текста
///
/// **🎯 АДАПТИВНЫЕ УЛУЧШЕНИЯ:**
/// - Компактные размеры для экономии места
/// - Адаптивные отступы и размеры
/// - Оптимизированная типографика
class PlanCard extends StatelessWidget {
  const PlanCard({
    required this.product,
    required this.isSelected,
    required this.onTap,
    required this.needsBottomPadding,
    required this.isDisabled,
    required this.hasDiscount,
    required this.isCompact,
    required this.index,
    super.key,
  });

  /// Продукт подписки для отображения
  final SubscriptionProduct product;

  /// Выбран ли этот план
  final bool isSelected;

  /// Callback при нажатии на карточку
  final VoidCallback onTap;

  /// Нужен ли отступ снизу (для последнего элемента)
  final bool needsBottomPadding;

  /// Заблокирована ли карточка
  final bool isDisabled;

  /// Есть ли скидка на план
  final bool hasDiscount;

  /// Компактный режим отображения
  final bool isCompact;

  /// Индекс карточки в списке
  final int index;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: needsBottomPadding ? 0 : 17.h,
        // bottom: !needsBottomPadding ? (isCompact ? 12.h : 16.h) : 0,
      ),
      child: InkWell(
        onTap:
            isDisabled
                ? null
                : () {
                  // Хэптик фидбек при выборе плана
                  HapticFeedback.selectionClick();
                  onTap();
                },
        borderRadius: BorderRadius.circular(
          isCompact ? 16.r : 20.r,
        ), // Компактные углы
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDisabled ? Colors.grey.shade100 : Colors.white,
            borderRadius: BorderRadius.circular(
              isCompact ? 16.r : 20.r,
            ), // Компактные углы
            border:
                isSelected
                    ? Border.all(color: const Color(0xFF6B73FF), width: 2)
                    : null,
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: const Color(0xFF6B73FF).withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : null,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Основное содержимое с адаптивными отступами
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 12.w : 16.w,
                  vertical: isCompact ? 8.h : 12.h,
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: isCompact ? 20.w : 24.w,
                      height: isCompact ? 20.h : 24.h,
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? const Color(0xFF6B73FF)
                                : Colors.transparent,
                        border: Border.all(
                          color:
                              isSelected
                                  ? const Color(0xFF6B73FF)
                                  : (isDisabled
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade300),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(
                          isCompact ? 4.r : 6.r,
                        ),
                      ),
                      child:
                          isSelected
                              ? Icon(
                                Icons.check,
                                color: Colors.white,
                                size: isCompact ? 12 : 16,
                              )
                              : null,
                    ),
                    SizedBox(width: isCompact ? 12.w : 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(product.title, style: context.styles.mMedium),
                          SizedBox(
                            height: isCompact ? 2.h : 4.h,
                          ), // Компактный отступ
                          Text(
                            product.description,
                            style: context.styles.sDemilight,
                          ),
                        ],
                      ),
                    ),

                    // Цена - без изменений
                    Row(
                      children: [
                        if (hasDiscount &&
                            product.originalPrice != null &&
                            index != 1) ...[
                          Text(
                            product.originalPrice!,
                            style: context.styles.mMedium.copyWith(
                              color: ZColors.grayDark,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          SizedBox(width: 4.w),
                        ],
                        Text(product.price, style: context.styles.mMedium),
                      ],
                    ),
                  ],
                ),
              ),

              // Кнопка скидки - адаптивная позиция
              if (hasDiscount)
                Positioned(
                  left: index == 0 ? 143.w : 135.w,
                  top: -13.h,
                  child: Container(
                    // width: 48.w,
                    height: 26.h,
                    decoration: BoxDecoration(
                      color:
                          index == 0
                              ? const Color(0xFF6B73FF)
                              : ZColors.yellowMiddle,
                      borderRadius: BorderRadius.circular(
                        20.r,
                      ), // Компактные углы
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 2.h,
                      ),
                      child: Center(
                        child: Text(
                          index == 0 ? '折扣' : '试用3天',
                          style: context.styles.sDemilight.copyWith(
                            color: index == 0 ? Colors.white : ZColors.black,
                            height: 1.h,
                            fontSize:
                                isCompact ? 11.sp : null, // Компактный шрифт
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
