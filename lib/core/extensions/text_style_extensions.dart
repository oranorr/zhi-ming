// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

class ZTexts extends ThemeExtension<ZTexts> {
  final TextStyle h1;
  final TextStyle h2;
  final TextStyle h3;
  final TextStyle regular;
  final TextStyle medium;
  final TextStyle mediumDemilight;
  final TextStyle small;
  ZTexts({
    required this.h1,
    required this.h2,
    required this.h3,
    required this.regular,
    required this.medium,
    required this.mediumDemilight,
    required this.small,
  });

  @override
  ZTexts copyWith({
    TextStyle? h1,
    TextStyle? h2,
    TextStyle? h3,
    TextStyle? regular,
    TextStyle? medium,
    TextStyle? mediumDemilight,
    TextStyle? small,
  }) {
    return ZTexts(
      h1: h1 ?? this.h1,
      h2: h2 ?? this.h2,
      h3: h3 ?? this.h3,
      regular: regular ?? this.regular,
      medium: medium ?? this.medium,
      mediumDemilight: mediumDemilight ?? this.mediumDemilight,
      small: small ?? this.small,
    );
  }

  @override
  ThemeExtension<ZTexts> lerp(
    covariant ThemeExtension<ZTexts>? other,
    double t,
  ) {
    if (other == null || other is! ZTexts) {
      return this;
    }

    return ZTexts(
      h1: TextStyle.lerp(h1, other.h1, t)!,
      h2: TextStyle.lerp(h2, other.h2, t)!,
      h3: TextStyle.lerp(h3, other.h3, t)!,
      regular: TextStyle.lerp(regular, other.regular, t)!,
      medium: TextStyle.lerp(medium, other.medium, t)!,
      mediumDemilight:
          TextStyle.lerp(mediumDemilight, other.mediumDemilight, t)!,
      small: TextStyle.lerp(small, other.small, t)!,
    );
  }
}
