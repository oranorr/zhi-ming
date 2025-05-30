import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:zhi_ming/core/services/adapty/adapty_service.dart';
import 'package:zhi_ming/features/adapty/domain/models/subscription_product.dart';
import 'package:zhi_ming/features/adapty/data/repositories/adapty_repository_impl.dart';
import 'package:zhi_ming/features/adapty/domain/repositories/adapty_repository.dart';

class AdaptyServiceImpl implements AdaptyService {
  static const _storage = FlutterSecureStorage();

  // Ключи для хранения данных
  static const String _subscriptionStatusKey = 'subscription_status';
  static const String _freeRequestsCountKey = 'free_requests_count';

  // Константы
  static const int _maxFreeRequests = kDebugMode ? 5 : 20;

  // Репозиторий Adapty для реальных вызовов
  late final AdaptyRepository _adaptyRepository;
  bool _isRepositoryInitialized = false;

  /// Инициализация репозитория Adapty
  Future<void> _initializeRepository() async {
    if (!_isRepositoryInitialized) {
      _adaptyRepository = AdaptyRepositoryImpl();
      await _adaptyRepository.initialize();
      _isRepositoryInitialized = true;
      debugPrint('[AdaptyServiceImpl] Репозиторий Adapty инициализирован');
    }
  }

  @override
  Future<void> init() async {
    // Инициализируем репозиторий Adapty
    await _initializeRepository();

    // Инициализируем счетчик бесплатных запросов, если он еще не установлен
    final currentCount = await getRemainingFreeRequests();
    if (currentCount == _maxFreeRequests) {
      // Если счетчик равен максимальному значению, возможно это первый запуск
      // Проверяем, есть ли сохраненное значение
      final savedCount = await _storage.read(key: _freeRequestsCountKey);
      if (savedCount == null) {
        // Первый запуск - устанавливаем максимальное количество запросов
        await _storage.write(
          key: _freeRequestsCountKey,
          value: _maxFreeRequests.toString(),
        );
      }
    }
  }

  @override
  Future<bool> hasActiveSubscription() async {
    await _initializeRepository();

    try {
      // Используем реальный статус подписки из Adapty
      final subscriptionStatus =
          await _adaptyRepository.getSubscriptionStatus();
      final isActive = subscriptionStatus.hasPremiumAccess;

      debugPrint('[AdaptyServiceImpl] Статус подписки из Adapty: $isActive');
      return isActive;
    } catch (e) {
      debugPrint('[AdaptyServiceImpl] Ошибка проверки подписки: $e');

      // Fallback на локальное хранение для debug режима
      if (kDebugMode) {
        final status = await _storage.read(key: _subscriptionStatusKey);
        return status == 'active';
      }

      return false;
    }
  }

  @override
  Future<int> getRemainingFreeRequests() async {
    final countStr = await _storage.read(key: _freeRequestsCountKey);

    if (countStr == null) {
      // Если значение не найдено, устанавливаем максимальное количество
      await _storage.write(
        key: _freeRequestsCountKey,
        value: _maxFreeRequests.toString(),
      );
      return _maxFreeRequests;
    }
    debugPrint('Счетчик бесплатных: $countStr');
    return int.tryParse(countStr) ?? _maxFreeRequests;
  }

  @override
  Future<void> decrementFreeRequests() async {
    await _initializeRepository();

    try {
      // Используем метод репозитория
      await _adaptyRepository.decrementFreeRequests();
      debugPrint('[AdaptyServiceImpl] Счетчик бесплатных запросов уменьшен');
    } catch (e) {
      debugPrint('[AdaptyServiceImpl] Ошибка уменьшения счетчика: $e');

      // Fallback на локальную реализацию
      final currentCount = await getRemainingFreeRequests();
      if (currentCount > 0) {
        final newCount = currentCount - 1;
        await _storage.write(
          key: _freeRequestsCountKey,
          value: newCount.toString(),
        );
        debugPrint(
          '[AdaptyServiceImpl] Локальное уменьшение счетчика до: $newCount',
        );
      }
    }
  }

  @override
  Future<void> resetFreeRequests() async {
    await _storage.write(
      key: _freeRequestsCountKey,
      value: _maxFreeRequests.toString(),
    );
    debugPrint('Счетчик бесплатных запросов сброшен до: $_maxFreeRequests');
  }

