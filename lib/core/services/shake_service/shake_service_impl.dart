import 'dart:async';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:zhi_ming/core/services/shake_service/shaker_service_repo.dart';

class ShakerServiceImpl extends ShakerServiceRepo {
  ShakerServiceImpl() {
    _initShakeDetection();
  }
  final _shakeCountController = StreamController<int>.broadcast();
  int _shakeCount = 0;
  static const int _maxShakeCount = 6;
  static const double _shakeThreshold = 15;
  static const Duration _shakeWindow = Duration(milliseconds: 500);

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

  void dispose() {
    _shakeCountController.close();
  }
}
