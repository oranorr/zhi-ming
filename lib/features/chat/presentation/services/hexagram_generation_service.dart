import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:zhi_ming/features/iching/models/hexagram.dart';

/// Сервис для генерации гексаграмм на основе значений линий
/// Отвечает за преобразование результатов бросков монет в гексаграммы
class HexagramGenerationService {
  /// Данные о гексаграммах из JSON-файла
  List<Map<String, dynamic>> _hexagramsData = [];

  /// Загрузка данных о гексаграммах из JSON-файла
  Future<void> loadHexagramsData() async {
    if (_hexagramsData.isNotEmpty) {
      debugPrint(
        '[HexagramGenerationService] Данные уже загружены, пропускаем',
      );
      return; // Если данные уже загружены, выходим
    }

    try {
      debugPrint('[HexagramGenerationService] Загружаем данные о гексаграммах');
      // Загружаем JSON-файл из assets
      final jsonString = await rootBundle.loadString(
        'assets/data/hexagrams.json',
      );
      // Парсим JSON и сохраняем данные о гексаграммах
      final List<dynamic> jsonData = jsonDecode(jsonString);
      _hexagramsData = jsonData.cast<Map<String, dynamic>>();
      debugPrint(
        '[HexagramGenerationService] Загружено ${_hexagramsData.length} гексаграмм',
      );
    } catch (e) {
      // В случае ошибки выводим сообщение и используем пустой список
      debugPrint(
        '[HexagramGenerationService] Ошибка загрузки данных о гексаграммах: $e',
      );
      _hexagramsData = [];
    }
  }

  /// Генерация гексаграммы на основе значений линий (6, 7, 8, 9)
  Future<HexagramPair> generateHexagramFromLines(List<int> lineValues) async {
    // Убеждаемся, что данные загружены
    await loadHexagramsData();

    // Преобразуем значения линий в объекты Line
    debugPrint(
      '[HexagramGenerationService] Начинаю генерацию гексаграммы из значений линий: $lineValues',
    );

    final lines = List<Line>.generate(6, (index) {
      if (index < lineValues.length) {
        final value = lineValues[index];
        Line line;
        switch (value) {
          case 6: // старый инь (изменяющийся)
            line = const Line(6);
            debugPrint(
              'Line ${index + 1}: значение линии $value -> 6 (инь, изменяющаяся)',
            );
            break;
          case 7: // молодой ян (неизменяющийся)
            line = const Line(7);
            debugPrint(
              'Line ${index + 1}: значение линии $value -> 7 (ян, неизменяющаяся)',
            );
            break;
          case 8: // молодой инь (неизменяющийся)
            line = const Line(8);
            debugPrint(
              'Line ${index + 1}: значение линии $value -> 8 (инь, неизменяющаяся)',
            );
            break;
          case 9: // старый ян (изменяющийся)
            line = const Line(9);
            debugPrint(
              'Line ${index + 1}: значение линии $value -> 9 (ян, изменяющаяся)',
            );
            break;
          default:
            line = const Line(8); // По умолчанию: инь, неизменяющаяся
            debugPrint(
              'Line ${index + 1}: неизвестное значение $value, использую по умолчанию -> 8 (инь, неизменяющаяся)',
            );
        }
        return line;
      } else {
        // Если данных от пользователя недостаточно, используем значение по умолчанию
        debugPrint(
          'Line ${index + 1}: недостаточно данных, использую значение по умолчанию -> 8 (инь, неизменяющаяся)',
        );
        return const Line(8); // инь, неизменяющаяся
      }
    });

    // Генерируем основную гексаграмму
    final primaryHexagram = _createHexagramFromLines(lines);

    // Проверяем, есть ли изменяющиеся линии
    Hexagram? secondaryHexagram;
    if (primaryHexagram.lines.any((line) => line.isChanging)) {
      debugPrint(
        '[HexagramGenerationService] Обнаружены изменяющиеся линии, создаем вторичную гексаграмму',
      );

      // Получаем измененные линии
      final changedLines =
          primaryHexagram.lines.map((line) => line.changedLine).toList();

      // Создаем вторичную гексаграмму
      secondaryHexagram = _createHexagramFromLines(changedLines);

      debugPrint(
        '[HexagramGenerationService] Вторичная гексаграмма: ${secondaryHexagram.number} (${secondaryHexagram.name})',
      );
    }

    return HexagramPair(primary: primaryHexagram, secondary: secondaryHexagram);
  }

