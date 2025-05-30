import 'package:flutter/foundation.dart';
import 'package:zhi_ming/features/adapty/data/repositories/adapty_repository_impl.dart';
import 'package:zhi_ming/features/adapty/domain/repositories/adapty_repository.dart';

/// Сервис для управления Adapty SDK
/// Предоставляет единую точку доступа к функциональности подписок
class AdaptyService {
  AdaptyService._();
  static AdaptyService? _instance;
  static AdaptyService get instance => _instance ??= AdaptyService._();

  late final AdaptyRepository _repository;
  bool _isInitialized = false;

  /// Получение экземпляра репозитория Adapty
  AdaptyRepository get repository {
    if (!_isInitialized) {
      throw StateError(
        'AdaptyService не инициализирован. Вызовите initialize() сначала.',
      );
    }
    return _repository;
  }

  /// Инициализация Adapty SDK
  /// Должна быть вызвана один раз при запуске приложения
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('[AdaptyService] Adapty уже инициализирован');
      return;
    }

    try {
      debugPrint('[AdaptyService] Инициализация Adapty SDK...');

      // Создаем экземпляр репозитория
      _repository = AdaptyRepositoryImpl();

      // Инициализируем репозиторий
      await _repository.initialize();

      _isInitialized = true;
      debugPrint('[AdaptyService] Adapty SDK успешно инициализирован');
    } catch (e) {
      debugPrint('[AdaptyService] Ошибка инициализации Adapty SDK: $e');
      rethrow;
    }
  }

  /// Проверка, инициализирован ли сервис
  bool get isInitialized => _isInitialized;

  /// Сброс состояния сервиса (для тестирования)
  @visibleForTesting
  void reset() {
    _isInitialized = false;
    _instance = null;
  }
}
