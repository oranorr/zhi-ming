import 'dart:io';
import 'package:adapty_flutter/adapty_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:zhi_ming/features/adapty/domain/models/subscription_product.dart';
import 'package:zhi_ming/features/adapty/domain/models/subscription_status.dart';
import 'package:zhi_ming/features/adapty/domain/repositories/adapty_repository.dart';

/// Реализация репозитория для работы с Adapty SDK
/// Интегрирует все функции Adapty для управления подписками
/// Кэширует продукты для быстрого доступа без повторной загрузки
class AdaptyRepositoryImpl implements AdaptyRepository {
  // Singleton pattern
  AdaptyRepositoryImpl._();
  static AdaptyRepositoryImpl? _instance;
  static AdaptyRepositoryImpl get instance =>
      _instance ??= AdaptyRepositoryImpl._();

  static const _storage = FlutterSecureStorage();

  // Ключи для локального хранения
  static const String _freeRequestsCountKey =
      'free_requests_count'; // DEPRECATED - оставляем для совместимости
  static const String _hasUsedFreeReadingKey =
      'has_used_free_reading'; // [AdaptyRepositoryImpl] Использовал ли бесплатное гадание
  static const String _followUpQuestionsCountKey =
      'follow_up_questions_count'; // [AdaptyRepositoryImpl] Счетчик фоллоу-ап вопросов
  static const String _subscriptionStatusKey = 'subscription_status';
  static const String _emulatorSubscriptionKey =
      'emulator_subscription_active'; // [AdaptyRepositoryImpl] Ключ для хранения фейковой подписки на эмуляторе
  static const String _emulatorSubscriptionProductKey =
      'emulator_subscription_product'; // [AdaptyRepositoryImpl] Ключ для хранения ID купленного продукта на эмуляторе
  static const String _emulatorSubscriptionDateKey =
      'emulator_subscription_date'; // [AdaptyRepositoryImpl] Ключ для хранения даты покупки на эмуляторе
  static const String _paywallPlacementId = 'zhi-ming-placement';

  // Константы
  static const int _maxFreeRequests =
      kDebugMode ? 5 : 20; // DEPRECATED - оставляем для совместимости
  static const int _maxFollowUpQuestions =
      kDebugMode
          ? 5
          : 20; // [AdaptyRepositoryImpl] Максимальное количество фоллоу-ап вопросов
  static const String _premiumAccessLevel = 'premium';

  bool _isInitialized = false;

  // [AdaptyRepositoryImpl] Кэш для хранения предзагруженных продуктов
  List<SubscriptionProduct> _cachedProducts = [];
  bool _productsLoaded = false;

