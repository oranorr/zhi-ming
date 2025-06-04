import 'package:flutter/material.dart';
import 'package:zhi_ming/core/theme/theme_colors.dart';

class ZTextStyle extends TextStyle {
  const ZTextStyle.font({
    super.fontSize,
    super.height,
    FontWeight? fontWeight,
    Color? color,
    super.decoration,
  }) : super(
         inherit: false,
         color: color ?? ZColors.black,
         fontFamily: 'NotoSansSC',
         fontWeight: fontWeight ?? AppFontWeight.regular,
         textBaseline: TextBaseline.alphabetic,
       );
}

class AppFontWeight {
  AppFontWeight._();

  static const FontWeight thin = FontWeight.w100;
  static const FontWeight extraLight = FontWeight.w200;
  static const FontWeight light = FontWeight.w300;
  static const FontWeight demiLight = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;
  static const FontWeight black = FontWeight.w900;
}

TextStyle h1() => const ZTextStyle.font(
  fontSize: 32,
  fontWeight: AppFontWeight.demiLight,
  height: 48 / 32, // = 1.5
);

TextStyle h2() => const ZTextStyle.font(
  fontSize: 24,
  fontWeight: AppFontWeight.medium,
  height: 30 / 24, // = 1.25
);

TextStyle h3() => const ZTextStyle.font(
  fontSize: 22,
  fontWeight: AppFontWeight.demiLight,
  height: 28 / 22, // ≈ 1.27
);

TextStyle h4() => const ZTextStyle.font(
  fontSize: 20,
  fontWeight: AppFontWeight.demiLight,
  height: 24 / 20, // = 1.2
);

TextStyle lRegular() => const ZTextStyle.font(
  fontSize: 20,
  fontWeight: AppFontWeight.regular,
  height: 30 / 20, // = 1.5
);

TextStyle mRegular() => const ZTextStyle.font(
  fontSize: 18,
  fontWeight: AppFontWeight.regular,
  height: 28 / 18, // ≈ 1.56
);

TextStyle mMedium() => const ZTextStyle.font(
  fontSize: 16,
  fontWeight: AppFontWeight.medium,
  height: 24 / 16, // = 1.5
);

TextStyle mDemilight() => const ZTextStyle.font(
  fontSize: 16,
  fontWeight: AppFontWeight.demiLight,
  height: 24 / 16, // = 1.5
);

TextStyle sDemilight() => const ZTextStyle.font(
  fontSize: 14,
  fontWeight: AppFontWeight.demiLight,
  height: 22 / 14, // ≈ 1.57
);

TextStyle xsDemilight() => const ZTextStyle.font(
  fontSize: 12,
  fontWeight: AppFontWeight.demiLight,
  height: 16 / 12, // ≈ 1.33
);
