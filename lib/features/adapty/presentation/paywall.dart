// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:zhi_ming/core/extensions/build_context_extension.dart';
import 'package:zhi_ming/features/adapty/data/repositories/adapty_repository_impl.dart';
import 'package:zhi_ming/core/theme/theme_colors.dart';
import 'package:zhi_ming/core/widgets/z_button.dart';
import 'package:zhi_ming/features/adapty/domain/models/subscription_product.dart';
import 'package:zhi_ming/features/home/presentation/home_screen.dart';

/// Основной виджет пейволла (экрана подписки)
///
/// **Новая архитектура с кэшированными продуктами:**
/// - Продукты предзагружаются при старте приложения в AdaptyRepositoryImpl
/// - На пейволле нет состояния загрузки - товары отображаются мгновенно
/// - Используется синглтон репозитория для доступа к кэшированным данным
///
/// **Apple HIG Design принципы:**
/// - Современный gradientный фон с плавными переходами
/// - Минималистичный дизайн в стиле macOS
/// - Плавные анимации и хэптик фидбек
/// - Четкая визуальная иерархия информации
class Paywall extends StatefulWidget {
  const Paywall({super.key});

  @override
  State<Paywall> createState() => _PaywallState();
}

/// Состояние основного пейволла с градиентным фоном
///
/// **Дизайн решения:**
/// - Используем Stack для наложения градиентов согласно Apple HIG
/// - Двойной градиент создает глубину и современный вид
/// - Цвета подобраны для создания premium ощущения
class _PaywallState extends State<Paywall> with SingleTickerProviderStateMixin {
  /// Контроллер анимации для плавного перехода между состояниами
  /// (в текущей версии не используется, но готов для будущих анимаций)
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    // [Paywall] Инициализация уже не нужна, так как сервис статический
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // **Основной цветной градиент**
            // Создает базовый фон с переходами от зеленого к фиолетовому
            // Использует 4 цвета с определенными позициями для плавности
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFEDFFCC), // светло-зеленый (природные тона)
                    Color(0xFFEEEFFF), // светло-фиолетовый (спокойствие)
                    Color(0xFFD6A0EA), // розово-фиолетовый (элегантность)
                    Color(0xFFA6AAFE), // голубовато-фиолетовый (доверие)
                  ],
                  stops: [0.0, 0.32, 0.57, 1.0],
                ),
              ),
              child: SizedBox.expand(),
            ),
            // **Белый градиент поверх для софт эффекта**
            // Добавляет дополнительную мягкость и читаемость тексту
            // Согласно Apple HIG - обеспечиваем хороший контраст
            Opacity(
              opacity: 0.42,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xffF2F2F2), // светло-серый с прозрачностью
                      Color(0xffFFFFFF), // полностью прозрачный белый
                    ],
                    stops: [0.0, 0.42],
                  ),
                ),
              ),
            ),
            // Основное содержимое пейволла
            _PaywallBody(),
          ],
        ),
      ),
    );
  }
}

/// Основное содержимое пейволла без состояния загрузки
///
/// **Архитектурное решение:**
/// Этот виджет больше не имеет состояния загрузки товаров,
/// так как все продукты предзагружаются при старте приложения
/// в синглтоне AdaptyRepositoryImpl
class _PaywallBody extends StatefulWidget {
  const _PaywallBody();

  @override
  State<_PaywallBody> createState() => __PaywallBodyState();
}