  /// Проверка, работает ли приложение на эмуляторе
  /// [AdaptyRepositoryImpl] Определяем эмулятор для Android и iOS
  bool get _isRunningOnEmulator {
    try {
      if (Platform.isAndroid) {
        // [AdaptyRepositoryImpl] Android эмулятор определяется по переменным окружения и системным свойствам
        final isEmulator =
            Platform.environment.containsKey('ANDROID_EMULATOR') ||
            Platform.environment['ANDROID_EMULATOR'] == 'true';
        debugPrint(
          '[AdaptyRepositoryImpl] 🤖 Android эмулятор проверка: $isEmulator',
        );
        return isEmulator;
      } else if (Platform.isIOS) {
        // [AdaptyRepositoryImpl] iOS симулятор определяется ТОЛЬКО по переменным симулятора
        final hasSimulatorEnv =
            Platform.environment.containsKey('SIMULATOR_DEVICE_NAME') ||
            Platform.environment['SIMULATOR_DEVICE_NAME'] != null;

        // [AdaptyRepositoryImpl] Дополнительная проверка через другие переменные симулятора
        final hasSimulatorRoot = Platform.environment.containsKey(
          'SIMULATOR_ROOT',
        );
        final hasSimulatorUdid = Platform.environment.containsKey(
          'SIMULATOR_UDID',
        );

        // [AdaptyRepositoryImpl] Проверяем переменную IPHONE_SIMULATOR_ROOT (старые версии Xcode)
        final hasLegacySimulatorRoot = Platform.environment.containsKey(
          'IPHONE_SIMULATOR_ROOT',
        );

        // [AdaptyRepositoryImpl] НЕ используем kDebugMode для определения симулятора!
        // Реальные устройства могут работать в debug режиме
        final isSimulator =
            hasSimulatorEnv ||
            hasSimulatorRoot ||
            hasSimulatorUdid ||
            hasLegacySimulatorRoot;

        debugPrint('[AdaptyRepositoryImpl] 🤖 iOS симулятор проверки:');
        debugPrint(
          '[AdaptyRepositoryImpl] 🤖   SIMULATOR_DEVICE_NAME: $hasSimulatorEnv',
        );
        debugPrint(
          '[AdaptyRepositoryImpl] 🤖   SIMULATOR_ROOT: $hasSimulatorRoot',
        );
        debugPrint(
          '[AdaptyRepositoryImpl] 🤖   SIMULATOR_UDID: $hasSimulatorUdid',
        );
        debugPrint(
          '[AdaptyRepositoryImpl] 🤖   IPHONE_SIMULATOR_ROOT: $hasLegacySimulatorRoot',
        );
        debugPrint(
          '[AdaptyRepositoryImpl] 🤖   kDebugMode: $kDebugMode (НЕ используется для определения)',
        );
        debugPrint(
          '[AdaptyRepositoryImpl] 🤖   Итоговый результат: $isSimulator',
        );

        return isSimulator;
      }
      debugPrint(
        '[AdaptyRepositoryImpl] 🤖 Неизвестная платформа, считаем НЕ эмулятором',
      );
      return false;
    } catch (e) {
      // [AdaptyRepositoryImpl] В случае ошибки считаем что НЕ эмулятор
      debugPrint('[AdaptyRepositoryImpl] Ошибка определения эмулятора: $e');
      return false;
    }
  }

  /// Проверка, инициализирован ли репозиторий
  bool get isInitialized => _isInitialized;

  /// Проверка, загружены ли продукты в кэш
  /// [AdaptyRepositoryImpl] Публичный геттер для проверки состояния загрузки продуктов
  bool get areProductsLoaded => _productsLoaded;

  /// Получение кэшированных продуктов без сетевого запроса
  /// [AdaptyRepositoryImpl] Быстрый доступ к предзагруженным продуктам для UI
  List<SubscriptionProduct> get cachedProducts =>
      List.unmodifiable(_cachedProducts);

  /// Сброс состояния репозитория (для тестирования)
  @visibleForTesting
  void reset() {
    _isInitialized = false;
    _productsLoaded = false;
    _cachedProducts.clear();
    _instance = null;
  }

