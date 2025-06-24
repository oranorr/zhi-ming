// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zhi_ming/core/extensions/build_context_extension.dart';
import 'package:zhi_ming/core/widgets/z_button.dart';
import 'package:zhi_ming/features/home/presentation/home_screen.dart';

/// Виджет экрана успешной покупки с premium анимациями
///
/// **Apple HIG премиум опыт:**
/// - Анимация конфетти для празднования
/// - Большая галочка как символ успеха
/// - Четкое сообщение о полученных преимуществах
/// - Простая кнопка "Завершить" для продолжения
///
/// **🎯 АДАПТИВНЫЕ УЛУЧШЕНИЯ:**
/// - SafeArea для корректной работы на всех устройствах
/// - Column с правильным распределением пространства
/// - Адаптивные размеры элементов через ScreenUtil
/// - Flexible виджеты для разных размеров экранов
class PurchaseSuccessScreen extends StatelessWidget {
  const PurchaseSuccessScreen({super.key, this.onReturnToChat});

  /// Callback для возврата в чат (для новой логики после встряхивания)
  final VoidCallback? onReturnToChat;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            /// **Верхняя часть с анимацией конфетти**
            /// Адаптивно позиционируется для разных экранов
            Flexible(
              flex: 2,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  /// Анимация конфетти - адаптивная позиция
                  Positioned(
                    top: 30.h, // Адаптивная позиция сверху
                    left: 0,
                    right: 0,
                    child: Image.asset('assets/confetty.png'),
                  ),
                ],
              ),
            ),

            /// **Центральная часть с основным контентом**
            /// Занимает основное пространство экрана
            Flexible(
              flex: 3,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    /// Большая иконка галочки - адаптивный размер
                    /// Меньше на маленьких экранах для экономии места
                    SizedBox(
                      width: 140.w, // Уменьшено со 170.w для адаптивности
                      height: 140.h, // Уменьшено со 170.h для адаптивности
                      child: Image.asset('assets/big_check.png'),
                    ),
                    SizedBox(height: 24.h), // Уменьшено с 36.h
                    /// Заголовок успешной покупки
                    Text(
                      '您的购买已成功完成！',
                      style: context.styles.h2,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.h), // Уменьшено с 12.h
                    /// Описание преимуществ VIP подписки
                    /// Информирует пользователя о том, что он получил
                    Text(
                      '恭喜您获得VIP专属权限，可查看个人八字命盘和深度运势分析！',
                      style: context.styles.h2,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            /// **Нижняя часть с кнопкой**
            /// Зафиксирована внизу с адаптивными отступами
            Flexible(
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Zbutton(
                  action: () async {
                    /// НОВАЯ ЛОГИКА: после покупки поведение зависит от контекста
                    if (onReturnToChat != null) {
                      // Возврат в чат после покупки
                      debugPrint(
                        '[PurchaseSuccessScreen] Покупка успешна - возврат в чат',
                      );
                      onReturnToChat!();
                      Navigator.of(context).pop();
                    } else {
                      /// Возврат на домашний экран после успешной покупки
                      /// Очищаем весь стек навигации для чистого состояния
                      await Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const HomeScreen(),
                        ),
                        (route) => false,
                      );
                    }
                  },
                  isLoading: false,
                  isActive: true,
                  text: '完成',
                  textColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
