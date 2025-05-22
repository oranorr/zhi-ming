import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:json_annotation/json_annotation.dart';

part 'hexagram.g.dart';

@JsonSerializable()
class Line extends Equatable {
  // true для 6 и 9, false для 7 и 8

  const Line(this.value) : isChanging = value == 6 || value == 9;

  factory Line.fromJson(Map<String, dynamic> json) => _$LineFromJson(json);
  Map<String, dynamic> toJson() => _$LineToJson(this);

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

@JsonSerializable()
class Hexagram extends Equatable {
  const Hexagram({
    required this.lines,
    this.name,
    this.description,
    this.number,
    this.interpretation,
  }) : assert(lines.length == 6, 'Гексаграмма должна содержать 6 линий');

  factory Hexagram.fromJson(Map<String, dynamic> json) =>
      _$HexagramFromJson(json);
  Map<String, dynamic> toJson() => _$HexagramToJson(this);

  final List<Line> lines; // снизу вверх, размер всегда 6
  final String? name;
  final String? description;
  final String? interpretation;

  // ID в формате "000000" - "111111", где 0 = инь, 1 = ян
  String get binaryId => lines.map((line) => line.isYang ? '1' : '0').join();

  // Номер гексаграммы по традиционной нумерации (1-64)
  final int? number;

  // Создаёт копию гексаграммы с новой интерпретацией
  Hexagram copyWith({
    List<Line>? lines,
    String? name,
    String? description,
    String? interpretation,
    int? number,
  }) {
    return Hexagram(
      lines: lines ?? this.lines,
      name: name ?? this.name,
      description: description ?? this.description,
      interpretation: interpretation ?? this.interpretation,
      number: number ?? this.number,
    );
  }

  // Создаёт вторую гексаграмму на основе изменяющихся линий
  Hexagram get changedHexagram {
    final hasChangingLines = lines.any((line) => line.isChanging);
    if (!hasChangingLines) return this;

    return Hexagram(
      lines: lines.map((line) => line.changedLine).toList(),
      name: name,
      description: description,
      interpretation: interpretation,
      number: number,
    );
  }

  // Виджет для отображения интерпретации с поддержкой маркдауна
  Widget buildInterpretation(BuildContext context) {
    if (interpretation == null || interpretation!.isEmpty) {
      return const SizedBox.shrink();
    }

    return MarkdownBody(
      data: interpretation!,
      styleSheet: MarkdownStyleSheet(
        p: Theme.of(context).textTheme.bodyLarge,
        h1: Theme.of(context).textTheme.headlineMedium,
        h2: Theme.of(context).textTheme.headlineSmall,
        h3: Theme.of(context).textTheme.titleLarge,
        blockquote: Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontStyle: FontStyle.italic,
          color: Theme.of(context).colorScheme.secondary,
        ),
        code: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontFamily: 'monospace',
          backgroundColor:
              Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        codeblockDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      selectable: true,
    );
  }

  @override
  List<Object?> get props => [lines, name, description, interpretation, number];
}
