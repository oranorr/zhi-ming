import 'package:flutter/material.dart';
import 'package:zhi_ming/core/extensions/text_style_extensions.dart';
import 'package:zhi_ming/core/theme/z_text_styles.dart';

extension BuildContextExtension on BuildContext {
  ThemeData get theme => Theme.of(this);

  /// Безопасный доступ к стилям с fallback значениями
  ZTexts get styles {
    final zTexts = theme.extension<ZTexts>();

    // Если extension не найден, возвращаем fallback стили
    if (zTexts == null) {
      print(
        '[BuildContextExtension] ZTexts extension не найден, используем fallback стили',
      );
      return ZTexts(
        h1: h1(),
        h2: h2(),
        h3: h3(),
        h4: h4(),
        lRegular: lRegular(),
        mRegular: mRegular(),
        mMedium: mMedium(),
        mDemilight: mDemilight(),
        sDemilight: sDemilight(),
        xsDemilight: xsDemilight(),
      );
    }

    return zTexts;
  }

  Brightness get brightness => MediaQuery.of(this).platformBrightness;

  Size get size => MediaQuery.of(this).size;

  EdgeInsets get viewInsets => MediaQuery.of(this).viewInsets;

  double get height => MediaQuery.of(this).size.height;

  double get width => MediaQuery.of(this).size.width;
}
