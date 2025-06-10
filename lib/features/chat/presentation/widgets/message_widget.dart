import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zhi_ming/features/chat/domain/message_entity.dart';
import 'package:zhi_ming/features/chat/presentation/widgets/bot_message_widget.dart';
import 'package:zhi_ming/features/chat/presentation/widgets/user_message_widget.dart';

/// [MessageWidget] Основной виджет для отображения сообщений в чате
class MessageWidget extends StatefulWidget {
  const MessageWidget({
    required this.isMe,
    required this.text,
    required this.isLoading,
    this.hexagrams,
    this.message, // Передаем весь объект сообщения для доступа к интерпретациям
    super.key,
  });

  final bool isMe;
  final String text;
  final bool isLoading;
  final List<dynamic>? hexagrams;
  final MessageEntity? message; // Полный объект сообщения

  @override
  State<MessageWidget> createState() => _MessageWidgetState();
}

class _MessageWidgetState extends State<MessageWidget>
    with TickerProviderStateMixin {
  String _displayedText = '';
  int _currentIndex = 0;
  Timer? _streamingTimer;

  @override
  void initState() {
    super.initState();
    // Если сообщение в режиме streaming и это не пользователь
    if (widget.message?.isStreaming == true &&
        !widget.isMe &&
        widget.text.isNotEmpty) {
      _startStreaming();
    } else {
      _displayedText = widget.text;
    }
  }

  @override
  void didUpdateWidget(MessageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Если streaming завершился, показываем полный текст
    if (oldWidget.message?.isStreaming == true &&
        widget.message?.isStreaming == false) {
      _stopStreaming();
      setState(() {
        _displayedText = widget.text;
      });
    }
    // Если текст изменился (например, заменили loading сообщение на сообщение с текстом)
    else if (oldWidget.text != widget.text) {
      // Если новое сообщение не в режиме streaming, просто обновляем текст
      if (widget.message?.isStreaming != true) {
        setState(() {
          _displayedText = widget.text;
        });
      } else {
        // Если новое сообщение в режиме streaming, запускаем анимацию
        _stopStreaming(); // Останавливаем предыдущий streaming, если был
        _currentIndex = 0;
        _displayedText = '';
        _startStreaming();
      }
    }
  }

  @override
  void dispose() {
    _stopStreaming();
    super.dispose();
  }

  /// [_MessageWidgetState] Запуск эффекта streaming для текста
  void _startStreaming() {
    if (widget.text.isEmpty) return;

    _streamingTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (_currentIndex < widget.text.length) {
        setState(() {
          _currentIndex++;
          _displayedText = widget.text.substring(0, _currentIndex);
        });
      } else {
        _stopStreaming();
      }
    });
  }

  /// [_MessageWidgetState] Остановка эффекта streaming
  void _stopStreaming() {
    _streamingTimer?.cancel();
    _streamingTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    // Определяем тип сообщения и отображаем соответствующий виджет
    if (widget.isMe) {
      return UserMessageWidget(text: _displayedText);
    } else {
      return BotMessageWidget(
        text: _displayedText,
        isLoading: widget.isLoading,
        hexagrams: widget.hexagrams,
        message: widget.message,
      );
    }
  }
}
