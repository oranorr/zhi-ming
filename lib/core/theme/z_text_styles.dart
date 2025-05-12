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
       );
}

class AppFontWeight {
  AppFontWeight._();
  static const FontWeight demiLight = FontWeight.w300;
  static const FontWeight regular = FontWeight.w600;
  static const FontWeight medium = FontWeight.w800;
}

TextStyle h1() => ZTextStyle.font(
  fontSize: 32,
  fontWeight: AppFontWeight.demiLight,
  height: 48 / 32, // = 1.5
);

TextStyle h2() => ZTextStyle.font(
  fontSize: 22,
  fontWeight: AppFontWeight.demiLight,
  height: 28 / 22,
);

TextStyle h3() => ZTextStyle.font(
  fontSize: 20,
  fontWeight: AppFontWeight.demiLight,
  height: 24 / 20,
);

TextStyle regular() => ZTextStyle.font(
  fontSize: 20,
  fontWeight: AppFontWeight.regular,
  height: 30 / 20,
);

TextStyle medium() => ZTextStyle.font(
  fontSize: 16,
  fontWeight: AppFontWeight.medium,
  height: 24 / 16,
);

TextStyle mediumDemilight() => ZTextStyle.font(
  fontSize: 16,
  fontWeight: AppFontWeight.demiLight,
  height: 24 / 16,
);

TextStyle small() => ZTextStyle.font(
  fontSize: 14,
  fontWeight: AppFontWeight.demiLight,
  height: 22 / 14,
);
