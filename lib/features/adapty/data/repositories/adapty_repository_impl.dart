import 'package:adapty_flutter/adapty_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:zhi_ming/features/adapty/domain/models/subscription_product.dart';
import 'package:zhi_ming/features/adapty/domain/models/subscription_status.dart';
import 'package:zhi_ming/features/adapty/domain/repositories/adapty_repository.dart';

/// Реализация репозитория для работы с Adapty SDK
/// Интегрирует все функции Adapty для управления подписками
class AdaptyRepositoryImpl implements AdaptyRepository {
  static const _storage = FlutterSecureStorage();

  // Ключи для локального хранения
  static const String _freeRequestsCountKey = 'free_requests_count';
  static const String _subscriptionStatusKey = 'subscription_status';
  static const String _paywallPlacementId = 'zhi-ming-placement';

  // Константы
  static const int _maxFreeRequests = kDebugMode ? 5 : 20;
  static const String _premiumAccessLevel = 'premium';

  @override
  Future<void> initialize() async {
    try {
      debugPrint('[AdaptyRepositoryImpl] Инициализация репозитория...');

      // Adapty SDK уже активирован в main.dart, здесь только инициализируем локальные данные

      // Инициализируем счетчик бесплатных запросов, если он еще не установлен
      final currentCount = await _getRemainingFreeRequests();
      if (currentCount == _maxFreeRequests) {
        final savedCount = await _storage.read(key: _freeRequestsCountKey);
        if (savedCount == null) {
          await _storage.write(
            key: _freeRequestsCountKey,
            value: _maxFreeRequests.toString(),
          );
          debugPrint(
            '[AdaptyRepositoryImpl] Установлен начальный счетчик бесплатных запросов: $_maxFreeRequests',
          );
        }
      }

      debugPrint('[AdaptyRepositoryImpl] Репозиторий успешно инициализирован');
    } catch (e) {
      debugPrint('[AdaptyRepositoryImpl] Ошибка инициализации репозитория: $e');
      rethrow;
    }
  }

  @override
  Future<SubscriptionStatus> getSubscriptionStatus() async {
    try {
      debugPrint('[AdaptyRepositoryImpl] Получение статуса подписки...');

      // Получаем информацию о подписке из Adapty
      final profile = await Adapty().getProfile();
      final accessLevels = profile.accessLevels;

      // Проверяем активную подписку (предполагаем access level "premium")
      final premiumAccess = accessLevels[_premiumAccessLevel];
      final isActive = premiumAccess?.isActive ?? false;

      final remainingFreeRequests = await _getRemainingFreeRequests();

      if (isActive) {
        debugPrint('[AdaptyRepositoryImpl] Найдена активная подписка');
        return SubscriptionStatus.premium(
          expirationDate:
              premiumAccess!.expiresAt ??
              DateTime.now().add(const Duration(days: 365)),
          subscriptionType: _getSubscriptionType(premiumAccess),
        );
      } else {
        debugPrint(
          '[AdaptyRepositoryImpl] Активная подписка не найдена, используем бесплатный режим',
        );
        return SubscriptionStatus.free(
          remainingFreeRequests: remainingFreeRequests,
          maxFreeRequests: _maxFreeRequests,
        );
      }
    } on Exception catch (e) {
      debugPrint(
        '[AdaptyRepositoryImpl] Ошибка получения статуса подписки: $e',
      );

      // В случае ошибки возвращаем статус бесплатного пользователя
      final remainingFreeRequests = await _getRemainingFreeRequests();
      return SubscriptionStatus.free(
        remainingFreeRequests: remainingFreeRequests,
        maxFreeRequests: _maxFreeRequests,
      );
    }
  }

