import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:zhi_ming/core/services/deepseek/models/message.dart';
import 'package:zhi_ming/core/services/deepseek/models/response_parsers.dart';
import 'package:zhi_ming/core/services/deepseek/prompts.dart';
import 'package:zhi_ming/features/chat/domain/message_entity.dart';
import 'package:zhi_ming/features/iching/models/hexagram.dart';

enum AgentType {
  requestValidator, // Проверяет адекватность запроса пользователя
  ichingInterpreter, // Интерпретирует результаты гадания и-дзин
  onboarding, // Для онбординга
  followUpQuestions, // Для обработки последующих вопросов
  bazsu, // Для интерпретации Ба-Дзы (Four Pillars of Destiny)
  recommendator, // Для генерации рекомендаций карточек
}

class DeepSeekService {
  DeepSeekService() {
    // Настраиваем Dio для прямой работы с API
    _dio.options.headers['Authorization'] = 'Bearer $_apiKey';
    _dio.options.headers['Content-Type'] = 'application/json';
  }
  static const String _apiKey = 'REPLACE_WITH_YOUR_API_KEY';
  static const String _baseUrl = 'https://api.deepseek.com/v1';

  final _dio = Dio();

  /// Активные HTTP запросы для возможности отмены
  http.Request? _activeRequest;
  http.StreamedResponse? _activeResponse;

  /// Отправляет запрос указанному агенту и возвращает ответ
  Future<String> sendMessage({
    required AgentType agentType,
    required String message,
    List<DeepSeekMessage>? history,
  }) async {
    try {
      debugPrint('====== НАЧАЛО ОТПРАВКИ СООБЩЕНИЯ ======');
      debugPrint('Тип агента: $agentType');

      final model = _getModelByAgentType(agentType);
      debugPrint('Модель: $model');

      final messages = <Map<String, dynamic>>[];

      // Добавляем системное сообщение в зависимости от типа агента
      final systemPrompt = _getSystemPromptByAgentType(agentType);
      debugPrint(
        'Системный промпт (первые 100 символов): ${systemPrompt.substring(0, min(100, systemPrompt.length))}...',
      );

      messages.add({'role': 'system', 'content': systemPrompt});

      // Добавляем историю сообщений, если она предоставлена
      if (history != null && history.isNotEmpty) {
        debugPrint('История сообщений: ${history.length} сообщений');
        messages.addAll(history.map((m) => m.toMap()));
      } else {
        debugPrint('История сообщений: отсутствует');
      }

      // Добавляем текущее сообщение пользователя
      String messagePreview =
          message.length > 100 ? '${message.substring(0, 100)}...' : message;
      debugPrint('Сообщение пользователя: $messagePreview');
      messages.add({'role': 'user', 'content': message});

      // Формируем тело запроса в соответствии с DeepSeek API
      final requestBody = {
        'model': model,
        'messages': messages,
        'temperature': 0.7,
        'max_tokens': 1000,
      };

      // Логируем часть тела запроса (без вывода полного содержимого)
      debugPrint('Тело запроса: частичное содержимое...');
      debugPrint('URL: $_baseUrl/chat/completions');
      debugPrint(
        'Headers: Content-Type: application/json, Authorization: Bearer sk-*****',
      );

      // Отправляем запрос напрямую через Dio
      debugPrint('Выполняем POST запрос...');
      final response = await _dio.post(
        '$_baseUrl/chat/completions',
        data: requestBody,
      );

      debugPrint('Получен ответ от сервера. Статус: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Защита от null с подробным логированием
        final responseData = response.data;

        if (responseData == null) {
          debugPrint('ОШИБКА: response.data == null');
          return '服务器返回空响应。请稍后重试。';
        }

        debugPrint(
          'Получены данные. Структура ответа: ${responseData.runtimeType}',
        );

        final choices = responseData['choices'];
        if (choices == null) {
          debugPrint('ОШИБКА: choices == null');
          debugPrint('Полный ответ: $responseData');
          return '服务器返回没有choices字段的响应。请稍后重试。';
        }

        if (choices is! List || choices.isEmpty) {
          debugPrint('ОШИБКА: choices пуст или не является списком');
          debugPrint(
            'Тип choices: ${choices.runtimeType}, содержимое: $choices',
          );
          return '服务器返回空选项列表。请稍后重试。';
        }

        final firstChoice = choices[0];
        if (firstChoice == null) {
          debugPrint('ОШИБКА: firstChoice == null');
          return 'Сервер вернул некорректный ответ. Пожалуйста, попробуйте позже.';
        }

        debugPrint('Первый элемент choices: $firstChoice');

        final messageObj = firstChoice['message'];
        if (messageObj == null) {
          debugPrint('ОШИБКА: message == null');
          debugPrint('Содержимое firstChoice: $firstChoice');
          return 'Сервер вернул ответ без поля message. Пожалуйста, попробуйте позже.';
        }

        final content = messageObj['content'];
        if (content == null) {
          debugPrint('ОШИБКА: content == null');
          debugPrint('Содержимое message: $messageObj');
          return 'Сервер вернул сообщение без содержимого. Пожалуйста, попробуйте позже.';
        }

        String contentPreview = content.toString();
        if (contentPreview.length > 100) {
          contentPreview = '${contentPreview.substring(0, 100)}...';
        }
        debugPrint('Успешно получен ответ: $contentPreview');
        debugPrint('====== КОНЕЦ ОТПРАВКИ СООБЩЕНИЯ ======');

        return content.toString();
      } else {
        debugPrint('ОШИБКА при отправке сообщения: ${response.statusCode}');
        debugPrint('Тело ответа с ошибкой: ${response.data}');
        debugPrint('====== КОНЕЦ ОТПРАВКИ СООБЩЕНИЯ (С ОШИБКОЙ) ======');
        return '服务器返回无效响应。请稍后重试。';
      }
    } on DioException catch (e, stackTrace) {
      debugPrint('ИСКЛЮЧЕНИЕ при отправке сообщения в API: $e');
      debugPrint(
        'Stack trace: ${stackTrace.toString().split("\n").take(10).join("\n")}',
      );
      debugPrint('====== КОНЕЦ ОТПРАВКИ СООБЩЕНИЯ (С ИСКЛЮЧЕНИЕМ) ======');
      return '处理请求时发生错误。请稍后重试。详情: $e';
    } on Exception catch (e) {
      debugPrint('Исключение при отправке сообщения в API: $e');
      debugPrint('====== КОНЕЦ ОТПРАВКИ СООБЩЕНИЯ (С ИСКЛЮЧЕНИЕМ) ======');
      return '您的问题不适合占卜。请更具体地表述。';
    }
  }