  @override
  Future<bool> canMakeRequest() async {
    await _initializeRepository();

    try {
      // Используем метод репозитория
      final canMake = await _adaptyRepository.canMakeRequest();
      debugPrint('[AdaptyServiceImpl] canMakeRequest из репозитория: $canMake');
      return canMake;
    } catch (e) {
      debugPrint('[AdaptyServiceImpl] Ошибка проверки возможности запроса: $e');

      // Fallback на локальную логику
      final hasSubscription = await hasActiveSubscription();
      if (hasSubscription) {
        return true;
      }

      final remainingRequests = await getRemainingFreeRequests();
      return remainingRequests > 0;
    }
  }

  @override
  Future<void> activateSubscription() async {
    await _storage.write(key: _subscriptionStatusKey, value: 'active');
    debugPrint('Подписка активирована');
  }

  @override
  Future<void> deactivateSubscription() async {
    await _storage.write(key: _subscriptionStatusKey, value: 'inactive');
    debugPrint('Подписка деактивирована');
  }

  @override
  Future<List<SubscriptionProduct>> getAvailableProducts() async {
    await _initializeRepository();

    try {
      // Используем реальные продукты из Adapty
      debugPrint('[AdaptyServiceImpl] Загружаем реальные продукты из Adapty');
      final products = await _adaptyRepository.getAvailableProducts();
      debugPrint(
        '[AdaptyServiceImpl] Получено ${products.length} продуктов из Adapty',
      );
      return products;
    } catch (e) {
      debugPrint('[AdaptyServiceImpl] Ошибка загрузки продуктов: $e');

      // Fallback на тестовые продукты в debug режиме
      if (kDebugMode) {
        debugPrint(
          '[AdaptyServiceImpl] Возвращаем тестовые продукты (fallback)',
        );
        return [
          SubscriptionProduct.monthly(
            productId: 'one_month',
            price: '¥18.9',
            priceAmountMicros: 18900000,
            currencyCode: 'CNY',
            hasFreeTrial: true,
            freeTrialDays: 3,
          ).copyWith(
            title: '1个月',
            description: '在1个月 ¥18.9 然后 ¥28',
            originalPrice: '¥28',
            discountPercentage: 32,
          ),
          const SubscriptionProduct(
            productId: 'three_months',
            title: '3个月',
            description: '¥19.3每月',
            price: '¥58',
            priceAmountMicros: 58000000,
            currencyCode: 'CNY',
            subscriptionPeriod: 'quarterly',
            hasFreeTrial: false,
            pricePerPeriod: '¥58/3个月',
          ),
          SubscriptionProduct.yearly(
            productId: 'annual',
            price: '¥138',
            priceAmountMicros: 138000000,
            currencyCode: 'CNY',
            discountPercentage: 39,
          ),
        ];
      }

      return [];
    }
  }

  @override
  Future<bool> purchaseSubscription(String productId) async {
    await _initializeRepository();

    try {
      debugPrint(
        '[AdaptyServiceImpl] Покупка подписки через Adapty: $productId',
      );

      // Используем реальную покупку через Adapty
      final success = await _adaptyRepository.purchaseSubscription(productId);

      if (success) {
        debugPrint(
          '[AdaptyServiceImpl] Покупка через Adapty завершена успешно',
        );
        // Дополнительно сохраняем в локальное хранение для совместимости
        await activateSubscription();
        return true;
      } else {
        debugPrint('[AdaptyServiceImpl] Покупка через Adapty не удалась');
        return false;
      }
    } catch (e) {
      debugPrint('[AdaptyServiceImpl] Ошибка покупки через Adapty: $e');

      // Fallback на симуляцию в debug режиме
      if (kDebugMode) {
        debugPrint('[AdaptyServiceImpl] Симулируем покупку (fallback)');
        await Future.delayed(const Duration(seconds: 2));
        await activateSubscription();
        return true;
      }

      return false;
    }
  }

  @override
  Future<bool> restorePurchases() async {
    await _initializeRepository();

    try {
      debugPrint('[AdaptyServiceImpl] Восстановление покупок через Adapty');

      // Используем реальное восстановление через Adapty
      final success = await _adaptyRepository.restorePurchases();

      if (success) {
        debugPrint('[AdaptyServiceImpl] Покупки успешно восстановлены');
        // Дополнительно сохраняем в локальное хранение для совместимости
        await activateSubscription();
        return true;
      } else {
        debugPrint('[AdaptyServiceImpl] Активные покупки не найдены');
        return false;
      }
    } catch (e) {
      debugPrint('[AdaptyServiceImpl] Ошибка восстановления покупок: $e');
      return false;
    }
  }

  /// Метод для тестирования - устанавливает конкретное количество бесплатных запросов
  Future<void> setFreeRequestsCount(int count) async {
    if (kDebugMode) {
      await _storage.write(key: _freeRequestsCountKey, value: count.toString());
      debugPrint('Установлено количество бесплатных запросов: $count');
    }
  }
}
