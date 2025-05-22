import 'dart:convert';

/// Парсер ответов от агента валидации запросов
class RequestValidationResponse {
  /// Конструктор
  RequestValidationResponse({
    required this.status,
    required this.reasonMessage,
  });

  /// Создание из JSON строки
  factory RequestValidationResponse.fromJson(String source) {
    try {
      final Map<String, dynamic> jsonMap =
          json.decode(source) as Map<String, dynamic>;
      return RequestValidationResponse.fromMap(jsonMap);
    } catch (e) {
      return RequestValidationResponse.unknown(
        'Ошибка парсинга JSON: $e, исходный ответ: $source',
      );
    }
  }

  /// Создание из JSON карты
  factory RequestValidationResponse.fromMap(Map<String, dynamic> map) {
    // Обрабатываем разные варианты структуры JSON
    final status = map['status'] as String? ?? 'unknown';

    // Обработка reasonMessage, который может отсутствовать для valid статуса
    String reasonMessage = '';
    if (map.containsKey('reasonMessage')) {
      reasonMessage = map['reasonMessage'] as String? ?? '';
    }

    return RequestValidationResponse(
      status: status,
      reasonMessage: reasonMessage,
    );
  }

  /// Фабричный метод для создания ответа о неизвестной ошибке
  factory RequestValidationResponse.unknown(String message) {
    return RequestValidationResponse(status: 'unknown', reasonMessage: message);
  }

  /// Фабричный метод для создания ответа об ошибке
  factory RequestValidationResponse.error(String message) {
    return RequestValidationResponse(status: 'error', reasonMessage: message);
  }

  /// Статус валидации (valid/invalid)
  final String status;

  /// Причина валидации/отклонения запроса
  final String reasonMessage;

  /// Проверка валидности запроса
  bool get isValid => status == 'valid';

  /// Конвертация в строку
  @override
  String toString() =>
      'RequestValidationResponse(status: $status, reasonMessage: $reasonMessage)';
}

/// Класс для потоковой обработки ответов
class StreamingResponseHandler {
  /// Метод для обработки куска данных из потока
  static String? parseStreamChunk(String chunk) {
    if (chunk.isEmpty) {
      return null;
    }

    // Обработка данных в формате Server-Sent Events
    if (chunk.startsWith('data: ') && chunk != 'data: [DONE]') {
      final jsonLine = chunk.substring(6); // Удаляем 'data: '
      try {
        final data = jsonDecode(jsonLine);

        // Проверяем структуру ответа от OpenRouter API
        if (data.containsKey('choices') &&
            data['choices'] is List &&
            data['choices'].isNotEmpty) {
          // Проверяем сначала delta структуру (для OpenAI/GPT)
          if (data['choices'][0].containsKey('delta') &&
              data['choices'][0]['delta'].containsKey('content')) {
            final content = data['choices'][0]['delta']['content'];
            if (content != null && content.isNotEmpty) {
              return content;
            }
          }
          // Затем проверяем структуру для обычного завершения (для других моделей)
          else if (data['choices'][0].containsKey('message') &&
              data['choices'][0]['message'].containsKey('content')) {
            final content = data['choices'][0]['message']['content'];
            if (content != null && content.isNotEmpty) {
              return content;
            }
          }
        }
      } catch (e) {
        // Пропускаем ошибки парсинга
        return null;
      }
    }

    return null;
  }
}