/// Состояние основного тела пейволла с современным UI/UX
///
/// **Новая архитектура продуктов:**
/// - ❌ isLoading - больше не нужно, продукты из кэша
/// - ✅ products - геттер из кэшированного репозитория
/// - ✅ Мгновенное отображение UI без задержек
///
/// **Apple HIG дизайн принципы применяемые здесь:**
/// - Плавные анимации для покупки с пульсацией
/// - Хэптик фидбек для всех действий пользователя
/// - Четкая визуальная иерархия с выделением важных элементов
/// - Использование системных иконок и паттернов
/// - Accessibility и читаемость текста
class __PaywallBodyState extends State<_PaywallBody>
    with TickerProviderStateMixin {
  /// Синглтон репозитория для доступа к кэшированным продуктам
  /// Теперь это единственный источник истины для продуктов
  static final repository = AdaptyRepositoryImpl.instance;

  /// Индекс выбранного плана подписки (по умолчанию первый)
  /// Используется для определения какой продукт покупать
  int selectedPlanIndex = 0;

  /// Флаг успешной покупки для показа экрана поздравления
  /// При true показывается анимация конфетти и сообщение об успехе
  bool isSuccess = false;

  /// ❌ УДАЛЕНО: isLoading - больше не нужно благодаря кэшированию
  /// Продукты доступны мгновенно из предзагруженного кэша

  /// Состояние процесса покупки с анимированным индикатором
  /// Показывает оверлей с пульсирующей анимацией во время покупки
  bool isPurchasing = false;

  /// Состояние процесса восстановления покупок
  /// Аналогично покупке, но для восстановления существующих подписок
  bool isRestoring = false;

  /// Геттер для получения кэшированных продуктов из репозитория
  /// **Ключевое изменение архитектуры:**
  /// Вместо List<SubscriptionProduct> products = []
  /// Теперь используем геттер из синглтона - всегда актуальные данные
  List<SubscriptionProduct> get products => repository.cachedProducts;

  /// Текст статуса для отображения во время покупки/восстановления
  /// Обновляется динамически для информирования пользователя
  String purchaseStatusText = '';

  /// **Анимации для премиум UX (Apple HIG):**
  /// Контроллер анимации пульсации во время покупки
  /// Создает визуально привлекательный feedback для пользователя
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    /// **РЕВОЛЮЦИОННОЕ ИЗМЕНЕНИЕ:**
    /// Больше не вызываем _loadProducts() - продукты уже загружены!
    /// Это значительно улучшает UX - нет задержек, нет скелетонов

    /// Инициализация анимации пульсации для premium эффектов
    /// Используется во время покупки для создания engaging опыта
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    /// Диагностика состояния кэша продуктов для отладки
    /// Помогает отследить, были ли продукты корректно предзагружены
    if (!repository.areProductsLoaded) {
      debugPrint(
        '[PaywallBody] ⚠️ Продукты не были предзагружены при инициализации',
      );
    } else {
      debugPrint(
        '[PaywallBody] ✅ Используем ${products.length} предзагруженных продуктов',
      );
    }
  }

  @override
  void dispose() {
    /// Освобождаем ресурсы анимации при выходе из виджета
    /// Важно для предотвращения утечек памяти
    _pulseController.dispose();
    super.dispose();
  }

  Widget _buildLoadingOverlay() {
    /// Если не покупаем и не восстанавливаем - не показываем оверлей
    if (!isPurchasing && !isRestoring) return const SizedBox.shrink();

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
                purchaseStatusText,
                style: context.styles.h3.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),

              /// **Описание процесса (статическое)**
              /// Дает пользователю понимание что происходит
              Text(
                isPurchasing ? '请稍等，正在处理您的购买...' : '正在恢复您的购买...',
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

  @override
  Widget build(BuildContext context) {
    /// **Экран успешной покупки с premium анимациями - АДАПТИВНАЯ ВЕРСИЯ**
    /// Показывается когда isSuccess = true
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
    if (isSuccess) {
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
                      /// Возврат на домашний экран после успешной покупки
                      /// Очищаем весь стек навигации для чистого состояния
                      await Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const HomeScreen(),
                        ),
                        (route) => false,
                      );
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

    /// **ОСНОВНОЙ ИНТЕРФЕЙС ПЕЙВОЛЛА - АДАПТИВНЫЙ ДИЗАЙН**
    ///
    /// **Новая архитектура без состояний загрузки:**
    /// - ✅ Мгновенное отображение продуктов из кэша
    /// - ❌ Нет isLoading индикаторов
    /// - ❌ Нет скелетон экранов
    /// - ✅ Плавные переходы и анимации
    ///
    /// **🎯 АДАПТИВНОСТЬ БЕЗ СКРОЛЛА:**
    /// - Используем SafeArea для учета всех экранов
    /// - Column с MainAxisAlignment.spaceBetween для распределения
    /// - Flexible виджеты для адаптации под разные размеры экранов
    /// - Адаптивные размеры через ScreenUtil (.w/.h)
    /// - Все элементы помещаются на экране без скролла
    ///
    /// **Apple HIG UX принципы:**
    /// - AbsorbPointer блокирует взаимодействие во время покупки
    /// - Opacity создает визуальный feedback о заблокированном состоянии
    /// - Stack позволяет наложить loading overlay поверх контента
    return Stack(
      children: [
        /// **Основной контент пейволла - АДАПТИВНЫЙ LAYOUT**
        /// Заблокирован во время покупки/восстановления для UX
        AbsorbPointer(
          absorbing:
              isPurchasing ||
              isRestoring, // Блокируем взаимодействие во время покупки
          child: Opacity(
            opacity:
                isPurchasing || isRestoring ? 0.5 : 1.0, // Затемняем контент
            child: SafeArea(
              /// **SafeArea обеспечивает корректную работу на всех устройствах**
              /// включая iPhone с динамическим островом, Android с вырезами
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),

                /// **🚀 КЛЮЧЕВОЕ ИЗМЕНЕНИЕ: Column вместо SingleChildScrollView**
                /// Теперь весь контент распределяется по экрану адаптивно
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    /// **📱 ВЕРХНЯЯ СЕКЦИЯ - Заголовок и иконки**
                    /// Занимает минимально необходимое пространство
                    _buildTopSection(),

                    /// **🔧 СРЕДНЯЯ СЕКЦИЯ - Преимущества и планы**
                    /// Расширяется на доступное пространство экрана
                    Expanded(child: _buildMiddleSection()),

                    /// **💳 НИЖНЯЯ СЕКЦИЯ - Кнопки покупки**
                    /// Зафиксирована внизу с адаптивными отступами
                    _buildBottomSection(),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Оверлей с индикатором загрузки (остается без изменений)
        _buildLoadingOverlay(),
      ],
    );
  }

  /// **📱 ВЕРХНЯЯ СЕКЦИЯ - Заголовок и иконки**
  ///
  /// **Адаптивный дизайн принципы:**
  /// - Компактные размеры для экономии пространства
  /// - Кнопка закрытия в стиле macOS
  /// - Иконка приложения с адаптивными размерами
  /// - Заголовки с оптимальной типографикой
  Widget _buildTopSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        /// **Отступ сверху адаптивный**
        /// На больших экранах больше, на маленьких - меньше
        // SizedBox(height: .h),

        /// **Кнопка закрытия в стиле macOS**
        /// Заблокирована во время покупки для предотвращения случайного выхода
        Row(
          children: [
            IconButton(
              onPressed: () async {
                /// Предотвращаем закрытие во время покупки
                /// Защищает от потери прогресса покупки
                if (isPurchasing || isRestoring) return;

                /// Закрытие paywall и возврат на домашний экран
                /// Очищаем стек навигации для согласованности
                await Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                  (route) => false,
                );
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

  /// **🔧 СРЕДНЯЯ СЕКЦИЯ - Преимущества и планы**
  ///
  /// **Адаптивные принципы:**
  /// - Используем SingleChildScrollView только для этой секции
  /// - Flexible height адаптируется под доступное пространство
  /// - Компактные отступы для помещения всего контента
  /// - Список планов с оптимизированными размерами
  Widget _buildMiddleSection() {
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

  /// **💳 НИЖНЯЯ СЕКЦИЯ - Кнопки покупки**
  ///
  /// **Фиксированный дизайн:**
  /// - Всегда внизу экрана
  /// - Условия подписки компактно
  /// - Кнопка восстановления покупок
  /// - Основная кнопка покупки
  /// - Адаптивные отступы снизу
  Widget _buildBottomSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        /// **Условия подписки - компактно**
        Text(
          '自动续订，可随时取消。\n条款和隐私政策。恢复购买',
          style: context.styles.mDemilight.copyWith(
            color: Colors.black,
            height: 1.4, // Уменьшена с 1.5 для компактности
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 6.h), // Уменьшено с 8.h
        /// **Кнопка восстановления покупок**
        TextButton(
          onPressed: () async {
            if (isPurchasing || isRestoring) return;

            // Хэптик фидбек при нажатии
            HapticFeedback.lightImpact();

            setState(() {
              isRestoring = true;
              purchaseStatusText = '正在验证您的购买记录...';
            });

            // Запускаем анимацию пульсации
            _pulseController.repeat(reverse: true);

            try {
              debugPrint('[PaywallBody] Восстановление покупок');
              final success = await repository.restorePurchases();

              // Останавливаем анимацию
              _pulseController.stop();

              if (success) {
                // Успех - хэптик фидбек
                HapticFeedback.mediumImpact();

                setState(() {
                  isSuccess = true;
                  isRestoring = false;
                });
              } else {
                // Ошибка - хэптик фидбек
                HapticFeedback.heavyImpact();

                setState(() {
                  isRestoring = false;
                });
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('未找到可恢复的购买记录')));
                }
              }
            } catch (e) {
              debugPrint('[PaywallBody] Ошибка восстановления покупок: $e');

              // Останавливаем анимацию и хэптик фидбек ошибки
              _pulseController.stop();
              HapticFeedback.heavyImpact();

              setState(() {
                isRestoring = false;
              });
              if (mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('恢复购买失败，请重试')));
              }
            }
          },
          child: Text(
            '恢复购买',
            style: context.styles.mRegular.copyWith(
              color: isRestoring ? Colors.grey : const Color(0xFF6B73FF),
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        SizedBox(height: 8.h), // Уменьшено с 12.h
        /// **Основная кнопка покупки**
        Zbutton(
          action: () async {
            if (products.isEmpty || isPurchasing || isRestoring) return;

            // Хэптик фидбек при нажатии
            HapticFeedback.lightImpact();

            setState(() {
              isPurchasing = true;
              purchaseStatusText = '正在连接支付系统...';
            });

            // Запускаем анимацию пульсации
            _pulseController.repeat(reverse: true);

            try {
              // Получаем выбранный продукт
              final selectedProduct = products[selectedPlanIndex];
              debugPrint(
                '[PaywallBody] Покупка продукта: ${selectedProduct.productId}',
              );

              // Обновляем статус
              setState(() {
                purchaseStatusText = '正在处理支付...';
              });

              // Покупка через Adapty репозиторий
              final success = await repository.purchaseSubscription(
                selectedProduct.productId,
              );

              // Останавливаем анимацию
              _pulseController.stop();

              if (success) {
                // Успех - хэптик фидбек
                HapticFeedback.mediumImpact();

                setState(() {
                  isSuccess = true;
                  isPurchasing = false;
                });
              } else {
                // Ошибка - хэптик фидбек
                HapticFeedback.heavyImpact();

                setState(() {
                  isPurchasing = false;
                });
                // Показываем ошибку
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('购买失败，请重试')));
                }
              }
            } catch (e) {
              debugPrint('[PaywallBody] Ошибка покупки: $e');

              // Останавливаем анимацию и хэптик фидбек ошибки
              _pulseController.stop();
              HapticFeedback.heavyImpact();

              setState(() {
                isPurchasing = false;
              });
              if (mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('购买失败，请重试')));
              }
            }
          },
          isLoading: isPurchasing,
          isActive: products.isNotEmpty && !isPurchasing && !isRestoring,
          text: isPurchasing ? '处理中...' : '立即更新',
          textColor: Colors.white,
        ),

        /// **Адаптивный отступ снизу**
        /// Больше на больших экранах, меньше на маленьких
        SizedBox(height: 12.h),
      ],
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
          (e) => Padding(
            padding: EdgeInsets.only(bottom: 6.h), // Компактные отступы
            child: Row(
              children: [
                SvgPicture.asset(
                  'assets/crown.svg',
                  width: 14.w, // Уменьшено с 16.w
                  height: 14.h, // Уменьшено с 16.h
                ),
                SizedBox(width: 10.w), // Уменьшено с 12.w
                Expanded(child: Text(e, style: context.styles.mDemilight)),
              ],
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
          (entry) => _PlanCard(
            product: entry.value,
            isSelected: selectedPlanIndex == entry.key,
            onTap:
                () => setState(() {
                  selectedPlanIndex = entry.key;
                }),
            needsBottomPadding: entry.key == products.length - 1,
            isDisabled: isPurchasing || isRestoring,
            hasDiscount: entry.value.isRecommended,
            isCompact: true, // Новый параметр для компактного отображения
          ),
        )
        .toList();
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.product,
    required this.isSelected,
    required this.onTap,
    required this.needsBottomPadding,
    required this.isDisabled,
    required this.hasDiscount,
    required this.isCompact,
  });

  final SubscriptionProduct product;
  final bool isSelected;
  final VoidCallback onTap;
  final bool needsBottomPadding;
  final bool isDisabled;
  final bool hasDiscount;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      /// **Адаптивные отступы между карточками**
      /// В компактном режиме отступы меньше для экономии места
      padding: EdgeInsets.only(
        bottom:
            !needsBottomPadding
                ? (isCompact
                    ? 6.h
                    : 10.h) // Уменьшенные отступы в компактном режиме
                : 0,
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
                  horizontal:
                      isCompact
                          ? 12.w
                          : 16.w, // Компактные горизонтальные отступы
                  vertical:
                      isCompact ? 8.h : 12.h, // Компактные вертикальные отступы
                ),
                child: Row(
                  children: [
                    // Checkbox/иконка выбора - адаптивный размер
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: isCompact ? 20.w : 24.w, // Компактный размер
                      height: isCompact ? 20.h : 24.h, // Компактный размер
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
                        ), // Компактные углы
                      ),
                      child:
                          isSelected
                              ? Icon(
                                Icons.check,
                                color: Colors.white,
                                size: isCompact ? 12 : 16, // Компактная иконка
                              )
                              : null,
                    ),
                    SizedBox(
                      width: isCompact ? 12.w : 16.w,
                    ), // Компактный отступ
                    // Информация о плане с адаптивными отступами
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
                        if (hasDiscount && product.originalPrice != null) ...[
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
                  right: isCompact ? 120.w : 143.w, // Адаптивная позиция
                  top: isCompact ? -10.h : -13.h, // Адаптивная позиция
                  child: Container(
                    width: isCompact ? 45.w : 50.w, // Компактная ширина
                    height: isCompact ? 20.h : 25.h, // Компактная высота
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B73FF),
                      borderRadius: BorderRadius.circular(
                        isCompact ? 10.r : 12.r,
                      ), // Компактные углы
                    ),
                    child: Center(
                      child: Text(
                        '折扣',
                        style: context.styles.sDemilight.copyWith(
                          color: Colors.white,
                          height: 1.h,
                          fontSize:
                              isCompact ? 11.sp : null, // Компактный шрифт
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