  /// Отправляет запрос агенту и возвращает ответ в виде потока
  Stream<String> streamMessage({
    required AgentType agentType,
    required String message,
    List<DeepSeekMessage>? history,
  }) async* {
    try {
      final model = _getModelByAgentType(agentType);

      final messages = <Map<String, dynamic>>[];

      // Добавляем системное сообщение в зависимости от типа агента
      // ignore: cascade_invocations
      messages.add({
        'role': 'system',
        'content': _getSystemPromptByAgentType(agentType),
      });

      // Добавляем историю сообщений, если она предоставлена
      if (history != null && history.isNotEmpty) {
        messages.addAll(history.map((m) => m.toMap()));
      }

      // Добавляем текущее сообщение пользователя
      messages.add({'role': 'user', 'content': message});

      // Для стриминга используем напрямую http запрос
      final url = Uri.parse('$_baseUrl/chat/completions');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      };

      final requestBody = jsonEncode({
        'model': model,
        'messages': messages,
        'temperature': 0.7,
        'max_tokens': 1000,
        'stream': true,
      });

      final request =
          http.Request('POST', url)
            ..headers.addAll(headers)
            ..body = requestBody;

      // Сохраняем ссылку на активный запрос
      _activeRequest = request;

      final response = await http.Client().send(request);

      // Сохраняем ссылку на активный ответ
      _activeResponse = response;

      if (response.statusCode == 200) {
        await for (final chunk in response.stream.transform(utf8.decoder)) {
          // Проверяем, не была ли отмена запроса
          if (_activeRequest == null || _activeResponse == null) {
            debugPrint(
              '[DeepSeekService] Запрос был отменен, прерываем стриминг',
            );
            break;
          }

          // API возвращает данные в формате SSE (Server-Sent Events)
          // Каждое событие начинается с 'data: '
          final lines = chunk.split('\n');
          for (final line in lines) {
            final content = StreamingResponseHandler.parseStreamChunk(line);
            if (content != null) {
              yield content;
            }
          }
        }
      } else {
        // Получаем тело ответа для диагностики
        final responseBody = await response.stream.bytesToString();
        debugPrint('Ошибка стриминга: ${response.statusCode}');
        debugPrint('Тело ответа: $responseBody');
        yield 'Ошибка стриминга: ${response.statusCode}. Детали: $responseBody';
      }

      // Очищаем ссылки после завершения
      _activeRequest = null;
      _activeResponse = null;
    } on Exception catch (e) {
      debugPrint('Исключение при стриминге: $e');
      yield '处理请求时发生错误。请稍后重试。详情: $e';
    }
  }

  /// Проверяет адекватность запроса пользователя и возвращает результат проверки
  Future<RequestValidationResponse> validateRequest(request) async {
    try {
      // Обрабатываем входной параметр - может быть строкой или списком строк
      String requestText;
      if (request is String) {
        requestText = request;
      } else if (request is List<String>) {
        // Объединяем контекст в один текст
        if (request.isEmpty) {
          return RequestValidationResponse.error('Пустой контекст вопроса');
        }

        // Если в контексте только одно сообщение, используем его
        if (request.length == 1) {
          requestText = request.first;
        } else {
          // Если несколько сообщений, объединяем их с контекстом
          final buffer = StringBuffer(
            'Пользователь постепенно формулирует вопрос:\n\n',
          );
          for (int i = 0; i < request.length; i++) {
            buffer.write('${i + 1}. ${request[i]}\n');
          }
          buffer.write(
            '\nОцени общий смысл всех сообщений как единый вопрос для гадания.',
          );
          requestText = buffer.toString();
        }
      } else {
        return RequestValidationResponse.error(
          'Неверный тип данных для валидации',
        );
      }

      final response = await sendMessage(
        agentType: AgentType.requestValidator,
        message: requestText,
      );

      debugPrint('Получен сырой ответ от валидатора: $response');

      // Очищаем ответ от маркеров Markdown
      String cleanedResponse = response;

      // Удаляем блоки кода markdown
      final markdownCodeRegex = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```');
      final match = markdownCodeRegex.firstMatch(cleanedResponse);

      if (match != null && match.groupCount >= 1) {
        // Извлекаем только содержимое внутри блока кода
        cleanedResponse = match.group(1)?.trim() ?? cleanedResponse;
        debugPrint('Извлеченный JSON после очистки: $cleanedResponse');
      }

      // Проверяем, содержит ли ответ ключевые слова, указывающие на статус
      // Некоторые модели могут не строго следовать формату JSON
      if (!cleanedResponse.contains('"status":') &&
          !cleanedResponse.contains("'status':")) {
        if (cleanedResponse.toLowerCase().contains('invalid') ||
            cleanedResponse.toLowerCase().contains('не подходит') ||
            cleanedResponse.toLowerCase().contains('некорректный') ||
            cleanedResponse.toLowerCase().contains('ошибка')) {
          String reason = cleanedResponse;
          // Пытаемся убрать техническую информацию
          if (reason.contains('reason')) {
            final parts = reason.split('reason');
            if (parts.length > 1) {
              reason = parts[1];
            }
          }

          // Убираем кавычки и скобки
          reason =
              reason
                  .replaceAll('"', '')
                  .replaceAll("'", '')
                  .replaceAll('{', '')
                  .replaceAll('}', '')
                  .replaceAll(':', '')
                  .replaceAll('Message', '')
                  .replaceAll('message', '')
                  .trim();

          return RequestValidationResponse(
            status: 'invalid',
            reasonMessage: reason,
          );
        } else {
          // Предполагаем, что валидно, если нет явных указаний на обратное
          return RequestValidationResponse(status: 'valid', reasonMessage: '');
        }
      }

      // Пытаемся распарсить очищенный ответ как JSON
      try {
        return RequestValidationResponse.fromJson(cleanedResponse);
      } on FormatException catch (e) {
        debugPrint('Ошибка парсинга JSON: $e');

        // Проверяем содержимое ответа на ключевые слова
        if (cleanedResponse.toLowerCase().contains('invalid')) {
          return RequestValidationResponse(
            status: 'invalid',
            reasonMessage: '您的问题不适合占卜。请更具体地表述。',
          );
        } else if (cleanedResponse.toLowerCase().contains('valid')) {
          return RequestValidationResponse(status: 'valid', reasonMessage: '');
        }

        // Если не удалось распарсить как JSON, возвращаем стандартный формат
        return RequestValidationResponse.unknown(
          'Не удалось обработать ответ: $response',
        );
      }
    } on Exception catch (e) {
      return RequestValidationResponse.error('Ошибка при проверке запроса: $e');
    }
  }

  /// Извлекает markdown-текст из ответа агента (парсит JSON, если нужно)
  String _extractMarkdownFromResponse(String response) {
    // Проверка на пустой ответ
    debugPrint(
      '--- Начало обработки ответа в _extractMarkdownFromResponse ---',
    );
    String result = response.trim();

    if (result.isEmpty) {
      debugPrint('Получен пустой ответ, возвращаем пустую строку');
      return '';
    }

    debugPrint('Исходный ответ (длина: ${result.length})');
    debugPrint('Тип ответа: ${result.runtimeType}');
    String previewOrig =
        result.length > 100 ? '${result.substring(0, 100)}...' : result;
    debugPrint('Начало ответа: $previewOrig');

    // Попробовать распарсить JSON из строки
    try {
      // Иногда агент возвращает JSON внутри строки, обрезаем кавычки если есть
      String jsonCandidate = result;
      if (jsonCandidate.startsWith('"') && jsonCandidate.endsWith('"')) {
        jsonCandidate = jsonCandidate.substring(1, jsonCandidate.length - 1);
        debugPrint('Обрезаны кавычки по краям');
      }

      // Убираем экранирование кавычек
      if (jsonCandidate.contains(r'\"')) {
        String before = jsonCandidate;
        jsonCandidate = jsonCandidate.replaceAll(r'\"', '"');
        debugPrint(
          'Заменено ${before.length - jsonCandidate.length} экранированных кавычек',
        );
      }

      debugPrint('Пробуем распарсить JSON...');
      final parsed = jsonDecode(jsonCandidate);
      debugPrint('JSON успешно распарсен! Тип: ${parsed.runtimeType}');

      if (parsed != null && parsed is Map) {
        debugPrint('Содержит поля: ${parsed.keys.join(", ")}');

        // Пробуем взять наиболее вероятные поля
        if (parsed.containsKey('interpretation')) {
          final interpretation = parsed['interpretation'];
          if (interpretation != null) {
            result = interpretation.toString();
            debugPrint('Извлечен текст из поля interpretation');
          } else {
            debugPrint('Поле interpretation существует, но содержит null');
          }
        } else if (parsed.containsKey('answer')) {
          final answer = parsed['answer'];
          if (answer != null) {
            result = answer.toString();
            debugPrint('Извлечен текст из поля answer');
          } else {
            debugPrint('Поле answer существует, но содержит null');
          }
        } else {
          // Если есть только одно текстовое поле — взять его
          debugPrint(
            'Нет полей interpretation или answer, ищем текстовое поле...',
          );
          for (final entry in parsed.entries) {
            debugPrint(
              'Проверяем поле ${entry.key}: ${entry.value.runtimeType}',
            );
            if (entry.value is String) {
              result = entry.value as String;
              debugPrint('Извлечен текст из поля ${entry.key}');
              break;
            }
          }
        }
      } else {
        debugPrint(
          'Распарсенный JSON не является объектом или равен null: $parsed',
        );
      }
    } on Exception catch (e) {
      // Не JSON — оставляем как есть
      debugPrint('Не удалось распарсить JSON: $e');
      debugPrint('Используем исходный ответ');
    }

    // Удаляем лишние кавычки по краям
    result = result.trim();
    if (result.startsWith('"') && result.endsWith('"')) {
      result = result.substring(1, result.length - 1);
      debugPrint('Обрезаны кавычки вокруг результата');
    }

    // Логируем итоговый результат
    String preview =
        result.length > 100 ? '${result.substring(0, 100)}...' : result;
    debugPrint('Итоговый результат (длина: ${result.length}): $preview');
    debugPrint('--- Конец обработки ответа ---');

    return result;
  }

  /// Парсит JSON ответ от интерпретатора и возвращает соответствующую модель
  dynamic parseInterpretationResponse(String response) {
    try {
      debugPrint('=== Начало парсинга JSON интерпретации ===');
      debugPrint('Длина ответа: ${response.length}');

      // Извлекаем JSON из ответа (может быть обернут в markdown или другой текст)
      final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(response);
      if (jsonMatch == null) {
        debugPrint('JSON не найден в ответе');
        return null;
      }

      final jsonString = jsonMatch.group(0)!;
      debugPrint('Найден JSON блок длиной: ${jsonString.length}');

      final parsed = json.decode(jsonString);

      // Определяем тип интерпретации по наличию ключей
      if (parsed.containsKey('interpretation_primary') &&
          parsed.containsKey('interpretation_secondary')) {
        debugPrint('Обнаружена сложная интерпретация');
        return ComplexInterpretation.fromJson(parsed);
      } else if (parsed.containsKey('interpretation_summary')) {
        debugPrint('Обнаружена простая интерпретация');
        return SimpleInterpretation.fromJson(parsed);
      } else {
        debugPrint('Неизвестный формат интерпретации');
        return null;
      }
    } on Exception catch (e) {
      debugPrint('Ошибка парсинга JSON интерпретации: $e');
      return null;
    }
  }

  /// Отправляет запрос интерпретатору гексаграмм с возвращением структурированного ответа
  Future<dynamic> interpretHexagramsStructured({
    required String question,
    required Hexagram primaryHexagram,
    Hexagram? secondaryHexagram,
  }) async {
    try {
      debugPrint('=== Начало структурированной интерпретации гексаграмм ===');
      debugPrint('Вопрос пользователя: $question');

      // Формируем сообщение для интерпретатора
      final messageData = <String, dynamic>{
        'question': question,
        'primary_hexagram': {
          'hexa_name': primaryHexagram.name ?? '',
          'hexa_info': primaryHexagram.description ?? '',
        },
      };

      // Если есть изменяющиеся линии, добавляем вторичную гексаграмму
      final changingLines =
          primaryHexagram.lines
              .asMap()
              .entries
              .where((e) => e.value.isChanging)
              .map((e) => e.key + 1)
              .toList();

      if (changingLines.isNotEmpty && secondaryHexagram != null) {
        messageData['secondary_hexagram'] = {
          'hexa_name': secondaryHexagram.name ?? '',
          'hexa_info': secondaryHexagram.description ?? '',
        };
        messageData['changing_lines'] = changingLines;
      }

      final message = json.encode(messageData);
      debugPrint('Отправляем структурированный запрос интерпретатору');

      // Отправляем запрос интерпретатору с обновленным промптом
      final response = await sendMessage(
        agentType: AgentType.ichingInterpreter,
        message: message,
      );

      debugPrint('Получен ответ от интерпретатора');

      // Парсим структурированный ответ
      final parsedInterpretation = parseInterpretationResponse(response);

      if (parsedInterpretation != null) {
        debugPrint('Успешно спарсена структурированная интерпретация');
        return parsedInterpretation;
      } else {
        debugPrint(
          'Не удалось спарсить структурированную интерпретацию, возвращаем текст',
        );
        // Возвращаем исходный текст как fallback
        return _extractMarkdownFromResponse(response);
      }
    } on Exception catch (e) {
      debugPrint('解释卦象时发生错误。请稍后重试。');
      return '服务器返回空响应。请稍后重试。';
    }
  }

  /// Отправляет запрос интерпретатору гексаграмм (старый метод - для совместимости)
  Future<String> interpretHexagrams({
    required String question,
    required Hexagram primaryHexagram,
    Hexagram? secondaryHexagram,
  }) async {
    final result = await interpretHexagramsStructured(
      question: question,
      primaryHexagram: primaryHexagram,
      secondaryHexagram: secondaryHexagram,
    );

    if (result is String) {
      return result;
    } else {
      // Если получили структурированный ответ, извлекаем основной текст
      if (result is SimpleInterpretation) {
        return result.answer;
      } else if (result is ComplexInterpretation) {
        return result.answer;
      } else {
        return 'Получен неожиданный тип ответа от интерпретатора.';
      }
    }
  }

  /// Обрабатывает последующие вопросы пользователя с учетом контекста предыдущего гадания
  Future<String> handleFollowUpQuestion({
    required String question,
    required String originalQuestion,
    required Hexagram primaryHexagram,
    Hexagram? secondaryHexagram,
    String? previousInterpretation,
    List<DeepSeekMessage>? conversationHistory,
  }) async {
    try {
      debugPrint('====== НАЧАЛО ОБРАБОТКИ ПОСЛЕДУЮЩЕГО ВОПРОСА ======');
      debugPrint('Текущий вопрос: $question');
      debugPrint('Исходный вопрос: $originalQuestion');

      // Логируем информацию о первичной гексаграмме
      debugPrint('Первичная гексаграмма:');
      debugPrint('- Номер: ${primaryHexagram.number ?? "отсутствует"}');
      debugPrint('- Название: ${primaryHexagram.name ?? "отсутствует"}');

      // Логируем информацию о вторичной гексаграмме, если есть
      if (secondaryHexagram != null) {
        debugPrint('Вторичная гексаграмма:');
        debugPrint('- Номер: ${secondaryHexagram.number ?? "отсутствует"}');
        debugPrint('- Название: ${secondaryHexagram.name ?? "отсутствует"}');
      } else {
        debugPrint('Вторичная гексаграмма: отсутствует');
      }

      // Логируем информацию о предыдущей интерпретации
      if (previousInterpretation != null && previousInterpretation.isNotEmpty) {
        String preview =
            previousInterpretation.length > 100
                ? '${previousInterpretation.substring(0, 100)}...'
                : previousInterpretation;
        debugPrint('Предыдущая интерпретация: $preview');
      } else {
        debugPrint('Предыдущая интерпретация: отсутствует или пуста');
      }

      // Логируем информацию об истории диалога
      if (conversationHistory != null && conversationHistory.isNotEmpty) {
        debugPrint('История диалога: ${conversationHistory.length} сообщений');
        for (int i = 0; i < min(3, conversationHistory.length); i++) {
          debugPrint(
            '- Сообщение ${i + 1}: роль=${conversationHistory[i].role}, '
            'текст=${conversationHistory[i].content.substring(0, min(30, conversationHistory[i].content.length))}...',
          );
        }
      } else {
        debugPrint('История диалога: отсутствует');
      }

      // Формируем сообщение с контекстом с защитой от null
      debugPrint('Формируем контекст для запроса...');
      final contextMap = {
        'current_question': question,
        'original_question': originalQuestion,
        'primary_hexagram': {
          'hexa_name': primaryHexagram.name ?? '',
          'hexa_info': primaryHexagram.description ?? '',
          'number': primaryHexagram.number ?? 0,
          'changing_lines':
              primaryHexagram.lines
                  .asMap()
                  .entries
                  .where((e) => e.value.isChanging)
                  .map((e) => e.key + 1)
                  .toList(),
        },
        if (secondaryHexagram != null)
          'secondary_hexagram': {
            'hexa_name': secondaryHexagram.name ?? '',
            'hexa_info': secondaryHexagram.description ?? '',
            'number': secondaryHexagram.number ?? 0,
          },
        'previous_interpretation': previousInterpretation ?? '',
      };

      debugPrint('Структура контекста: ${contextMap.keys.join(", ")}');
      final contextMessage = jsonEncode(contextMap);

      // Отправляем запрос с учетом истории диалога
      debugPrint('Отправляем запрос агенту followUpQuestions...');
      final response = await sendMessage(
        agentType: AgentType.followUpQuestions,
        message: contextMessage,
        history: conversationHistory,
      );

      // Проверяем полученный ответ
      if (response.isEmpty) {
        debugPrint('ОШИБКА: Получен пустой ответ от sendMessage');
        debugPrint(
          '====== КОНЕЦ ОБРАБОТКИ ПОСЛЕДУЮЩЕГО ВОПРОСА (С ОШИБКОЙ) ======',
        );
        return 'Сервер вернул пустой ответ на ваш вопрос. Пожалуйста, попробуйте позже.';
      }

      debugPrint(
        'Получен ответ от сервиса sendMessage (длина: ${response.length})',
      );

      String responsePreview =
          response.length > 100 ? '${response.substring(0, 100)}...' : response;
      debugPrint('Ответ: $responsePreview');

      // Парсим markdown/JSON как и для основной интерпретации
      debugPrint('Очищаем ответ от JSON/Markdown...');
      final cleaned = _extractMarkdownFromResponse(response);

      if (cleaned.isEmpty) {
        debugPrint('ПРЕДУПРЕЖДЕНИЕ: После очистки ответ стал пустым');
        debugPrint(
          '====== КОНЕЦ ОБРАБОТКИ ПОСЛЕДУЮЩЕГО ВОПРОСА (С ПРЕДУПРЕЖДЕНИЕМ) ======',
        );
        return 'Не удалось обработать ответ сервера. Пожалуйста, попробуйте задать вопрос иначе.';
      }

      String cleanedPreview =
          cleaned.length > 100 ? '${cleaned.substring(0, 100)}...' : cleaned;
      debugPrint('Очищенный ответ: $cleanedPreview');
      debugPrint('====== КОНЕЦ ОБРАБОТКИ ПОСЛЕДУЮЩЕГО ВОПРОСА ======');

      return cleaned;
    } on Exception catch (e, stackTrace) {
      debugPrint('ИСКЛЮЧЕНИЕ при обработке последующего вопроса: $e');
      debugPrint(
        'Stack trace: ${stackTrace.toString().split("\n").take(10).join("\n")}',
      );
      debugPrint(
        '====== КОНЕЦ ОБРАБОТКИ ПОСЛЕДУЮЩЕГО ВОПРОСА (С ОШИБКОЙ) ======',
      );
      return '处理请求时发生错误。请稍后重试。详情: $e';
    }
  }

  // Возвращает модель в зависимости от типа агента
  String _getModelByAgentType(AgentType agentType) {
    switch (agentType) {
      case AgentType.requestValidator:
        return 'deepseek-chat';
      case AgentType.ichingInterpreter:
        return 'deepseek-chat';
      case AgentType.onboarding:
        return 'deepseek-chat';
      case AgentType.followUpQuestions:
        return 'deepseek-chat';
      case AgentType.bazsu:
        return 'deepseek-chat';
      case AgentType.recommendator:
        return 'deepseek-chat';
    }
  }

  // Возвращает системный промпт в зависимости от типа агента
  String _getSystemPromptByAgentType(AgentType agentType) {
    switch (agentType) {
      case AgentType.requestValidator:
        return validator;
      case AgentType.ichingInterpreter:
        return interpreter;
      case AgentType.onboarding:
        return onboarder;
      case AgentType.followUpQuestions:
        return followUpQuestionsPrompt;
      case AgentType.bazsu:
        return bazsuPrompt;
      case AgentType.recommendator:
        return recommendator;
    }
  }

  // Метод для тестирования соединения
  Future<String> testConnection() async {
    try {
      // Простой запрос для проверки соединения
      final response = await _dio.post(
        '$_baseUrl/chat/completions',
        data: {
          'model': 'deepseek-chat',
          'messages': [
            {'role': 'user', 'content': 'Привет, это тестовое сообщение.'},
          ],
          'temperature': 0.7,
          'max_tokens': 100,
        },
      );

      debugPrint('Статус ответа: ${response.statusCode}');
      debugPrint('Тело ответа: ${response.data}');

      return 'Соединение успешно установлено. Статус: ${response.statusCode}';
    } on Exception catch (e) {
      debugPrint('Ошибка при тестировании соединения: $e');
      return 'Ошибка соединения: $e';
    }
  }

  /// Отмена активных HTTP запросов
  void cancelActiveRequests() {
    debugPrint('[DeepSeekService] Отмена активных HTTP запросов');

    if (_activeRequest != null) {
      debugPrint('[DeepSeekService] Очищаем активный запрос');
      _activeRequest = null;
    }

    if (_activeResponse != null) {
      debugPrint('[DeepSeekService] Очищаем активный ответ');
      _activeResponse = null;
    }
  }
}
