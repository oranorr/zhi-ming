// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zhi_ming/features/adapty/presentation/services/paywall_state_service.dart';
import 'package:zhi_ming/features/adapty/presentation/widgets/loading_overlay.dart';
import 'package:zhi_ming/features/adapty/presentation/widgets/paywall_bottom_section.dart';
import 'package:zhi_ming/features/adapty/presentation/widgets/paywall_middle_section.dart';
import 'package:zhi_ming/features/adapty/presentation/widgets/paywall_top_section.dart';
import 'package:zhi_ming/features/adapty/presentation/widgets/purchase_success_screen.dart';

class Paywall extends StatefulWidget {
  const Paywall({
    super.key,
    this.isFirstReading = false,
    this.onReturnToChat,
    this.onClearChat,
  });

  /// Первое ли это гадание пользователя
  final bool isFirstReading;

  /// Callback для возврата в чат (для новой логики после встряхивания)
  final VoidCallback? onReturnToChat;

  /// Callback для очистки чата при закрытии paywall (для повторных гаданий)
  final VoidCallback? onClearChat;

  @override
  State<Paywall> createState() => _PaywallState();
}

class _PaywallState extends State<Paywall> {
  late final PaywallStateService _stateService;

  @override
  void initState() {
    super.initState();
    _stateService = PaywallStateService();

    /// Диагностика состояния кэша продуктов для отладки
    if (!PaywallStateService.repository.areProductsLoaded) {
      debugPrint(
        '[Paywall] ⚠️ Продукты не были предзагружены при инициализации',
      );
    } else {
      debugPrint(
        '[Paywall] ✅ Используем ${_stateService.products.length} предзагруженных продуктов',
      );
    }
  }

  @override
  void dispose() {
    _stateService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            /// **Основной цветной градиент**
            /// Создает базовый фон с переходами от зеленого к фиолетовому
            const DecoratedBox(
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

            /// **Белый градиент поверх для софт эффекта**
            /// Добавляет дополнительную мягкость и читаемость тексту
            const Opacity(
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

            /// **Основное содержимое пейволла**
            ListenableBuilder(
              listenable: _stateService,
              builder: (context, child) {
                /// **Экран успешной покупки**
                if (_stateService.isSuccess) {
                  return PurchaseSuccessScreen(
                    onReturnToChat: widget.onReturnToChat,
                  );
                }

                /// **Основной интерфейс пейволла**
                return _buildMainPaywallInterface();
              },
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
  Widget _buildMainPaywallInterface() {
    return Stack(
      children: [
        /// **Основной контент пейволла - АДАПТИВНЫЙ LAYOUT**
        /// Заблокирован во время покупки/восстановления для UX
        AbsorbPointer(
          absorbing: _stateService.isPurchasing || _stateService.isRestoring,
          child: Opacity(
            opacity:
                _stateService.isPurchasing || _stateService.isRestoring
                    ? 0.5
                    : 1.0,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    /// **📱 ВЕРХНЯЯ СЕКЦИЯ - Заголовок и иконки**
                    PaywallTopSection(
                      isFirstReading: widget.isFirstReading,
                      isPurchasing: _stateService.isPurchasing,
                      isRestoring: _stateService.isRestoring,
                      onReturnToChat: widget.onReturnToChat,
                      onClearChat: widget.onClearChat,
                    ),

                    /// **🔧 СРЕДНЯЯ СЕКЦИЯ - Преимущества и планы**
                    Expanded(
                      child: PaywallMiddleSection(
                        products: _stateService.products,
                        selectedPlanIndex: _stateService.selectedPlanIndex,
                        isPurchasing: _stateService.isPurchasing,
                        isRestoring: _stateService.isRestoring,
                        onPlanSelected: _stateService.selectPlan,
                      ),
                    ),

                    /// **💳 НИЖНЯЯ СЕКЦИЯ - Кнопки покупки**
                    PaywallBottomSection(
                      products: _stateService.products,
                      isPurchasing: _stateService.isPurchasing,
                      isRestoring: _stateService.isRestoring,
                      onPurchase: _handlePurchase,
                      onRestore: _handleRestore,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        /// **Оверлей с индикатором загрузки**
        LoadingOverlay(
          isVisible: _stateService.isPurchasing || _stateService.isRestoring,
          statusText: _stateService.purchaseStatusText,
          isPurchasing: _stateService.isPurchasing,
        ),
      ],
    );
  }

  /// **Обработчик покупки с обработкой ошибок**
  Future<void> _handlePurchase() async {
    final success = await _stateService.purchaseSubscription();

    if (!success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('购买失败，请重试')));
    }
  }

  /// **Обработчик восстановления покупок с обработкой ошибок**
  Future<void> _handleRestore() async {
    final success = await _stateService.restorePurchases();

    if (!success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('未找到可恢复的购买记录')));
    }
  }
}