  /// Создание гексаграммы из линий
  Hexagram _createHexagramFromLines(List<Line> lines) {
    // Создаем бинарное представление гексаграммы (для поиска в JSON)
    // ВАЖНО: Порядок линий в бинарном представлении - СНИЗУ ВВЕРХ
    String binaryRepresentation = '';
    for (int i = lines.length - 1; i >= 0; i--) {
      binaryRepresentation += lines[i].isYang ? '1' : '0';
    }

    debugPrint(
      '[HexagramGenerationService] Бинарное представление гексаграммы (снизу вверх): $binaryRepresentation',
    );

    // Ищем информацию о гексаграмме по бинарному представлению
    final hexagramInfo = _findHexagramByBinary(binaryRepresentation);

    if (hexagramInfo != null && hexagramInfo.isNotEmpty) {
      // Если нашли информацию, используем ее
      debugPrint(
        '[HexagramGenerationService] Найдена гексаграмма по бинарному представлению: ${hexagramInfo['number']} (${hexagramInfo['name']})',
      );
      return Hexagram(
        lines: lines,
        number: hexagramInfo['number'],
        name: hexagramInfo['name'],
        description: hexagramInfo['description'],
      );
    } else {
      // Если не нашли, вычисляем номер и используем временные данные
      int hexagramNumber = 1;
      int binaryValue = 0;

      // Вычисляем двоичное значение (снизу вверх)
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].isYang) {
          binaryValue |= 1 << i;
        }
      }

      // Преобразуем в номер гексаграммы (1-64)
      hexagramNumber = binaryValue + 1;

      debugPrint(
        '[HexagramGenerationService] Не найдена гексаграмма по бинарному представлению, вычисляю номер: $hexagramNumber (двоичное: $binaryValue)',
      );

      // Ищем информацию по номеру (на всякий случай)
      final hexagramInfoByNumber = _findHexagramByNumber(hexagramNumber);

      if (hexagramInfoByNumber != null && hexagramInfoByNumber.isNotEmpty) {
        debugPrint(
          '[HexagramGenerationService] Найдена гексаграмма по номеру: ${hexagramInfoByNumber['number']} (${hexagramInfoByNumber['name']})',
        );
        return Hexagram(
          lines: lines,
          number: hexagramInfoByNumber['number'],
          name: hexagramInfoByNumber['name'],
          description: hexagramInfoByNumber['description'],
        );
      }

      // Если всё равно не нашли, используем временные данные
      debugPrint(
        '[HexagramGenerationService] Не найдена гексаграмма ни по бинарному представлению, ни по номеру. Использую временные данные.',
      );
      return Hexagram(
        lines: lines,
        number: hexagramNumber,
        name: '第$hexagramNumber卦', // Временное имя: "Гексаграмма номер X"
        description:
            '此卦基于您的六次投币生成。', // "Эта гексаграмма создана на основе ваших шести бросков монет"
      );
    }
  }

  /// Поиск информации о гексаграмме по номеру
  Map<String, dynamic>? _findHexagramByNumber(int number) {
    if (_hexagramsData.isEmpty) return null;

    try {
      return _hexagramsData.firstWhere(
        (hexagram) => hexagram['number'] == number,
        orElse: () => {},
      );
    } catch (e) {
      debugPrint(
        '[HexagramGenerationService] Ошибка поиска гексаграммы по номеру: $e',
      );
      return null;
    }
  }

  /// Поиск информации о гексаграмме по бинарному представлению
  Map<String, dynamic>? _findHexagramByBinary(String binary) {
    if (_hexagramsData.isEmpty) return null;

    try {
      return _hexagramsData.firstWhere(
        (hexagram) => hexagram['binary'] == binary,
        orElse: () => {},
      );
    } catch (e) {
      debugPrint(
        '[HexagramGenerationService] Ошибка поиска гексаграммы по бинарному представлению: $e',
      );
      return null;
    }
  }
}

/// Класс для пары гексаграмм (основная и изменяющаяся)
class HexagramPair {
  const HexagramPair({required this.primary, this.secondary});

  final Hexagram primary;
  final Hexagram? secondary;

  /// Проверка наличия изменяющихся линий
  bool get hasChangingLines => secondary != null;
}
