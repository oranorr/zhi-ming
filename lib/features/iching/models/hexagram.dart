import 'package:equatable/equatable.dart';

class Line extends Equatable {
  // true для 6 и 9, false для 7 и 8

  const Line(this.value) : isChanging = value == 6 || value == 9;
  final int value; // 6, 7, 8, 9
  final bool isChanging;

  bool get isYang => value == 7 || value == 9; // сплошная линия
  bool get isYin => value == 6 || value == 8; // прерывистая линия

  Line get changedLine =>
      isChanging
          ? Line(isYang ? 8 : 7) // 9 -> 8, 6 -> 7
          : this;

  @override
  List<Object?> get props => [value];
}

class Hexagram extends Equatable {
  const Hexagram({
    required this.lines,
    this.name,
    this.description,
    this.number,
  }) : assert(lines.length == 6, 'Гексаграмма должна содержать 6 линий');
  final List<Line> lines; // снизу вверх, размер всегда 6
  final String? name;
  final String? description;

  // ID в формате "000000" - "111111", где 0 = инь, 1 = ян
  String get binaryId => lines.map((line) => line.isYang ? '1' : '0').join();

  // Номер гексаграммы по традиционной нумерации (1-64)
  final int? number;

  // Создаёт вторую гексаграмму на основе изменяющихся линий
  Hexagram get changedHexagram {
    final hasChangingLines = lines.any((line) => line.isChanging);
    if (!hasChangingLines) return this;

    return Hexagram(lines: lines.map((line) => line.changedLine).toList());
  }

  @override
  List<Object?> get props => [lines];
}
