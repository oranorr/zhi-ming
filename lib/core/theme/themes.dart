import 'package:flutter/material.dart';
import 'package:zhi_ming/core/extensions/text_style_extensions.dart';
import 'package:zhi_ming/core/theme/z_text_styles.dart';

final class AppTheme {
  static ThemeData light() => ThemeData().copyWith(
    extensions: <ThemeExtension>[
      ZTexts(
        h1: h1(),
        h2: h2(),
        h3: h3(),
        regular: regular(),
        medium: medium(),
        mediumDemilight: mediumDemilight(),
        small: small(),
      ),
    ],
  );
}
