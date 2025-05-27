import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:zhi_ming/core/services/adapty/adapty_service.dart';

class AdaptyServiceImpl implements AdaptyService {
  static const _storage = FlutterSecureStorage();

  // Ключи для хранения данных
  static const String _subscriptionStatusKey = 'subscription_status';
  static const String _freeRequestsCountKey = 'free_requests_count';

  // Константы
  static const int _maxFreeRequests = kDebugMode ? 5 : 20;

  @override
  Future<void> init() async {
    // await Adapty.init();

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
    // Для разработки по умолчанию считаем подписку неоплаченной
    if (kDebugMode) {
      final status = await _storage.read(key: _subscriptionStatusKey);
      return status == 'active';
    }

    // В продакшене здесь будет проверка через Adapty
    // return await Adapty.getPaywallProducts();
    return false;
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
    final currentCount = await getRemainingFreeRequests();
    if (currentCount > 0) {
      final newCount = currentCount - 1;
      await _storage.write(
        key: _freeRequestsCountKey,
        value: newCount.toString(),
      );
      debugPrint('Счетчик бесплатных запросов уменьшен до: $newCount');
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
    // Если есть активная подписка, запросы не ограничены
    final hasSubscription = await hasActiveSubscription();
    debugPrint(
      'AdaptyService.canMakeRequest: hasActiveSubscription = $hasSubscription',
    );

    if (hasSubscription) {
      debugPrint(
        'AdaptyService.canMakeRequest: возвращаем true (есть подписка)',
      );
      return true;
    }

    // Если подписки нет, проверяем количество оставшихся бесплатных запросов
    final remainingRequests = await getRemainingFreeRequests();
    debugPrint(
      'AdaptyService.canMakeRequest: remainingRequests = $remainingRequests',
    );

    final canMake = remainingRequests > 0;
    debugPrint('AdaptyService.canMakeRequest: возвращаем $canMake');
    return canMake;
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

  /// Метод для тестирования - устанавливает конкретное количество бесплатных запросов
  Future<void> setFreeRequestsCount(int count) async {
    if (kDebugMode) {
      await _storage.write(key: _freeRequestsCountKey, value: count.toString());
      debugPrint('Установлено количество бесплатных запросов: $count');
    }
  }
}
