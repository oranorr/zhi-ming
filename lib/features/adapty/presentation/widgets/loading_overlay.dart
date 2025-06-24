// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zhi_ming/core/extensions/build_context_extension.dart';

/// Виджет оверлея загрузки с пульсирующей анимацией
///
/// **Apple HIG дизайн принципы:**
/// - Полупрозрачный фон блокирует взаимодействие с интерфейсом
/// - Пульсирующая анимация создает engaging опыт
/// - Белый контейнер с мягкими тенями создает глубину
/// - Четкая типографика для информирования пользователя
class LoadingOverlay extends StatefulWidget {
  const LoadingOverlay({
    required this.isVisible,
    required this.statusText,
    required this.isPurchasing,
    super.key,
  });

  /// Показывать ли оверлей
  final bool isVisible;

  /// Текст статуса для отображения
  final String statusText;

  /// Флаг покупки (для разного текста описания)
  final bool isPurchasing;

  @override
  State<LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<LoadingOverlay>
    with SingleTickerProviderStateMixin {
  /// **Анимации для премиум UX (Apple HIG):**
  /// Контроллер анимации пульсации во время покупки
  /// Создает визуально привлекательный feedback для пользователя
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    /// Инициализация анимации пульсации для premium эффектов
    /// Используется во время покупки для создания engaging опыта
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(LoadingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    /// Запускаем/останавливаем анимацию в зависимости от видимости
    if (widget.isVisible && !oldWidget.isVisible) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isVisible && oldWidget.isVisible) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    /// Освобождаем ресурсы анимации при выходе из виджета
    /// Важно для предотвращения утечек памяти
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /// Если не видим - не показываем оверлей
    if (!widget.isVisible) return const SizedBox.shrink();

    return ColoredBox(
      /// Полупрозрачный фон блокирует взаимодействие с интерфейсом
      /// 50% прозрачности создает идеальный баланс видимости
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          /// Размеры контейнера рассчитаны для оптимального восприятия
          /// Достаточно места для иконки, заголовка и описания
          width: 280.w,
          height: 180.h,
          decoration: BoxDecoration(
            /// Белый фон обеспечивает максимальный контраст
            color: Colors.white,

            /// 20px радиус = современный macOS стиль
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              /// Мягкая тень создает ощущение "парения" над контентом
              /// 10% прозрачности черного + смещение создают глубину
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              /// **Анимированный индикатор загрузки**
              /// Пульсирующая анимация создает premium ощущения
              /// AnimatedBuilder оптимизирует производительность
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 60.w,
                      height: 60.h,
                      decoration: BoxDecoration(
                        /// Фоновый круг с цветом акцента приложения
                        /// 10% прозрачности создает мягкий ореол
                        color: const Color(0xFF6B73FF).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const CircularProgressIndicator(
                        /// Цвет индикатора совпадает с акцентом приложения
                        /// Обеспечивает визуальную согласованность
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF6B73FF),
                        ),
                        strokeWidth: 3,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 24.h),

              /// **Заголовок статуса (динамический)**
              /// Обновляется в зависимости от этапа покупки
              Text(
                widget.statusText,
                style: context.styles.h3.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),

              /// **Описание процесса (статическое)**
              /// Дает пользователю понимание что происходит
              Text(
                widget.isPurchasing ? '请稍等，正在处理您的购买...' : '正在恢复您的购买...',
                style: context.styles.mRegular.copyWith(
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
