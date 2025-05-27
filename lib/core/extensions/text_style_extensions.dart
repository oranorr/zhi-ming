// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

class ZTexts extends ThemeExtension<ZTexts> {
  final TextStyle h1;
  final TextStyle h2;
  final TextStyle h3;
  final TextStyle h4;
  final TextStyle lRegular;
  final TextStyle mRegular;
  final TextStyle mMedium;
  final TextStyle mDemilight;
  final TextStyle sDemilight;
  final TextStyle xsDemilight;

  ZTexts({
    required this.h1,
    required this.h2,
    required this.h3,
    required this.h4,
    required this.lRegular,
    required this.mRegular,
    required this.mMedium,
    required this.mDemilight,
    required this.sDemilight,
    required this.xsDemilight,
  });

  @override
  ZTexts copyWith({
    TextStyle? h1,
    TextStyle? h2,
    TextStyle? h3,
    TextStyle? h4,
    TextStyle? lRegular,
    TextStyle? mRegular,
    TextStyle? mMedium,
    TextStyle? mDemilight,
    TextStyle? sDemilight,
    TextStyle? xsDemilight,
  }) {
    return ZTexts(
      h1: h1 ?? this.h1,
      h2: h2 ?? this.h2,
      h3: h3 ?? this.h3,
      h4: h4 ?? this.h4,
      lRegular: lRegular ?? this.lRegular,
      mRegular: mRegular ?? this.mRegular,
      mMedium: mMedium ?? this.mMedium,
      mDemilight: mDemilight ?? this.mDemilight,
      sDemilight: sDemilight ?? this.sDemilight,
      xsDemilight: xsDemilight ?? this.xsDemilight,
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
      h4: TextStyle.lerp(h4, other.h4, t)!,
      lRegular: TextStyle.lerp(lRegular, other.lRegular, t)!,
      mRegular: TextStyle.lerp(mRegular, other.mRegular, t)!,
      mMedium: TextStyle.lerp(mMedium, other.mMedium, t)!,
      mDemilight: TextStyle.lerp(mDemilight, other.mDemilight, t)!,
      sDemilight: TextStyle.lerp(sDemilight, other.sDemilight, t)!,
      xsDemilight: TextStyle.lerp(xsDemilight, other.xsDemilight, t)!,
    );
  }
}