  @override
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('[AdaptyRepositoryImpl] Adapty уже инициализирован');
      return;
    }

    try {
      debugPrint('[AdaptyRepositoryImpl] Инициализация репозитория...');

      // Adapty SDK уже активирован в main.dart, здесь только инициализируем локальные данные

      // [AdaptyRepositoryImpl] Инициализируем старый счетчик для совместимости
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

      // [AdaptyRepositoryImpl] Инициализируем новую систему счетчиков
      await _initializeNewCounterSystem();

      // [AdaptyRepositoryImpl] Предзагружаем продукты при инициализации
      await _preloadProducts();

      _isInitialized = true;
      debugPrint('[AdaptyRepositoryImpl] Репозиторий успешно инициализирован');
    } catch (e) {
      debugPrint('[AdaptyRepositoryImpl] Ошибка инициализации репозитория: $e');
      rethrow;
    }
  }

  /// Инициализация новой системы счетчиков
  /// [AdaptyRepositoryImpl] Устанавливает начальные значения для новых пользователей
  Future<void> _initializeNewCounterSystem() async {
    // Проверяем флаг использования бесплатного гадания
    final hasUsedFreeReadingString = await _storage.read(
      key: _hasUsedFreeReadingKey,
    );
    if (hasUsedFreeReadingString == null) {
      await _storage.write(key: _hasUsedFreeReadingKey, value: 'false');
      debugPrint(
        '[AdaptyRepositoryImpl] Установлен флаг бесплатного гадания: false',
      );
    }

    // Проверяем счетчик фоллоу-ап вопросов
    final followUpCountString = await _storage.read(
      key: _followUpQuestionsCountKey,
    );
    if (followUpCountString == null) {
      await _storage.write(
        key: _followUpQuestionsCountKey,
        value: _maxFollowUpQuestions.toString(),
      );
      debugPrint(
        '[AdaptyRepositoryImpl] Установлен счетчик фоллоу-ап вопросов: $_maxFollowUpQuestions',
      );
    }
  }

  /// Предзагрузка продуктов при инициализации репозитория
  /// [AdaptyRepositoryImpl] Загружает продукты один раз при старте приложения
  Future<void> _preloadProducts() async {
    if (_productsLoaded) {
      debugPrint('[AdaptyRepositoryImpl] Продукты уже загружены в кэш');
      return;
    }

    try {
      debugPrint('[AdaptyRepositoryImpl] 🚀 Предзагрузка продуктов...');

      // [AdaptyRepositoryImpl] Загружаем продукты и сохраняем в кэш
      final products = await _fetchProductsFromAdapty();
      _cachedProducts = products;
      _productsLoaded = true;

      debugPrint(
        '[AdaptyRepositoryImpl] ✅ Предзагружено ${_cachedProducts.length} продуктов в кэш',
      );
    } catch (e) {
      debugPrint('[AdaptyRepositoryImpl] ❌ Ошибка предзагрузки продуктов: $e');

      // [AdaptyRepositoryImpl] В случае ошибки используем mock продукты
      _cachedProducts = _getMockProducts();
      _productsLoaded = true;

      debugPrint(
        '[AdaptyRepositoryImpl] 🔄 Использованы mock продукты: ${_cachedProducts.length}',
      );
    }
  }

  /// Принудительное обновление кэша продуктов
  /// [AdaptyRepositoryImpl] Метод для обновления продуктов по требованию
  @override
  Future<void> refreshProducts() async {
    try {
      debugPrint(
        '[AdaptyRepositoryImpl] 🔄 Принудительное обновление продуктов...',
      );

      final products = await _fetchProductsFromAdapty();
      _cachedProducts = products;

      debugPrint(
        '[AdaptyRepositoryImpl] ✅ Кэш продуктов обновлен: ${_cachedProducts.length}',
      );
    } catch (e) {
      debugPrint('[AdaptyRepositoryImpl] ❌ Ошибка обновления продуктов: $e');
      // [AdaptyRepositoryImpl] Оставляем старый кэш при ошибке
    }
  }

  /// Загрузка продуктов непосредственно из Adapty
  /// [AdaptyRepositoryImpl] Приватный метод для получения продуктов из Adapty SDK
  Future<List<SubscriptionProduct>> _fetchProductsFromAdapty() async {
    debugPrint('[AdaptyRepositoryImpl] Получение продуктов из Adapty...');
    debugPrint(
      '[AdaptyRepositoryImpl] Используется placement ID: $_paywallPlacementId',
    );

    // Получаем paywall с продуктами
    final paywall = await Adapty().getPaywall(placementId: _paywallPlacementId);

    debugPrint(
      '[AdaptyRepositoryImpl] Paywall получен: ${paywall.placementId}',
    );
    debugPrint('[AdaptyRepositoryImpl] Paywall revision: ${paywall.revision}');

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
  }

  @override
  Future<List<SubscriptionProduct>> getAvailableProducts() async {
    // [AdaptyRepositoryImpl] Теперь просто возвращаем кэшированные продукты
    if (!_productsLoaded) {
      debugPrint(
        '[AdaptyRepositoryImpl] ⚠️ Продукты еще не загружены, выполняем загрузку...',
      );
      await _preloadProducts();
    }

    debugPrint(
      '[AdaptyRepositoryImpl] 📦 Возвращаем ${_cachedProducts.length} кэшированных продуктов',
    );
    return List.from(_cachedProducts);
  }

  @override
  Future<SubscriptionStatus> getSubscriptionStatus() async {
    try {
      debugPrint('[AdaptyRepositoryImpl] Получение статуса подписки...');

      // [AdaptyRepositoryImpl] Получаем новые данные о счетчиках
      final hasUsedFreeReading = await _getHasUsedFreeReading();
      final remainingFollowUpQuestions = await _getRemainingFollowUpQuestions();

      // [AdaptyRepositoryImpl] Проверяем фейковую подписку на эмуляторе в первую очередь
      if (_isRunningOnEmulator) {
        final emulatorSubscriptionActive = await _storage.read(
          key: _emulatorSubscriptionKey,
        );
        if (emulatorSubscriptionActive == 'true') {
          final productId =
              await _storage.read(key: _emulatorSubscriptionProductKey) ??
              'emulator_premium';
          final dateString = await _storage.read(
            key: _emulatorSubscriptionDateKey,
          );
          final purchaseDate =
              dateString != null
                  ? DateTime.tryParse(dateString)
                  : DateTime.now();

          debugPrint(
            '[AdaptyRepositoryImpl] 🤖 Найдена активная ФЕЙКОВАЯ подписка на эмуляторе: $productId',
          );

          // [AdaptyRepositoryImpl] Возвращаем premium статус с датой истечения через год от покупки
          return SubscriptionStatus.premium(
            expirationDate: (purchaseDate ?? DateTime.now()).add(
              const Duration(days: 365),
            ),
            subscriptionType: _getEmulatorSubscriptionType(productId),
          );
        }
      }

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
          hasUsedFreeReading: hasUsedFreeReading,
          remainingFollowUpQuestions: remainingFollowUpQuestions,
          maxFollowUpQuestions: _maxFollowUpQuestions,
        );
      }
    } on Exception catch (e) {
      debugPrint(
        '[AdaptyRepositoryImpl] Ошибка получения статуса подписки: $e',
      );

      // [AdaptyRepositoryImpl] Получаем данные для обработки ошибки
      final hasUsedFreeReading = await _getHasUsedFreeReading();
      final remainingFollowUpQuestions = await _getRemainingFollowUpQuestions();

      // [AdaptyRepositoryImpl] В случае ошибки на эмуляторе все равно проверяем фейковую подписку
      if (_isRunningOnEmulator) {
        final emulatorSubscriptionActive = await _storage.read(
          key: _emulatorSubscriptionKey,
        );
        if (emulatorSubscriptionActive == 'true') {
          final productId =
              await _storage.read(key: _emulatorSubscriptionProductKey) ??
              'emulator_premium';
          debugPrint(
            '[AdaptyRepositoryImpl] 🤖 Используем фейковую подписку на эмуляторе при ошибке: $productId',
          );

          return SubscriptionStatus.premium(
            expirationDate: DateTime.now().add(const Duration(days: 365)),
            subscriptionType: _getEmulatorSubscriptionType(productId),
          );
        }
      }

      // В случае ошибки возвращаем статус бесплатного пользователя
      final remainingFreeRequests = await _getRemainingFreeRequests();
      return SubscriptionStatus.free(
        remainingFreeRequests: remainingFreeRequests,
        maxFreeRequests: _maxFreeRequests,
        hasUsedFreeReading: hasUsedFreeReading,
        remainingFollowUpQuestions: remainingFollowUpQuestions,
        maxFollowUpQuestions: _maxFollowUpQuestions,
      );
    }
  }

  @override
  Future<bool> purchaseSubscription(String productId) async {
    try {
      debugPrint('[AdaptyRepositoryImpl] Покупка подписки: $productId');
      debugPrint('[AdaptyRepositoryImpl] 🔍 Проверка эмулятора...');

      final isEmulator = _isRunningOnEmulator;
      debugPrint(
        '[AdaptyRepositoryImpl] 🔍 Результат проверки эмулятора: $isEmulator',
      );
      debugPrint('[AdaptyRepositoryImpl] 🔍 Platform.isIOS: ${Platform.isIOS}');
      debugPrint('[AdaptyRepositoryImpl] 🔍 kDebugMode: $kDebugMode');

      // [AdaptyRepositoryImpl] Имитация покупки на эмуляторе - сразу "покупаем" без обращения к Adapty
      if (isEmulator) {
        debugPrint(
          '[AdaptyRepositoryImpl] 🤖 ЭМУЛЯТОР: Имитируем успешную покупку подписки: $productId',
        );

        // [AdaptyRepositoryImpl] Сохраняем информацию о "купленной" подписке
        await _storage.write(key: _emulatorSubscriptionKey, value: 'true');
        await _storage.write(
          key: _emulatorSubscriptionProductKey,
          value: productId,
        );
        await _storage.write(
          key: _emulatorSubscriptionDateKey,
          value: DateTime.now().toIso8601String(),
        );

        // [AdaptyRepositoryImpl] Трекаем событие фейковой покупки
        await _trackPurchaseEvent(productId);
        await trackEvent(
          'emulator_fake_purchase',
          parameters: {
            'product_id': productId,
            'timestamp': DateTime.now().toIso8601String(),
            'platform': Platform.operatingSystem,
          },
        );

        debugPrint(
          '[AdaptyRepositoryImpl] 🤖 ЭМУЛЯТОР: Фейковая покупка успешно сохранена!',
        );
        return true;
      }

      debugPrint(
        '[AdaptyRepositoryImpl] 📱 РЕАЛЬНОЕ УСТРОЙСТВО: Выполняем реальную покупку через Adapty',
      );

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

      // [AdaptyRepositoryImpl] Очищаем фейковую подписку на эмуляторе
      if (_isRunningOnEmulator) {
        await _storage.delete(key: _emulatorSubscriptionKey);
        await _storage.delete(key: _emulatorSubscriptionProductKey);
        await _storage.delete(key: _emulatorSubscriptionDateKey);
        debugPrint(
          '[AdaptyRepositoryImpl] 🤖 ЭМУЛЯТОР: Фейковая подписка очищена при выходе',
        );
      }

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

  /// Определение типа подписки для эмулятора по product ID
  /// [AdaptyRepositoryImpl] Маппинг product ID в читаемый тип подписки для эмулятора
  String _getEmulatorSubscriptionType(String productId) {
    if (productId.toLowerCase().contains('one_month') ||
        productId.toLowerCase().contains('monthly')) {
      return 'monthly';
    } else if (productId.toLowerCase().contains('three_months') ||
        productId.toLowerCase().contains('quarterly')) {
      return 'quarterly';
    } else if (productId.toLowerCase().contains('annual') ||
        productId.toLowerCase().contains('yearly')) {
      return 'yearly';
    } else {
      return 'premium'; // [AdaptyRepositoryImpl] Дефолтный тип для неизвестных продуктов
    }
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

        // [AdaptyRepositoryImpl] Для трехмесячной подписки ВСЕГДА используем оригинальную цену
        // даже если есть introductory offer (бесплатные первые 3 дня)
        final displayPrice =
            hasDiscount && originalPrice != null ? originalPrice : finalPrice;
        final displayPriceAmountMicros =
            hasDiscount && originalPrice != null
                ? (product.price.amount * 1000000)
                    .toInt() // Используем оригинальную цену в micros
                : finalPriceAmountMicros;

        debugPrint(
          '[AdaptyRepositoryImpl] 💰 Трехмесячная подписка - отображаем цену: $displayPrice (вместо скидочной: $finalPrice)',
        );
        debugPrint(
          '[AdaptyRepositoryImpl] 💰 Трехмесячная подписка - hasDiscount: $hasDiscount, originalPrice: $originalPrice, basePrice: $basePrice',
        );

        return SubscriptionProduct(
          productId: productId,
          title: '3个月',
          description: hasDiscount ? '首月特惠' : '¥19.3每月',
          price: displayPrice,
          priceAmountMicros: displayPriceAmountMicros,
          currencyCode: currencyCode,
          subscriptionPeriod: 'quarterly',
          hasFreeTrial: false,
          pricePerPeriod: displayPrice,
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

  /// Очистка фейковой подписки на эмуляторе (для тестирования)
  /// [AdaptyRepositoryImpl] Метод для ручного сброса подписки на эмуляторе
  @visibleForTesting
  Future<void> clearEmulatorSubscription() async {
    if (_isRunningOnEmulator) {
      await _storage.delete(key: _emulatorSubscriptionKey);
      await _storage.delete(key: _emulatorSubscriptionProductKey);
      await _storage.delete(key: _emulatorSubscriptionDateKey);
      debugPrint(
        '[AdaptyRepositoryImpl] 🤖 ЭМУЛЯТОР: Фейковая подписка очищена вручную',
      );

      await trackEvent(
        'emulator_subscription_cleared',
        parameters: {
          'timestamp': DateTime.now().toIso8601String(),
          'platform': Platform.operatingSystem,
        },
      );
    } else {
      debugPrint(
        '[AdaptyRepositoryImpl] ⚠️ Попытка очистить фейковую подписку не на эмуляторе',
      );
    }
  }

  /// Получение флага использования бесплатного гадания
  /// [AdaptyRepositoryImpl] Проверяет, использовал ли пользователь свое бесплатное гадание
  Future<bool> _getHasUsedFreeReading() async {
    try {
      final hasUsedString = await _storage.read(key: _hasUsedFreeReadingKey);
      final hasUsed = hasUsedString == 'true';
      debugPrint(
        '[AdaptyRepositoryImpl] Флаг использования бесплатного гадания: $hasUsed',
      );
      return hasUsed;
    } catch (e) {
      debugPrint(
        '[AdaptyRepositoryImpl] Ошибка чтения флага бесплатного гадания: $e',
      );
      return false; // По умолчанию считаем что не использовал
    }
  }

  /// Получение количества оставшихся фоллоу-ап вопросов
  /// [AdaptyRepositoryImpl] Возвращает количество доступных фоллоу-ап вопросов
  Future<int> _getRemainingFollowUpQuestions() async {
    try {
      final countString = await _storage.read(key: _followUpQuestionsCountKey);
      final count = int.tryParse(countString ?? '0') ?? _maxFollowUpQuestions;
      debugPrint('[AdaptyRepositoryImpl] Оставшиеся фоллоу-ап вопросы: $count');
      return count;
    } catch (e) {
      debugPrint(
        '[AdaptyRepositoryImpl] Ошибка чтения счетчика фоллоу-ап вопросов: $e',
      );
      return _maxFollowUpQuestions; // По умолчанию возвращаем максимум
    }
  }

  /// Отметка использования бесплатного гадания
  /// [AdaptyRepositoryImpl] Устанавливает флаг что пользователь использовал бесплатное гадание
  @override
  Future<void> markFreeReadingAsUsed() async {
    try {
      await _storage.write(key: _hasUsedFreeReadingKey, value: 'true');
      debugPrint(
        '[AdaptyRepositoryImpl] Бесплатное гадание отмечено как использованное',
      );

      // Трекаем событие использования бесплатного гадания
      await trackEvent('free_reading_used');
    } catch (e) {
      debugPrint(
        '[AdaptyRepositoryImpl] Ошибка установки флага бесплатного гадания: $e',
      );
    }
  }

  /// Уменьшение счетчика фоллоу-ап вопросов
  /// [AdaptyRepositoryImpl] Уменьшает счетчик доступных фоллоу-ап вопросов
  @override
  Future<void> decrementFollowUpQuestions() async {
    try {
      final currentCount = await _getRemainingFollowUpQuestions();
      if (currentCount > 0) {
        final newCount = currentCount - 1;
        await _storage.write(
          key: _followUpQuestionsCountKey,
          value: newCount.toString(),
        );
        debugPrint(
          '[AdaptyRepositoryImpl] Счетчик фоллоу-ап вопросов уменьшен до: $newCount',
        );

        // Трекаем событие использования фоллоу-ап вопроса
        await trackEvent(
          'follow_up_question_used',
          parameters: {'remaining_questions': newCount},
        );
      }
    } catch (e) {
      debugPrint(
        '[AdaptyRepositoryImpl] Ошибка уменьшения счетчика фоллоу-ап вопросов: $e',
      );
    }
  }

  /// Проверка возможности начать новое гадание
  /// [AdaptyRepositoryImpl] Проверяет может ли пользователь начать новое гадание
  @override
  Future<bool> canStartNewReading() async {
    try {
      final status = await getSubscriptionStatus();
      final canStart = status.canStartNewReading;
      debugPrint(
        '[AdaptyRepositoryImpl] Может ли начать новое гадание: $canStart',
      );
      return canStart;
    } catch (e) {
      debugPrint(
        '[AdaptyRepositoryImpl] Ошибка проверки возможности нового гадания: $e',
      );
      return false;
    }
  }

  /// Проверка возможности задать фоллоу-ап вопрос
  /// [AdaptyRepositoryImpl] Проверяет может ли пользователь задать фоллоу-ап вопрос
  @override
  Future<bool> canAskFollowUpQuestion() async {
    try {
      final status = await getSubscriptionStatus();
      final canAsk = status.canAskFollowUpQuestion;
      debugPrint(
        '[AdaptyRepositoryImpl] Может ли задать фоллоу-ап вопрос: $canAsk',
      );
      return canAsk;
    } catch (e) {
      debugPrint(
        '[AdaptyRepositoryImpl] Ошибка проверки возможности фоллоу-ап вопроса: $e',
      );
      return false;
    }
  }

  /// Сброс флага бесплатного гадания (для тестирования)
  /// [AdaptyRepositoryImpl] Метод для ручного сброса флага использования бесплатного гадания
  @override
  @visibleForTesting
  Future<void> resetFreeReadingFlag() async {
    try {
      await _storage.write(key: _hasUsedFreeReadingKey, value: 'false');
      debugPrint(
        '[AdaptyRepositoryImpl] 🔄 Флаг бесплатного гадания сброшен в false',
      );

      await trackEvent(
        'free_reading_flag_reset',
        parameters: {
          'timestamp': DateTime.now().toIso8601String(),
          'platform': Platform.operatingSystem,
        },
      );
    } catch (e) {
      debugPrint(
        '[AdaptyRepositoryImpl] ❌ Ошибка сброса флага бесплатного гадания: $e',
      );
    }
  }

  /// Сброс счетчика фоллоу-ап вопросов (для тестирования)
  /// [AdaptyRepositoryImpl] Метод для ручного сброса счетчика фоллоу-ап вопросов
  @override
  @visibleForTesting
  Future<void> resetFollowUpQuestionsCount() async {
    try {
      await _storage.write(
        key: _followUpQuestionsCountKey,
        value: _maxFollowUpQuestions.toString(),
      );
      debugPrint(
        '[AdaptyRepositoryImpl] 🔄 Счетчик фоллоу-ап вопросов сброшен до $_maxFollowUpQuestions',
      );

      await trackEvent(
        'follow_up_questions_reset',
        parameters: {
          'count': _maxFollowUpQuestions,
          'timestamp': DateTime.now().toIso8601String(),
          'platform': Platform.operatingSystem,
        },
      );
    } catch (e) {
      debugPrint(
        '[AdaptyRepositoryImpl] ❌ Ошибка сброса счетчика фоллоу-ап вопросов: $e',
      );
    }
  }

  /// Полный сброс всех данных пользователя (для тестирования)
  /// [AdaptyRepositoryImpl] Метод для полного сброса состояния пользователя
  @override
  @visibleForTesting
  Future<void> resetUserData() async {
    debugPrint(
      '[AdaptyRepositoryImpl] 🔄 Начинаем полный сброс данных пользователя...',
    );

    await resetFreeReadingFlag();
    await resetFollowUpQuestionsCount();

    if (_isRunningOnEmulator) {
      await clearEmulatorSubscription();
    }

    debugPrint(
      '[AdaptyRepositoryImpl] ✅ Полный сброс данных пользователя завершен',
    );
  }

  /// Детальное логирование состояния пользователя для отладки
  /// [AdaptyRepositoryImpl] Выводит все данные о состоянии пользователя в лог
  @override
  @visibleForTesting
  Future<void> logUserState() async {
    debugPrint('');
    debugPrint(
      '[AdaptyRepositoryImpl] 📊 === ДЕТАЛЬНОЕ СОСТОЯНИЕ ПОЛЬЗОВАТЕЛЯ ===',
    );

    try {
      // Получаем все флаги и счетчики
      final hasUsedFreeReading = await _getHasUsedFreeReading();
      final remainingFollowUpQuestions = await _getRemainingFollowUpQuestions();
      final remainingFreeRequests = await _getRemainingFreeRequests();

      // Получаем статус подписки
      final subscriptionStatus = await getSubscriptionStatus();

      debugPrint('[AdaptyRepositoryImpl] 📊 Флаги локального хранения:');
      debugPrint(
        '[AdaptyRepositoryImpl] 📊   hasUsedFreeReading: $hasUsedFreeReading',
      );
      debugPrint(
        '[AdaptyRepositoryImpl] 📊   remainingFollowUpQuestions: $remainingFollowUpQuestions',
      );
      debugPrint(
        '[AdaptyRepositoryImpl] 📊   remainingFreeRequests: $remainingFreeRequests',
      );

      debugPrint('[AdaptyRepositoryImpl] 📊 Статус подписки:');
      debugPrint(
        '[AdaptyRepositoryImpl] 📊   isActive: ${subscriptionStatus.isActive}',
      );
      debugPrint(
        '[AdaptyRepositoryImpl] 📊   hasPremiumAccess: ${subscriptionStatus.hasPremiumAccess}',
      );
      debugPrint(
        '[AdaptyRepositoryImpl] 📊   canStartNewReading: ${subscriptionStatus.canStartNewReading}',
      );
      debugPrint(
        '[AdaptyRepositoryImpl] 📊   canAskFollowUpQuestion: ${subscriptionStatus.canAskFollowUpQuestion}',
      );

      debugPrint('[AdaptyRepositoryImpl] 📊 Платформа:');
      debugPrint(
        '[AdaptyRepositoryImpl] 📊   isRunningOnEmulator: $_isRunningOnEmulator',
      );
      debugPrint('[AdaptyRepositoryImpl] 📊   kDebugMode: $kDebugMode');

      if (_isRunningOnEmulator) {
        final emulatorSubscription = await _storage.read(
          key: _emulatorSubscriptionKey,
        );
        debugPrint('[AdaptyRepositoryImpl] 📊 Эмулятор:');
        debugPrint(
          '[AdaptyRepositoryImpl] 📊   emulatorSubscriptionActive: $emulatorSubscription',
        );
      }
    } catch (e) {
      debugPrint(
        '[AdaptyRepositoryImpl] 📊 ❌ Ошибка при получении состояния: $e',
      );
    }

    debugPrint('[AdaptyRepositoryImpl] 📊 === КОНЕЦ ДЕТАЛЬНОГО СОСТОЯНИЯ ===');
    debugPrint('');
  }
}
