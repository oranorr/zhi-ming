import 'dart:async';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:zhi_ming/core/services/shake_service/shaker_service_repo.dart';
import 'dart:developer' as developer;

class ShakerServiceImpl extends ShakerServiceRepo {
  ShakerServiceImpl() {
    _initShakeDetection();
  }
  final _shakeCountController = StreamController<int>.broadcast();
  int _shakeCount = 0;
  static const int _maxShakeCount = 6;
  static const double _shakeThreshold = 15;
  static const Duration _shakeWindow = Duration(milliseconds: 500);

  // Список для хранения результатов каждого броска (группа из 3 монет)
  final List<List<int>> _coinThrows = [];

  DateTime? _lastShakeTime;
  bool _isShaking = false;

  void _initShakeDetection() {
    accelerometerEvents.listen((AccelerometerEvent event) {
      final acceleration = _calculateAcceleration(event);

      if (acceleration > _shakeThreshold && !_isShaking) {
        _isShaking = true;
        _lastShakeTime = DateTime.now();
        _incrementShakeCount();
      } else if (_lastShakeTime != null &&
          DateTime.now().difference(_lastShakeTime!) > _shakeWindow) {
        _isShaking = false;
      }
    });
  }

  double _calculateAcceleration(AccelerometerEvent event) {
    return (event.x * event.x + event.y * event.y + event.z * event.z) / 100;
  }

  Future<void> _incrementShakeCount() async {
    if (_shakeCount < _maxShakeCount) {
      _shakeCount++;
      _shakeCountController.add(_shakeCount);

      // Генерируем сразу 3 монеты при одном встряхивании
      final List<int> currentThrow = [];

      // Генерируем 3 монеты (2 = Инь, 3 = Ян)
      for (int i = 0; i < 3; i++) {
        final bool isHeads = DateTime.now().millisecondsSinceEpoch % 2 == 0;
        final int coinValue = isHeads ? 3 : 2; // 3 = Ян (орел), 2 = Инь (решка)
        currentThrow.add(coinValue);
      }

      // Сохраняем бросок (все 3 монеты)
      saveCoinThrow(currentThrow);

      developer.log(
        'ShakerService: сгенерирован полный бросок из 3 монет: $currentThrow',
      );

      // Добавляем тактильную обратную связь
      if (_shakeCount == _maxShakeCount) {
        // Для последнего встряхивания используем более сильную вибрацию
        await HapticFeedback.heavyImpact();
      } else {
        // Для обычных встряхиваний используем среднюю вибрацию
        await HapticFeedback.mediumImpact();
      }
    }
  }

  @override
  Future<void> shake() async {
    _incrementShakeCount();
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Stream<int> get shakeCountStream => _shakeCountController.stream;

  @override
  int get currentShakeCount => _shakeCount;

  @override
  void resetShakeCount() {
    _shakeCount = 0;
    _shakeCountController.add(_shakeCount);
  }

  @override
  int get maxShakeCount => _maxShakeCount;

  @override
  void saveCoinThrow(List<int> coinValues) {
    if (_coinThrows.length < _maxShakeCount) {
      // Максимум 6 бросков для 6 линий
      _coinThrows.add(coinValues);
      int sum = coinValues.reduce((a, b) => a + b);
      developer.log('ShakerService: сохранен бросок: $coinValues, сумма: $sum');
    }
  }

  @override
  List<List<int>> getCoinThrows() {
    developer.log('ShakerService: получение всех бросков монет: $_coinThrows');
    return List<List<int>>.unmodifiable(_coinThrows);
  }

  @override
  List<int> getLineValues() {
    // Преобразуем каждый бросок (3 монеты) в сумму
    final List<int> lineValues =
        _coinThrows.map((throw_) {
          return throw_.reduce((a, b) => a + b);
        }).toList();

    developer.log('ShakerService: получение значений для линий: $lineValues');
    return lineValues;
  }

  @override
  void resetCoinThrows() {
    _coinThrows.clear();
  }

  void dispose() {
    _shakeCountController.close();
  }
}
