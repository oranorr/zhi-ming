import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:zhi_ming/features/chat/domain/message_entity.dart';

/// Сервис для управления streaming эффектом сообщений
/// Отвечает за включение и отключение анимации печатания текста
class MessageStreamingService {
  final Map<String, Timer> _activeTimers = {};

  /// Настройка streaming для сообщения
  /// [message] - сообщение для которого нужно настроить streaming
  /// [onStreamingComplete] - колбэк, вызываемый когда streaming завершен
  void setupStreaming({
    required MessageEntity message,
    required VoidCallback onStreamingComplete,
    int? customDurationMs,
  }) {
    if (!message.isStreaming) {
      debugPrint(
        '[MessageStreamingService] Сообщение не имеет флага streaming, пропускаем',
      );
      return;
    }

    final messageId = _getMessageId(message);

    // Отменяем предыдущий таймер для этого сообщения, если он есть
    _cancelTimer(messageId);

    // Рассчитываем длительность на основе длины текста
    final duration =
        customDurationMs ?? _calculateStreamingDuration(message.text);

    debugPrint(
      '[MessageStreamingService] Настраиваем streaming для сообщения на $duration мс',
    );

    // Создаем новый таймер
    _activeTimers[messageId] = Timer(Duration(milliseconds: duration), () {
      debugPrint('[MessageStreamingService] Streaming завершен для сообщения');
      _activeTimers.remove(messageId);
      onStreamingComplete();
    });
  }

  /// Принудительное завершение streaming для сообщения
  void stopStreaming(MessageEntity message) {
    final messageId = _getMessageId(message);
    debugPrint(
      '[MessageStreamingService] Принудительное завершение streaming для сообщения',
    );
    _cancelTimer(messageId);
  }

  /// Принудительное завершение всех активных streaming
  void stopAllStreaming() {
    debugPrint('[MessageStreamingService] Завершение всех активных streaming');
    for (final timer in _activeTimers.values) {
      timer.cancel();
    }
    _activeTimers.clear();
  }

  /// Проверка наличия активного streaming для сообщения
  bool isStreaming(MessageEntity message) {
    final messageId = _getMessageId(message);
    return _activeTimers.containsKey(messageId);
  }

  /// Получение количества активных streaming
  int get activeStreamingCount => _activeTimers.length;

  /// Рассчитывает длительность streaming на основе длины текста
  int _calculateStreamingDuration(String text) {
    // Базовая формула: 30 мс на символ + базовая задержка 500 мс
    const int msPerCharacter = 30;
    const int baseDurationMs = 500;

    final calculatedDuration = text.length * msPerCharacter + baseDurationMs;

    // Ограничиваем минимальную и максимальную длительность
    const int minDurationMs = 1000; // минимум 1 секунда
    const int maxDurationMs = 10000; // максимум 10 секунд

    return calculatedDuration.clamp(minDurationMs, maxDurationMs);
  }

  /// Генерирует уникальный ID для сообщения
  String _getMessageId(MessageEntity message) {
    // Используем комбинацию timestamp и первых символов текста для уникальности
    final timestampMs = message.timestamp.millisecondsSinceEpoch;
    final textPreview =
        message.text.length > 20 ? message.text.substring(0, 20) : message.text;
    return '${timestampMs}_${textPreview.hashCode}';
  }

  /// Отменяет таймер для сообщения
  void _cancelTimer(String messageId) {
    final timer = _activeTimers[messageId];
    if (timer != null) {
      timer.cancel();
      _activeTimers.remove(messageId);
      debugPrint(
        '[MessageStreamingService] Таймер отменен для сообщения $messageId',
      );
    }
  }

  /// Освобождение ресурсов при уничтожении сервиса
  void dispose() {
    debugPrint('[MessageStreamingService] Освобождение ресурсов');
    stopAllStreaming();
  }
}

/// Конфигурация для streaming сообщений
class StreamingConfig {
  const StreamingConfig({
    this.msPerCharacter = 30,
    this.baseDurationMs = 500,
    this.minDurationMs = 1000,
    this.maxDurationMs = 10000,
  });

  final int msPerCharacter;
  final int baseDurationMs;
  final int minDurationMs;
  final int maxDurationMs;

  /// Рассчитывает длительность для текста
  int calculateDuration(String text) {
    final calculatedDuration = text.length * msPerCharacter + baseDurationMs;
    return calculatedDuration.clamp(minDurationMs, maxDurationMs);
  }
}
