// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zhi_ming/features/adapty/data/repositories/adapty_repository_impl.dart';
import 'package:zhi_ming/features/adapty/domain/models/subscription_product.dart';

/// Сервис для управления состоянием пейволла
///
/// **Архитектурное решение:**
/// Выносим бизнес-логику из UI компонентов для лучшей тестируемости
/// и разделения ответственности согласно принципам чистой архитектуры
class PaywallStateService extends ChangeNotifier {
  /// Синглтон репозитория для доступа к кэшированным продуктам
  static final repository = AdaptyRepositoryImpl.instance;

  /// Индекс выбранного плана подписки (по умолчанию первый)
  int _selectedPlanIndex = 0;
  int get selectedPlanIndex => _selectedPlanIndex;

  /// Флаг успешной покупки для показа экрана поздравления
  bool _isSuccess = false;
  bool get isSuccess => _isSuccess;

  /// Состояние процесса покупки с анимированным индикатором
  bool _isPurchasing = false;
  bool get isPurchasing => _isPurchasing;

  /// Состояние процесса восстановления покупок
  bool _isRestoring = false;
  bool get isRestoring => _isRestoring;

  /// Текст статуса для отображения во время покупки/восстановления
  String _purchaseStatusText = '';
  String get purchaseStatusText => _purchaseStatusText;

  /// Геттер для получения кэшированных продуктов из репозитория
  List<SubscriptionProduct> get products => repository.cachedProducts;

  /// Выбор плана подписки
  void selectPlan(int index) {
    if (index != _selectedPlanIndex) {
      _selectedPlanIndex = index;
      notifyListeners();
    }
  }

  /// Покупка подписки
  Future<bool> purchaseSubscription() async {
    if (products.isEmpty || _isPurchasing || _isRestoring) return false;

    // Хэптик фидбек при нажатии
    HapticFeedback.lightImpact();

    _setPurchasingState(true, '正在连接支付系统...');

    try {
      // Получаем выбранный продукт
      final selectedProduct = products[_selectedPlanIndex];
      debugPrint(
        '[PaywallStateService] Покупка продукта: ${selectedProduct.productId}',
      );

      // Обновляем статус
      _setPurchasingState(true, '正在处理支付...');

      // Покупка через Adapty репозиторий
      final success = await repository.purchaseSubscription(
        selectedProduct.productId,
      );

      if (success) {
        // Успех - хэптик фидбек
        HapticFeedback.mediumImpact();
        _setSuccessState();
        return true;
      } else {
        // Ошибка - хэптик фидбек
        HapticFeedback.heavyImpact();
        _setPurchasingState(false, '');
        return false;
      }
    } catch (e) {
      debugPrint('[PaywallStateService] Ошибка покупки: $e');

      // Хэптик фидбек ошибки
      HapticFeedback.heavyImpact();
      _setPurchasingState(false, '');
      return false;
    }
  }

  /// Восстановление покупок
  Future<bool> restorePurchases() async {
    if (_isPurchasing || _isRestoring) return false;

    // Хэптик фидбек при нажатии
    HapticFeedback.lightImpact();

    _setRestoringState(true, '正在验证您的购买记录...');

    try {
      debugPrint('[PaywallStateService] Восстановление покупок');
      final success = await repository.restorePurchases();

      if (success) {
        // Успех - хэптик фидбек
        HapticFeedback.mediumImpact();
        _setSuccessState();
        return true;
      } else {
        // Ошибка - хэптик фидбек
        HapticFeedback.heavyImpact();
        _setRestoringState(false, '');
        return false;
      }
    } catch (e) {
      debugPrint('[PaywallStateService] Ошибка восстановления покупок: $e');

      // Хэптик фидбек ошибки
      HapticFeedback.heavyImpact();
      _setRestoringState(false, '');
      return false;
    }
  }

  /// Сброс состояния успеха (для повторного использования)
  void resetSuccessState() {
    _isSuccess = false;
    notifyListeners();
  }

  /// Установка состояния покупки
  void _setPurchasingState(bool isPurchasing, String statusText) {
    _isPurchasing = isPurchasing;
    _purchaseStatusText = statusText;
    notifyListeners();
  }

  /// Установка состояния восстановления
  void _setRestoringState(bool isRestoring, String statusText) {
    _isRestoring = isRestoring;
    _purchaseStatusText = statusText;
    notifyListeners();
  }

  /// Установка состояния успеха
  void _setSuccessState() {
    _isSuccess = true;
    _isPurchasing = false;
    _isRestoring = false;
    _purchaseStatusText = '';
    notifyListeners();
  }
}
