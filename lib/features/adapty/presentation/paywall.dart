// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:zhi_ming/core/extensions/build_context_extension.dart';
import 'package:zhi_ming/core/services/adapty/adapty_service.dart';
import 'package:zhi_ming/core/services/adapty/adapty_service_impl.dart';
import 'package:zhi_ming/core/theme/theme_colors.dart';
import 'package:zhi_ming/core/widgets/z_button.dart';
import 'package:zhi_ming/features/home/presentation/home_page.dart';
import 'package:zhi_ming/features/adapty/domain/models/subscription_product.dart';

class Paywall extends StatefulWidget {
  const Paywall({super.key});

  @override
  State<Paywall> createState() => _PaywallState();
}

class _PaywallState extends State<Paywall> {
  static final AdaptyService _adaptyService = AdaptyServiceImpl();

  @override
  void initState() {
    super.initState();
    // Инициализация уже не нужна, так как сервис статический
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Основной цветной градиент
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFEDFFCC), // светло-зеленый
                    Color(0xFFEEEFFF), // светло-фиолетовый
                    Color(0xFFD6A0EA), // розово-фиолетовый
                    Color(0xFFA6AAFE), // голубовато-фиолетовый
                  ],
                  stops: [0.0, 0.32, 0.57, 1.0],
                ),
              ),
              child: SizedBox.expand(),
            ),
            // Белый градиент поверх
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
                // child: Center(child: Text('Paywall')),
              ),
            ),
            _PaywallBody(),
          ],
        ),
      ),
    );
  }
}

class _PaywallBody extends StatefulWidget {
  const _PaywallBody();

  @override
  State<_PaywallBody> createState() => __PaywallBodyState();
}

