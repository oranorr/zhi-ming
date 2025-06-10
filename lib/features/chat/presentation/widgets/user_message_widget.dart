import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zhi_ming/core/extensions/build_context_extension.dart';
import 'package:zhi_ming/core/theme/theme_colors.dart';

/// [UserMessageWidget] Виджет для отображения сообщений пользователя
class UserMessageWidget extends StatelessWidget {
  const UserMessageWidget({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Контейнер с сообщением - он будет занимать только необходимое место
        // с максимальной шириной в 75% экрана
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: ZColors.yellowLight,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            child: Text(text, style: context.styles.mDemilight, softWrap: true),
          ),
        ),
      ],
    );
  }
}
