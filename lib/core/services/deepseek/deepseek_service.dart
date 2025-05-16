import 'dart:async';
import 'dart:convert';

import 'package:deepseek_api/deepseek_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:zhi_ming/core/services/deepseek/models/message.dart';
import 'package:zhi_ming/core/services/deepseek/models/response_parsers.dart';

enum AgentType {
  requestValidator, // Проверяет адекватность запроса пользователя
  ichingInterpreter, // Интерпретирует результаты гадания и-дзин
  onboarding, // Для онбординга
}

class DeepSeekService {
  DeepSeekService() {
    _api = DeepSeekAPI(apiKey: _apiKey);
    _dio.options.headers['Authorization'] = 'Bearer $_apiKey';
  }
  static const String _apiKey =
      'YOUR_DEEPSEEK_API_KEY'; // Замените на свой API ключ
  static const String _baseUrl = 'https://api.deepseek.com/v1';

  late final DeepSeekAPI _api;
  final _dio = Dio();

  /// Отправляет запрос указанному агенту и возвращает ответ
  Future<String> sendMessage({
    required AgentType agentType,
    required String message,
    List<DeepSeekMessage>? history,
  }) async {
    try {
      final model = _getModelByAgentType(agentType);

      final messages = <ChatMessage>[];

      // Добавляем системное сообщение в зависимости от типа агента
      messages.add(
        ChatMessage(
          role: 'system',
          content: _getSystemPromptByAgentType(agentType),
        ),
      );

      // Добавляем историю сообщений, если она предоставлена
      if (history != null && history.isNotEmpty) {
        messages.addAll(
          history.map((m) => ChatMessage(role: m.role, content: m.content)),
        );
      }

      // Добавляем текущее сообщение пользователя
      messages.add(ChatMessage(role: 'user', content: message));

      final request = ChatCompletionRequest(
        model: model,
        messages: messages,
        temperature: 0.7,
        maxTokens: 1000,
      );

      final response = await _api.createChatCompletion(request);
      return response.choices.first.message.content;
    } catch (e) {
      debugPrint('Ошибка при отправке сообщения в DeepSeek API: $e');
      return 'Произошла ошибка при обработке запроса. Пожалуйста, попробуйте позже.';
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

      final request = http.Request('POST', url);
      request.headers.addAll(headers);
      request.body = requestBody;

      final response = await http.Client().send(request);

      if (response.statusCode == 200) {
        await for (final chunk in response.stream.transform(utf8.decoder)) {
          // DeepSeek возвращает данные в формате SSE (Server-Sent Events)
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
        yield 'Ошибка стриминга: ${response.statusCode}';
      }
    } catch (e) {
      yield 'Произошла ошибка при обработке запроса: $e';
    }
  }

  /// Проверяет адекватность запроса пользователя и возвращает результат проверки
  Future<RequestValidationResponse> validateRequest(String request) async {
    try {
      final response = await sendMessage(
        agentType: AgentType.requestValidator,
        message: request,
      );

      // Пытаемся распарсить ответ как JSON
      try {
        return RequestValidationResponse.fromJson(response);
      } catch (e) {
        // Если не удалось распарсить как JSON, возвращаем стандартный формат
        return RequestValidationResponse.unknown(
          'Не удалось обработать ответ: $response',
        );
      }
    } catch (e) {
      return RequestValidationResponse.error('Ошибка при проверке запроса: $e');
    }
  }

  // Возвращает модель в зависимости от типа агента
  String _getModelByAgentType(AgentType agentType) {
    switch (agentType) {
      case AgentType.requestValidator:
        return 'deepseek-chat'; // Быстрый базовый агент для проверки запросов
      case AgentType.ichingInterpreter:
        return 'deepseek-chat'; // Агент для интерпретации результатов
      case AgentType.onboarding:
        return 'deepseek-chat'; // Агент для онбординга
    }
  }

  // Возвращает системный промпт в зависимости от типа агента
  String _getSystemPromptByAgentType(AgentType agentType) {
    switch (agentType) {
      case AgentType.requestValidator:
        return '''
Ты - агент проверки пользовательских запросов. Твоя задача - определить, является ли запрос пользователя адекватным и подходящим для гадания И-Цзин.

Правила:
1. Оценивай запрос с точки зрения его ясности, конкретности и этичности.
2. Не принимай запросы, содержащие угрозы, оскорбления, запросы на нелегальную деятельность.
3. Запросы должны быть связаны с поиском совета, мудрости или решения личной проблемы.

Твой ответ должен быть строго в следующем JSON формате:
{
  "status": "valid" или "invalid",
  "reasonMessage": "Объяснение, почему запрос принят или отклонен"
}
''';
      case AgentType.ichingInterpreter:
        return '''
Ты - эксперт по толкованию гексаграмм И-Цзин (Книги Перемен). Пользователь задал вопрос и получил гексаграмму. Твоя задача - интерпретировать эту гексаграмму в контексте вопроса пользователя.

Правила:
1. Объясни значение гексаграммы в целом.
2. Опиши, как это значение применимо к вопросу пользователя.
3. Предложи конкретные рекомендации на основе полученной гексаграммы.
4. Будь конкретным, но не директивным - предлагай возможные пути, но подчеркивай, что окончательное решение остается за пользователем.
''';
      case AgentType.onboarding:
        return '''
Ты - гид по гаданию И-Цзин. Твоя цель - помочь пользователю понять, что такое И-Цзин, как им пользоваться и что ожидать от результатов.

Правила:
1. Объясняй простым, понятным языком, избегая чрезмерно эзотерических терминов.
2. Рассказывай о традиции И-Цзин, его истории и значении.
3. Объясни, как формулировать вопросы для наилучших результатов.
4. Помогай пользователю понять, как интерпретировать полученные ответы.
''';
    }
  }
}
