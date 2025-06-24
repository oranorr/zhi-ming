// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:zhi_ming/core/extensions/build_context_extension.dart';
import 'package:zhi_ming/features/adapty/domain/models/subscription_product.dart';
import 'package:zhi_ming/features/adapty/presentation/widgets/plan_card.dart';

/// Виджет средней секции пейволла с преимуществами и планами
///
/// **Адаптивные принципы:**
/// - Используем Column для вертикального расположения
/// - Flexible height адаптируется под доступное пространство
/// - Компактные отступы для помещения всего контента
/// - Список планов с оптимизированными размерами
class PaywallMiddleSection extends StatelessWidget {
  const PaywallMiddleSection({
    required this.products,
    required this.selectedPlanIndex,
    required this.isPurchasing,
    required this.isRestoring,
    required this.onPlanSelected,
    super.key,
  });

  /// Список продуктов подписки
  final List<SubscriptionProduct> products;

  /// Индекс выбранного плана
  final int selectedPlanIndex;

  /// Состояние процесса покупки
  final bool isPurchasing;

  /// Состояние процесса восстановления
  final bool isRestoring;

  /// Callback при выборе плана
  final ValueChanged<int> onPlanSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.h), // Компактные отступы
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          /// Описание преимуществ VIP
          Text('要继续并了解更多：', style: context.styles.mRegular),
          SizedBox(height: 8.h), // Уменьшено с 10.h
          /// **Построение списка преимуществ VIP - КОМПАКТНАЯ ВЕРСИЯ**
          ///
          /// **Адаптивные изменения:**
          /// - Уменьшены размеры иконок для экономии места
          /// - Компактные отступы между элементами
          /// - Оптимизированная типографика
          ..._buildAdvantages(),
          SizedBox(height: 20.h), // Уменьшено с 32.h
          /// **КЛЮЧЕВОЕ ИЗМЕНЕНИЕ АРХИТЕКТУРЫ:**
          /// Больше нет проверки isLoading!
          /// Продукты отображаются мгновенно из кэша
          if (products.isEmpty)
            Text(
              '暂无可用套餐',
              style: context.styles.mRegular.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            )
          else
            /// **Построение списка планов подписки - КОМПАКТНАЯ ВЕРСИЯ**
            ///
            /// **Адаптивные изменения:**
            /// - Уменьшены отступы между планами
            /// - Компактная высота карточек
            /// - Оптимизированная типографика
            ..._buildPlans(),
        ],
      ),
    );
  }

  /// **Построение списка преимуществ VIP - КОМПАКТНАЯ ВЕРСИЯ**
  ///
  /// **Адаптивные изменения:**
  /// - Уменьшены размеры иконок для экономии места
  /// - Компактные отступы между элементами
  /// - Оптимизированная типографика
  List<Widget> _buildAdvantages() {
    List<String> texts = ['无限占卜', '无限的澄清和问题', '保存所有牌局在历史记录中'];
    return texts
        .map(
          (e) => Builder(
            builder:
                (context) => Padding(
                  padding: EdgeInsets.only(bottom: 6.h), // Компактные отступы
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        'assets/crown.svg',
                        width: 14.w, // Уменьшено с 16.w
                        height: 14.h, // Уменьшено с 16.h
                      ),
                      SizedBox(width: 10.w), // Уменьшено с 12.w
                      Expanded(
                        child: Text(e, style: context.styles.mDemilight),
                      ),
                    ],
                  ),
                ),
          ),
        )
        .toList();
  }

  /// **Построение списка планов подписки - КОМПАКТНАЯ ВЕРСИЯ**
  ///
  /// **Адаптивные изменения:**
  /// - Уменьшены отступы между планами
  /// - Компактная высота карточек
  /// - Оптимизированная типографика
  List<Widget> _buildPlans() {
    return products
        .asMap()
        .entries
        .map(
          (entry) => PlanCard(
            index: entry.key,
            product: entry.value,
            isSelected: selectedPlanIndex == entry.key,
            onTap: () => onPlanSelected(entry.key),
            needsBottomPadding: entry.key == products.length - 1,
            isDisabled: isPurchasing || isRestoring,
            hasDiscount: entry.value.isRecommended,
            isCompact: true, // Новый параметр для компактного отображения
          ),
        )
        .toList();
  }
}
