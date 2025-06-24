// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zhi_ming/core/extensions/build_context_extension.dart';
import 'package:zhi_ming/core/widgets/z_button.dart';
import 'package:zhi_ming/features/adapty/domain/models/subscription_product.dart';

/// Виджет нижней секции пейволла с кнопками покупки
///
/// **Фиксированный дизайн:**
/// - Всегда внизу экрана
/// - Условия подписки компактно
/// - Кнопка восстановления покупок
/// - Основная кнопка покупки
/// - Адаптивные отступы снизу
class PaywallBottomSection extends StatelessWidget {
  const PaywallBottomSection({
    required this.products,
    required this.isPurchasing,
    required this.isRestoring,
    required this.onPurchase,
    required this.onRestore,
    super.key,
  });

  /// Список продуктов подписки
  final List<SubscriptionProduct> products;

  /// Состояние процесса покупки
  final bool isPurchasing;

  /// Состояние процесса восстановления
  final bool isRestoring;

  /// Callback для покупки
  final VoidCallback onPurchase;

  /// Callback для восстановления покупок
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        /// **Условия подписки с кликабельной ссылкой на Terms & Conditions**
        /// Используем RichText для создания кликабельной ссылки на условия
        /// https://zhiming.app/terms-and-conditions.html
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: context.styles.mDemilight.copyWith(
              color: Colors.black,
              height: 1.4, // Уменьшена с 1.5 для компактности
            ),
            children: [
              // Первая часть текста (обычный текст)
              const TextSpan(text: '自动续订，可随时取消。\n'),

              // Кликабельная ссылка на Terms & Conditions
              WidgetSpan(
                child: GestureDetector(
                  onTap: () async {
                    // Предотвращаем нажатие во время покупки/восстановления
                    if (isPurchasing || isRestoring) return;

                    // Открываем Terms & Conditions
                    await _openTermsAndConditions(context);
                  },
                  child: Text(
                    '条款',
                    style: context.styles.mDemilight.copyWith(
                      color:
                          isPurchasing || isRestoring
                              ? Colors.grey
                              : const Color(0xFF6B73FF), // Цвет ссылки
                      decoration: TextDecoration.underline,
                      decorationColor:
                          isPurchasing || isRestoring
                              ? Colors.grey
                              : const Color(0xFF6B73FF),
                      height: 1.4,
                    ),
                  ),
                ),
              ),

              // Разделитель между ссылками
              const TextSpan(text: ' 和 '),

              // Кликабельная ссылка на Privacy Policy
              WidgetSpan(
                child: GestureDetector(
                  onTap: () async {
                    // Предотвращаем нажатие во время покупки/восстановления
                    if (isPurchasing || isRestoring) return;

                    // Открываем Privacy Policy
                    await _openPrivacyPolicy(context);
                  },
                  child: Text(
                    '隐私政策',
                    style: context.styles.mDemilight.copyWith(
                      color:
                          isPurchasing || isRestoring
                              ? Colors.grey
                              : const Color(0xFF6B73FF), // Цвет ссылки
                      decoration: TextDecoration.underline,
                      decorationColor:
                          isPurchasing || isRestoring
                              ? Colors.grey
                              : const Color(0xFF6B73FF),
                      height: 1.4,
                    ),
                  ),
                ),
              ),

              // Последняя часть текста (обычный текст)
              const TextSpan(text: '。'),
            ],
          ),
        ),
        // SizedBox(height: 4.h), // Уменьшено с 6.h для более компактного вида
        /// **Кнопка восстановления покупок**
        GestureDetector(
          onTap: () async {
            if (isPurchasing || isRestoring) return;

            // Хэптик фидбек при нажатии
            HapticFeedback.lightImpact();

            onRestore();
          },
          child: Text(
            '恢复购买',
            style: context.styles.mRegular.copyWith(
              color: isRestoring ? Colors.grey : const Color(0xFF6B73FF),
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        SizedBox(height: 5.h),
        Zbutton(
          action: () async {
            if (products.isEmpty || isPurchasing || isRestoring) return;

            // Хэптик фидбек при нажатии
            HapticFeedback.lightImpact();

            onPurchase();
          },
          isLoading: isPurchasing,
          isActive: products.isNotEmpty && !isPurchasing && !isRestoring,
          text: isPurchasing ? '处理中...' : '立即更新',
          textColor: Colors.white,
        ),

        /// **Адаптивный отступ снизу**
        /// Больше на больших экранах, меньше на маленьких
        // SizedBox(height: 0.h),
      ],
    );
  }

  /// **Функция для открытия Terms & Conditions в браузере**
  /// Использует url_launcher для открытия веб-страницы с условиями использования
  /// https://zhiming.app/terms-and-conditions.html
  Future<void> _openTermsAndConditions(BuildContext context) async {
    try {
      final url = Uri.parse('https://zhiming.app/terms-and-conditions.html');

      // Проверяем, можем ли мы открыть URL
      if (await canLaunchUrl(url)) {
        // Хэптик фидбек при нажатии на ссылку
        await HapticFeedback.lightImpact();

        // Открываем в браузере
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication, // Открываем во внешнем браузере
        );

        debugPrint('[PaywallBottomSection] Открыт Terms & Conditions: $url');
      } else {
        debugPrint('[PaywallBottomSection] Не удается открыть URL: $url');

        // Показываем пользователю уведомление об ошибке
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('无法打开网页，请稍后重试')));
      }
    } catch (e) {
      debugPrint(
        '[PaywallBottomSection] Ошибка открытия Terms & Conditions: $e',
      );

      // Показываем пользователю уведомление об ошибке
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('无法打开网页，请稍后重试')));
    }
  }

  /// **Функция для открытия Privacy Policy в браузере**
  /// Использует url_launcher для открытия веб-страницы с политикой конфиденциальности
  /// https://zhiming.app/privacy-policy.html
  Future<void> _openPrivacyPolicy(BuildContext context) async {
    try {
      final url = Uri.parse('https://zhiming.app/privacy-policy.html');

      // Проверяем, можем ли мы открыть URL
      if (await canLaunchUrl(url)) {
        // Хэптик фидбек при нажатии на ссылку
        await HapticFeedback.lightImpact();

        // Открываем в браузере
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication, // Открываем во внешнем браузере
        );

        debugPrint('[PaywallBottomSection] Открыт Privacy Policy: $url');
      } else {
        debugPrint('[PaywallBottomSection] Не удается открыть URL: $url');

        // Показываем пользователю уведомление об ошибке
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('无法打开网页，请稍后重试')));
      }
    } catch (e) {
      debugPrint('[PaywallBottomSection] Ошибка открытия Privacy Policy: $e');

      // Показываем пользователю уведомление об ошибке
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('无法打开网页，请稍后重试')));
    }
  }
}
