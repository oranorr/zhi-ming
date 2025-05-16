import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:zhi_ming/features/iching/models/hexagram.dart';

class IChingService {
  static final Random _random = Random();
  static const List<int> _coinValues = [2, 3]; // 2=инь, 3=ян

  // Все гексаграммы (загружаются из JSON)
  List<Hexagram>? _allHexagrams;

  // Генерация одного броска монет (возвращает значение линии: 6, 7, 8 или 9)
  int throwCoins() {
    // Бросаем 3 монеты и суммируем значения (каждая монета: 2=инь или 3=ян)
    final results = List.generate(3, (_) => _coinValues[_random.nextInt(2)]);
    final sum = results.reduce((a, b) => a + b);

    // Конвертируем сумму в тип линии
    return sum;
  }

  // Заполняет информацию о гексаграмме и её изменяющейся форме из базы данных
  Future<(Hexagram, Hexagram?)> fillHexagramInfo(Hexagram hexagram) async {
    // Убеждаемся, что гексаграммы загружены
    await _loadHexagramsIfNeeded();

    // Находим соответствующую гексаграмму из базы по бинарному коду
    final baseHexagram = _findHexagramByBinaryId(hexagram.binaryId);
    final filledHexagram = Hexagram(
      lines: hexagram.lines,
      name: baseHexagram?.name,
      description: baseHexagram?.description,
      number: baseHexagram?.number,
    );

    // Проверяем есть ли изменяющиеся линии
    final hasChangingLines = hexagram.lines.any((line) => line.isChanging);
    if (!hasChangingLines) {
      return (filledHexagram, null);
    }

    // Создаем измененную гексаграмму и находим соответствующую в базе
    final changedHexagram = filledHexagram.changedHexagram;
    final baseChangedHexagram = _findHexagramByBinaryId(
      changedHexagram.binaryId,
    );

    final filledChangedHexagram = Hexagram(
      lines: changedHexagram.lines,
      name: baseChangedHexagram?.name,
      description: baseChangedHexagram?.description,
      number: baseChangedHexagram?.number,
    );

    return (filledHexagram, filledChangedHexagram);
  }

  // Генерация полной гексаграммы (6 бросков)
  Future<(Hexagram, Hexagram?)> generateHexagram() async {
    // Ensure hexagrams are loaded
    await _loadHexagramsIfNeeded();

    // Генерируем 6 бросков монет (снизу вверх)
    final lineValues = List.generate(6, (_) => throwCoins());
    final lines = lineValues.map((value) => Line(value)).toList();

    // Создаем исходную гексаграмму
    final hexagram = Hexagram(lines: lines);

    return fillHexagramInfo(hexagram);
  }

  // Загрузка всех гексаграмм из JSON файла
  Future<void> _loadHexagramsIfNeeded() async {
    if (_allHexagrams != null) return;

    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/hexagrams.json',
      );
      final List<dynamic> jsonList = json.decode(jsonString);

      _allHexagrams =
          jsonList.map((json) {
            // Конвертируем бинарный ID в список линий
            final String binaryId = json['binary'] as String;
            final lines =
                binaryId.split('').map((bit) {
                  return Line(
                    bit == '1' ? 7 : 8,
                  ); // Используем немутирующие линии (7=ян, 8=инь)
                }).toList();

            return Hexagram(
              lines: lines,
              name: json['name'] as String?,
              description: json['description'] as String?,
              number: json['number'] as int?,
            );
          }).toList();
    } catch (e) {
      print('Ошибка загрузки гексаграмм: $e');
      _allHexagrams = [];
    }
  }

  // Поиск гексаграммы по бинарному ID
  Hexagram? _findHexagramByBinaryId(String binaryId) {
    return _allHexagrams?.firstWhere(
      (h) => h.binaryId == binaryId,
      orElse:
          () => Hexagram(
            lines:
                binaryId.split('').map((bit) {
                  return Line(bit == '1' ? 7 : 8);
                }).toList(),
          ),
    );
  }
}