  @override
  Future<List<SubscriptionProduct>> getAvailableProducts() async {
    try {
      debugPrint('[AdaptyRepositoryImpl] Получение доступных продуктов...');
      debugPrint(
        '[AdaptyRepositoryImpl] Используется placement ID: $_paywallPlacementId',
      );

      // Получаем paywall с продуктами
      final paywall = await Adapty().getPaywall(
        placementId: _paywallPlacementId,
      );

      debugPrint(
        '[AdaptyRepositoryImpl] Paywall получен: ${paywall.placementId}',
      );
      debugPrint(
        '[AdaptyRepositoryImpl] Paywall revision: ${paywall.revision}',
      );

      final products = await Adapty().getPaywallProducts(paywall: paywall);

      debugPrint(
        '[AdaptyRepositoryImpl] Получено ${products.length} сырых продуктов от Adapty',
      );

      if (products.isEmpty) {
        debugPrint(
          '[AdaptyRepositoryImpl] ⚠️ Paywall не содержит продуктов! Проверьте настройки в Adapty Dashboard',
        );
        debugPrint(
          '[AdaptyRepositoryImpl] 📋 Placement ID: $_paywallPlacementId',
        );
        debugPrint('[AdaptyRepositoryImpl] 🔄 Revision: ${paywall.revision}');
      }

      final subscriptionProducts = <SubscriptionProduct>[];

      for (final product in products) {
        debugPrint(
          '[AdaptyRepositoryImpl] Обработка продукта: ${product.vendorProductId}',
        );
        final subscriptionProduct = _mapAdaptyProductToSubscriptionProduct(
          product,
        );
        if (subscriptionProduct != null) {
          subscriptionProducts.add(subscriptionProduct);
          debugPrint(
            '[AdaptyRepositoryImpl] ✅ Продукт успешно добавлен: ${subscriptionProduct.title}',
          );
        } else {
          debugPrint(
            '[AdaptyRepositoryImpl] ❌ Продукт не удалось преобразовать: ${product.vendorProductId}',
          );
        }
      }

      debugPrint(
        '[AdaptyRepositoryImpl] Итого найдено ${subscriptionProducts.length} продуктов',
      );
      return subscriptionProducts;
    } on Exception catch (e) {
      debugPrint('[AdaptyRepositoryImpl] Ошибка получения продуктов: $e');

      // Возвращаем заглушки для тестирования
      debugPrint('[AdaptyRepositoryImpl] 🔄 Возвращаем mock продукты');
      return _getMockProducts();
    }
  }

  @override
  Future<bool> purchaseSubscription(String productId) async {
    try {
      debugPrint('[AdaptyRepositoryImpl] Покупка подписки: $productId');

      // Получаем paywall и продукты
      final paywall = await Adapty().getPaywall(
        placementId: _paywallPlacementId,
      );
      final products = await Adapty().getPaywallProducts(paywall: paywall);

      final product = products.firstWhere(
        (p) => p.vendorProductId == productId,
        orElse: () => throw Exception('Продукт не найден: $productId'),
      );

      // Совершаем покупку
      final result = await Adapty().makePurchase(product: product);

      // Проверяем результат покупки
      switch (result) {
        case AdaptyPurchaseResultSuccess(profile: final profile):
          if (profile.accessLevels[_premiumAccessLevel]?.isActive ?? false) {
            debugPrint('[AdaptyRepositoryImpl] Покупка успешно завершена');
            await _trackPurchaseEvent(productId);
            return true;
          } else {
            debugPrint(
              '[AdaptyRepositoryImpl] Покупка не активировала подписку',
            );
            return false;
          }
        case AdaptyPurchaseResultUserCancelled():
          debugPrint('[AdaptyRepositoryImpl] Покупка отменена пользователем');
          return false;
        case AdaptyPurchaseResultPending():
          debugPrint('[AdaptyRepositoryImpl] Покупка в ожидании');
          return false;
      }
    } on Exception catch (e) {
      debugPrint('[AdaptyRepositoryImpl] Ошибка покупки: $e');
      return false;
    }
  }

  @override
  Future<bool> restorePurchases() async {
    try {
      debugPrint('[AdaptyRepositoryImpl] Восстановление покупок...');

      final profile = await Adapty().restorePurchases();
      final isActive =
          profile.accessLevels[_premiumAccessLevel]?.isActive ?? false;

      if (isActive) {
        debugPrint('[AdaptyRepositoryImpl] Покупки успешно восстановлены');
        await trackEvent('restore_purchases_success');
      } else {
        debugPrint('[AdaptyRepositoryImpl] Активные покупки не найдены');
        await trackEvent('restore_purchases_no_active');
      }

      return isActive;
    } on Exception catch (e) {
      debugPrint('[AdaptyRepositoryImpl] Ошибка восстановления покупок: $e');
      await trackEvent(
        'restore_purchases_error',
        parameters: {'error': e.toString()},
      );
      return false;
    }
  }

