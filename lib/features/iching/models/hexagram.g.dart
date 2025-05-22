// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hexagram.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Line _$LineFromJson(Map<String, dynamic> json) =>
    Line((json['value'] as num).toInt());

Map<String, dynamic> _$LineToJson(Line instance) => <String, dynamic>{
  'value': instance.value,
};

Hexagram _$HexagramFromJson(Map<String, dynamic> json) => Hexagram(
  lines:
      (json['lines'] as List<dynamic>)
          .map((e) => Line.fromJson(e as Map<String, dynamic>))
          .toList(),
  name: json['name'] as String?,
  description: json['description'] as String?,
  number: (json['number'] as num?)?.toInt(),
  interpretation: json['interpretation'] as String?,
);

Map<String, dynamic> _$HexagramToJson(Hexagram instance) => <String, dynamic>{
  'lines': instance.lines,
  'name': instance.name,
  'description': instance.description,
  'interpretation': instance.interpretation,
  'number': instance.number,
};
