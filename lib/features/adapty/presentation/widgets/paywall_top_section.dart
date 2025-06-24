// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zhi_ming/core/extensions/build_context_extension.dart';
import 'package:zhi_ming/features/home/presentation/home_screen.dart';

/// Виджет верхней секции пейволла с заголовком и иконками
///
/// **Адаптивный дизайн принципы:**
/// - Компактные размеры для экономии пространства
/// - Кнопка закрытия в стиле macOS
/// - Иконка приложения с адаптивными размерами
/// - Заголовки с оптимальной типографикой
class PaywallTopSection extends StatelessWidget {
  const PaywallTopSection({
    required this.isFirstReading,
    required this.isPurchasing,
    required this.isRestoring,
    super.key,
    this.onReturnToChat,
    this.onClearChat,
  });

  /// Первое ли это гадание пользователя
  final bool isFirstReading;

  /// Состояние процесса покупки
  final bool isPurchasing;

  /// Состояние процесса восстановления
  final bool isRestoring;

  /// Callback для возврата в чат
  final VoidCallback? onReturnToChat;

  /// Callback для очистки чата при закрытии paywall
  final VoidCallback? onClearChat;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        /// **Кнопка закрытия в стиле macOS**
        /// Заблокирована во время покупки для предотвращения случайного выхода
        Row(
          children: [
            IconButton(
              onPressed: () async {
                /// Предотвращаем закрытие во время покупки
                /// Защищает от потери прогресса покупки
                if (isPurchasing || isRestoring) return;

                /// НОВАЯ ЛОГИКА: разное поведение в зависимости от типа показа paywall
                if (onReturnToChat != null) {
                  // Если есть callback для возврата в чат - это новая логика
                  if (isFirstReading) {
                    // Первое гадание - просто возвращаемся в чат
                    debugPrint(
                      '[PaywallTopSection] Первое гадание - возврат в чат через pop',
                    );
                    onReturnToChat!();
                    Navigator.of(context).pop();
                  } else {
                    // Повторное гадание - очищаем чат и переходим домой
                    debugPrint(
                      '[PaywallTopSection] Повторное гадание - очистка чата и переход на домашний экран',
                    );

                    // Очищаем чат перед переходом домой
                    onClearChat?.call();

                    await Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const HomeScreen(),
                      ),
                      (route) => false,
                    );
                  }
                } else {
                  // Старая логика - домашний экран
                  /// Закрытие paywall и возврат на домашний экран
                  /// Очищаем стек навигации для согласованности
                  await Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                    (route) => false,
                  );
                }
              },
              icon: Icon(
                Icons.close,
                size: 28.sp, // Используем .sp для адаптивности иконки
                color: isPurchasing || isRestoring ? Colors.grey : Colors.black,
              ),
              padding: EdgeInsets.zero,
              style: IconButton.styleFrom(padding: EdgeInsets.zero),
            ),
          ],
        ),

        /// **Основная иконка приложения - адаптивные размеры**
        /// Уменьшены для экономии пространства на маленьких экранах
        Center(
          child: SizedBox(
            height: 80.h, // Уменьшено с 114.h для адаптивности
            width: 78.w, // Уменьшено с 111.w для адаптивности
            child: Image.asset('assets/heads.png'),
          ),
        ),
        SizedBox(height: 12.h), // Уменьшено с 18.h
        /// **Заголовок пейволла - компактный**
        /// Информирует о завершении базовой функции
        Text('您的占卜已结束', style: context.styles.h2, textAlign: TextAlign.center),
        SizedBox(height: 4.h), // Уменьшено с 6.h
        /// **Призыв к действию - компактный**
        /// Мотивирует к покупке VIP подписки
        Text(
          '升级VIP，畅享全部功能',
          style: context.styles.h2,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