  @override
  Future<void> decrementFreeRequests() async {
    try {
      final currentCount = await _getRemainingFreeRequests();
      if (currentCount > 0) {
        final newCount = currentCount - 1;
        await _storage.write(
          key: _freeRequestsCountKey,
          value: newCount.toString(),
        );
        debugPrint(
          '[AdaptyRepositoryImpl] Счетчик бесплатных запросов уменьшен до: $newCount',
        );

        // Отправляем событие об использовании бесплатного запроса
        await trackEvent(
          'free_request_used',
          parameters: {'remaining_requests': newCount},
        );
      }
    } on Exception catch (e) {
      debugPrint('[AdaptyRepositoryImpl] Ошибка уменьшения счетчика: $e');
    }
  }

  @override
  Future<bool> canMakeRequest() async {
    try {
      final status = await getSubscriptionStatus();
      final canMake = status.canMakeRequest;

      debugPrint(
        '[AdaptyRepositoryImpl] Проверка возможности запроса: $canMake',
      );
      debugPrint(
        '[AdaptyRepositoryImpl] Статус подписки: ${status.hasPremiumAccess}',
      );
      debugPrint(
        '[AdaptyRepositoryImpl] Оставшиеся запросы: ${status.remainingFreeRequests}',
      );

      return canMake;
    } on Exception catch (e) {
      debugPrint(
        '[AdaptyRepositoryImpl] Ошибка проверки возможности запроса: $e',
      );
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>?> getPaywallConfiguration() async {
    try {
      debugPrint('[AdaptyRepositoryImpl] Получение конфигурации paywall...');

      final paywall = await Adapty().getPaywall(
        placementId: _paywallPlacementId,
      );

      return {
        'placement_id': paywall.placementId,
        'revision': paywall.revision,
        'remote_config': paywall.remoteConfig,
      };
    } on Exception catch (e) {
      debugPrint(
        '[AdaptyRepositoryImpl] Ошибка получения конфигурации paywall: $e',
      );
      return null;
    }
  }

  @override
  Future<void> trackEvent(
    String eventName, {
    Map<String, dynamic>? parameters,
  }) async {
    try {
      debugPrint('[AdaptyRepositoryImpl] Отправка события: $eventName');

      // В Adapty 3.x события отправляются через logShowPaywall и другие специфичные методы
      // Для кастомных событий используем updateProfile с кастомными атрибутами
      if (parameters != null) {
        final builder =
            AdaptyProfileParametersBuilder()
              ..setCustomStringAttribute('last_event', eventName)
              ..setCustomStringAttribute(
                DateTime.now().toIso8601String(),
                'last_event_time',
              );

        for (final entry in parameters.entries) {
          builder.setCustomStringAttribute(
            entry.value.toString(),
            'event_${entry.key}',
          );
        }

        await Adapty().updateProfile(builder.build());
      }

      debugPrint('[AdaptyRepositoryImpl] Событие отправлено: $eventName');
    } on Exception catch (e) {
      debugPrint('[AdaptyRepositoryImpl] Ошибка отправки события: $e');
    }
  }

  @override
  Future<void> setUserAttributes(Map<String, dynamic> attributes) async {
    try {
      debugPrint('[AdaptyRepositoryImpl] Установка атрибутов пользователя...');

      final builder = AdaptyProfileParametersBuilder();

      // Устанавливаем стандартные атрибуты
      if (attributes.containsKey('email')) {
        builder.setEmail(attributes['email'] as String);
      }
      if (attributes.containsKey('phone')) {
        builder.setPhoneNumber(attributes['phone'] as String);
      }
      if (attributes.containsKey('first_name')) {
        builder.setFirstName(attributes['first_name'] as String);
      }
      if (attributes.containsKey('last_name')) {
        builder.setLastName(attributes['last_name'] as String);
      }

      // Устанавливаем кастомные атрибуты
      for (final entry in attributes.entries) {
        if (![
          'email',
          'phone',
          'first_name',
          'last_name',
        ].contains(entry.key)) {
          if (entry.value is String) {
            builder.setCustomStringAttribute(entry.value as String, entry.key);
          } else if (entry.value is num) {
            builder.setCustomDoubleAttribute(
              (entry.value as num).toDouble(),
              entry.key,
            );
          } else {
            builder.setCustomStringAttribute(entry.value.toString(), entry.key);
          }
        }
      }

      await Adapty().updateProfile(builder.build());
      debugPrint('[AdaptyRepositoryImpl] Атрибуты пользователя установлены');
    } on Exception catch (e) {
      debugPrint('[AdaptyRepositoryImpl] Ошибка установки атрибутов: $e');
    }
  }

  @override
  Future<String?> getUserId() async {
    try {
      final profile = await Adapty().getProfile();
      return profile.profileId;
    } on Exception catch (e) {
      debugPrint('[AdaptyRepositoryImpl] Ошибка получения ID пользователя: $e');
      return null;
    }
  }

  @override
  Future<void> logout() async {
    try {
      debugPrint('[AdaptyRepositoryImpl] Выход пользователя...');

      await Adapty().logout();

      // Очищаем локальные данные
      await _storage.delete(key: _subscriptionStatusKey);
      await _storage.write(
        key: _freeRequestsCountKey,
        value: _maxFreeRequests.toString(),
      );

      debugPrint('[AdaptyRepositoryImpl] Пользователь вышел из системы');
    } on Exception catch (e) {
      debugPrint('[AdaptyRepositoryImpl] Ошибка выхода: $e');
    }
  }

  // Приватные методы

  /// Получение количества оставшихся бесплатных запросов
  Future<int> _getRemainingFreeRequests() async {
    final countStr = await _storage.read(key: _freeRequestsCountKey);
    if (countStr == null) {
      await _storage.write(
        key: _freeRequestsCountKey,
        value: _maxFreeRequests.toString(),
      );
      return _maxFreeRequests;
    }
    return int.tryParse(countStr) ?? _maxFreeRequests;
  }

  /// Определение типа подписки по access level
  String _getSubscriptionType(AdaptyAccessLevel accessLevel) {
    // Логика определения типа подписки на основе данных Adapty
    // Можно использовать vendorProductId или другие поля
    return 'premium'; // Заглушка
  }

  /// Маппинг продукта Adapty в нашу модель
  SubscriptionProduct? _mapAdaptyProductToSubscriptionProduct(
    AdaptyPaywallProduct product,
  ) {
    try {
      final productId = product.vendorProductId;
      final basePrice = product.price.localizedString;
      final currencyCode = product.price.currencyCode;
      final amount = product.price.amount;

      debugPrint(
        '[AdaptyRepositoryImpl] 🔍 Детали продукта: ${product.subscription?.offer?.identifier.type}',
      );
      debugPrint(
        '[AdaptyRepositoryImpl] 🔍 Детали продукта: ${product.subscription?.offer?.phases}',
      );

      // Проверяем на null значения
      if (currencyCode == null || basePrice == null) {
        debugPrint(
          '[AdaptyRepositoryImpl] ❌ Отсутствует currencyCode или price для продукта: $productId',
        );
        return null;
      }

      // Проверяем наличие скидочного предложения
      bool hasDiscount = false;
      String? discountPrice;
      String? originalPrice;
      int? discountPriceAmountMicros;

      final subscription = product.subscription;
      final offer = subscription?.offer;

      if (offer != null &&
          offer.identifier.type == AdaptySubscriptionOfferType.introductory) {
        final phases = offer.phases;
        if (phases.isNotEmpty) {
          // Есть скидочное предложение
          hasDiscount = true;
          final firstPhase = phases.first;
          discountPrice = firstPhase.price.localizedString;
          discountPriceAmountMicros =
              (firstPhase.price.amount * 1000000).toInt();
          originalPrice = basePrice; // Основная цена становится оригинальной

          debugPrint(
            '[AdaptyRepositoryImpl] 💸 Найдена скидка: $discountPrice (оригинал: $originalPrice)',
          );
        }
      }

      // Определяем финальную цену и amount micros
      final finalPrice = hasDiscount ? discountPrice! : basePrice;
      final finalPriceAmountMicros =
          hasDiscount ? discountPriceAmountMicros! : (amount * 1000000).toInt();

      debugPrint(
        '[AdaptyRepositoryImpl] 💰 Final price: $finalPrice, amount micros: $finalPriceAmountMicros',
      );

      // Определяем тип подписки по ID продукта
      if (productId.toLowerCase().contains('one_month')) {
        debugPrint('[AdaptyRepositoryImpl] 📅 Определен как месячная подписка');
        final baseProduct = SubscriptionProduct.monthly(
          productId: productId,
          price: finalPrice,
          priceAmountMicros: finalPriceAmountMicros,
          currencyCode: currencyCode,
        );

        return hasDiscount
            ? baseProduct.copyWith(
              originalPrice: originalPrice,
              isRecommended: true,
              description: '首月特惠 然后 $originalPrice',
            )
            : baseProduct;
      } else if (productId.toLowerCase().contains('annual')) {
        debugPrint('[AdaptyRepositoryImpl] 📅 Определен как годовая подписка');
        final baseProduct = SubscriptionProduct.yearly(
          productId: productId,
          price: finalPrice,
          priceAmountMicros: finalPriceAmountMicros,
          currencyCode: currencyCode,
        );

        return hasDiscount
            ? baseProduct.copyWith(
              originalPrice: originalPrice,
              isRecommended: true,
              description: '首年特惠 然后 $originalPrice',
            )
            : baseProduct;
      } else if (productId.toLowerCase().contains('three_months')) {
        debugPrint(
          '[AdaptyRepositoryImpl] 📅 Определен как трехмесячная подписка',
        );
        return SubscriptionProduct(
          productId: productId,
          title: '3个月',
          description: hasDiscount ? '首月特惠' : '¥19.3每月',
          price: finalPrice,
          priceAmountMicros: finalPriceAmountMicros,
          currencyCode: currencyCode,
          subscriptionPeriod: 'quarterly',
          hasFreeTrial: false,
          pricePerPeriod: finalPrice,
          originalPrice: hasDiscount ? originalPrice : null,
          isRecommended: hasDiscount,
        );
      } else {
        // Если не можем определить тип, создаем базовый продукт
        debugPrint(
          '[AdaptyRepositoryImpl] ⚠️ Неизвестный тип продукта, создаем базовый: $productId',
        );
        return SubscriptionProduct(
          productId: productId,
          title: '订阅',
          description: hasDiscount ? '特惠价格' : '高级订阅',
          price: finalPrice,
          priceAmountMicros: finalPriceAmountMicros,
          currencyCode: currencyCode,
          subscriptionPeriod: 'unknown',
          hasFreeTrial: false,
          pricePerPeriod: finalPrice,
          originalPrice: hasDiscount ? originalPrice : null,
          isRecommended: hasDiscount,
        );
      }
    } on Exception catch (e) {
      debugPrint('[AdaptyRepositoryImpl] ❌ Ошибка маппинга продукта: $e');
      return null;
    }
  }

  /// Получение заглушек продуктов для тестирования
  List<SubscriptionProduct> _getMockProducts() {
    return [
      SubscriptionProduct.monthly(
        productId: 'one_month',
        price: '¥68',
        priceAmountMicros: 68000000,
        currencyCode: 'CNY',
      ),
      const SubscriptionProduct(
        productId: 'three_months',
        title: '3个月',
        description: '按季度订阅，享受优惠',
        price: '¥188',
        priceAmountMicros: 188000000,
        currencyCode: 'CNY',
        subscriptionPeriod: 'quarterly',
        hasFreeTrial: false,
        pricePerPeriod: '¥188/3个月',
        discountPercentage: 15,
      ),
      SubscriptionProduct.yearly(
        productId: 'annual',
        price: '¥588',
        priceAmountMicros: 588000000,
        currencyCode: 'CNY',
        discountPercentage: 30,
      ),
    ];
  }

  /// Отправка события о покупке
  Future<void> _trackPurchaseEvent(String productId) async {
    await trackEvent(
      'subscription_purchased',
      parameters: {
        'product_id': productId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }
}