class __PaywallBodyState extends State<_PaywallBody>
    with TickerProviderStateMixin {
  int selectedPlanIndex = 0; // Первый план выбран по умолчанию
  bool isSuccess = false;
  bool isLoading = true; // Добавляем состояние загрузки
  bool isPurchasing = false; // Состояние загрузки покупки
  bool isRestoring = false; // Состояние восстановления покупок
  List<SubscriptionProduct> products = []; // Реальные продукты
  String purchaseStatusText = ''; // Текст статуса покупки

  // Анимация для пульсации во время покупки
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _loadProducts(); // Загружаем продукты при инициализации

    // Инициализация анимации пульсации
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// Загрузка доступных продуктов из AdaptyService
  Future<void> _loadProducts() async {
    try {
      debugPrint('[PaywallBody] Загрузка продуктов...');
      final loadedProducts =
          await _PaywallState._adaptyService.getAvailableProducts();

      setState(() {
        products = loadedProducts;
        isLoading = false;
      });

      debugPrint('[PaywallBody] Загружено ${products.length} продуктов');
    } catch (e) {
      debugPrint('[PaywallBody] Ошибка загрузки продуктов: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Показ оверлея с индикатором загрузки
  Widget _buildLoadingOverlay() {
    if (!isPurchasing && !isRestoring) return const SizedBox.shrink();

    return ColoredBox(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          width: 280.w,
          height: 180.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
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
              // Анимированный индикатор загрузки
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 60.w,
                      height: 60.h,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B73FF).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const CircularProgressIndicator(
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
              Text(
                purchaseStatusText,
                style: context.styles.h3.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
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
    if (isSuccess) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          alignment: Alignment.topCenter,
          children: [
            Positioned(
              top: 100.h,
              left: 0,
              right: 0,
              child: Image.asset('assets/confetty.png'),
            ),
            Positioned(
              top: 290.h,
              left: 0,
              right: 0,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  children: [
                    SizedBox(
                      width: 170.w,
                      height: 170.h,
                      child: Image.asset('assets/big_check.png'),
                    ),
                    SizedBox(height: 36.h),
                    Text('您的购买已成功完成！', style: context.styles.h2),
                    SizedBox(height: 12.h),
                    Text(
                      '恭喜您获得VIP专属权限，可查看个人八字命盘和深度运势分析！',
                      style: context.styles.h2,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Zbutton(
              action: () async {
                // Возврат на домашний экран
                await Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const HomePage()),
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
      );
    }

    return Stack(
      children: [
        // Основной контент
        AbsorbPointer(
          absorbing:
              isPurchasing ||
              isRestoring, // Блокируем взаимодействие во время покупки
          child: Opacity(
            opacity:
                isPurchasing || isRestoring ? 0.5 : 1.0, // Затемняем контент
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 50.h),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () async {
                            // Предотвращаем закрытие во время покупки
                            if (isPurchasing || isRestoring) return;

                            // Закрытие paywall и возврат на домашний экран
                            await Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (context) => const HomePage(),
                              ),
                              (route) => false,
                            );
                          },
                          icon: Icon(
                            Icons.close,
                            size: 30,
                            color:
                                isPurchasing || isRestoring
                                    ? Colors.grey
                                    : Colors.black,
                          ),
                          padding: EdgeInsets.zero,
                          style: IconButton.styleFrom(padding: EdgeInsets.zero),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 114.h,
                      width: 111.w,
                      child: Image.asset('assets/heads.png'),
                    ),
                    SizedBox(height: 18.h),
                    Text('您的占卜已结束', style: context.styles.h2),
                    SizedBox(height: 6.h),
                    Text('升级VIP，畅享全部功能', style: context.styles.h2),
                    SizedBox(height: 24.h),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('要继续并了解更多：', style: context.styles.mRegular),
                              SizedBox(height: 10.h),
                              ..._buildAdvantages(),
                              SizedBox(height: 32.h),
                              // Показываем индикатор загрузки или продукты
                              if (isLoading)
                                const Center(child: CircularProgressIndicator())
                              else if (products.isEmpty)
                                Text(
                                  '暂无可用套餐',
                                  style: context.styles.mRegular.copyWith(
                                    color: Colors.grey,
                                  ),
                                )
                              else
                                ..._buildPlans(),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '自动续订，可随时取消。\n条款和隐私政策。恢复购买',
                      style: context.styles.mDemilight.copyWith(
                        color: Colors.black,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.h),
                    // Кнопка восстановления покупок
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
                          final success =
                              await _PaywallState._adaptyService
                                  .restorePurchases();

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
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('未找到可恢复的购买记录')),
                              );
                            }
                          }
                        } catch (e) {
                          debugPrint(
                            '[PaywallBody] Ошибка восстановления покупок: $e',
                          );

                          // Останавливаем анимацию и хэптик фидбек ошибки
                          _pulseController.stop();
                          HapticFeedback.heavyImpact();

                          setState(() {
                            isRestoring = false;
                          });
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('恢复购买失败，请重试')),
                            );
                          }
                        }
                      },
                      child: Text(
                        '恢复购买',
                        style: context.styles.mRegular.copyWith(
                          color:
                              isRestoring
                                  ? Colors.grey
                                  : const Color(0xFF6B73FF),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Zbutton(
                      action: () async {
                        if (products.isEmpty || isPurchasing || isRestoring)
                          return;

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

                          // Активируем подписку
                          final success = await _PaywallState._adaptyService
                              .purchaseSubscription(selectedProduct.productId);

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
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('购买失败，请重试')),
                              );
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('购买失败，请重试')),
                            );
                          }
                        }
                      },
                      isLoading: isPurchasing,
                      isActive:
                          !isLoading &&
                          products.isNotEmpty &&
                          !isPurchasing &&
                          !isRestoring,
                      text: isPurchasing ? '处理中...' : '立即更新',
                      textColor: Colors.white,
                    ),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Оверлей с индикатором загрузки
        _buildLoadingOverlay(),
      ],
    );
  }

  List<Widget> _buildAdvantages() {
    List<String> texts = ['无限占卜', '无限的澄清和问题', '保存所有牌局在历史记录中'];
    return texts
        .map(
          (e) => Row(
            children: [
              SvgPicture.asset('assets/crown.svg', width: 16.w, height: 16.h),
              SizedBox(width: 12.w),
              Text(e, style: context.styles.mDemilight),
            ],
          ),
        )
        .toList();
  }

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
  });
  final SubscriptionProduct product;
  final bool isSelected;
  final VoidCallback onTap;
  final bool needsBottomPadding;
  final bool isDisabled;
  final bool hasDiscount;
  @override
  Widget build(BuildContext context) {
    // final hasDiscount =
    //     product.discountPercentage != null && product.discountPercentage! > 0;

    return Padding(
      padding: EdgeInsets.only(bottom: !needsBottomPadding ? 10.h : 0),
      child: InkWell(
        onTap:
            isDisabled
                ? null
                : () {
                  // Хэптик фидбек при выборе плана
                  HapticFeedback.selectionClick();
                  onTap();
                },
        borderRadius: BorderRadius.circular(20.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDisabled ? Colors.grey.shade100 : Colors.white,
            borderRadius: BorderRadius.circular(20.r),
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
              // Основное содержимое
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Row(
                  children: [
                    // Checkbox/иконка выбора
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 24.w,
                      height: 24.h,
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
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child:
                          isSelected
                              ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              )
                              : null,
                    ),
                    SizedBox(width: 16.w),
                    // Информация о плане
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            product.title,
                            style: context.styles.mMedium.copyWith(
                              // fontWeight: FontWeight.w600,
                              // color: isDisabled ? Colors.grey.shade600 : null,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            product.description,
                            style: context.styles.sDemilight.copyWith(),
                          ),
                        ],
                      ),
                    ),
                    // Цена
                    Row(
                      children: [
                        if (hasDiscount && product.originalPrice != null) ...[
                          Text(
                            product.originalPrice!,
                            style: context.styles.mMedium.copyWith(
                              color: ZColors.grayDark,
                              decoration: TextDecoration.lineThrough,
                              // fontWeight: FontWeight.w600,
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
              // Кнопка скидки для продуктов со скидкой
              if (hasDiscount)
                Positioned(
                  right: 143.w,
                  top: -13.h,
                  child: Container(
                    width: 50.w,
                    height: 25.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B73FF),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Center(
                      child: Text(
                        '折扣',
                        style: context.styles.sDemilight.copyWith(
                          color: Colors.white,
                          height: 1.h,
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
