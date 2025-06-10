import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:zhi_ming/core/extensions/build_context_extension.dart';
import 'package:zhi_ming/core/theme/theme_colors.dart';
import 'package:zhi_ming/features/chat/domain/chat_entrypoint_entity.dart';

/// [ChatAppBar] Кастомная шапка для экрана чата
class ChatAppBar extends StatelessWidget {
  const ChatAppBar({
    required this.entrypoint,
    required this.onBackPressed,
    this.onClearChatPressed,
    super.key,
  });

  final ChatEntrypointEntity entrypoint;
  final VoidCallback onBackPressed;
  final VoidCallback? onClearChatPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Левая часть - кнопка назад
        GestureDetector(
          onTap: onBackPressed,
          child: Row(
            children: [
              SvgPicture.asset('assets/arrow-left.svg'),
              SizedBox(width: 8.w),
              Text(
                entrypoint.isReadOnlyMode ? '历史' : '首页',
                style: context.styles.h2,
              ),
            ],
          ),
        ),

        // Правая часть - кнопка очистки чата Ба-Дзы (только в дебаге)
        if (kDebugMode &&
            entrypoint is BaDzyEntrypointEntity &&
            onClearChatPressed != null)
          GestureDetector(
            onTap: onClearChatPressed,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: ZColors.pinkDark.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ZColors.pinkDark.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.clear_all, size: 16.w, color: ZColors.pinkDark),
                  SizedBox(width: 4.w),
                  Text(
                    'DEBUG',
                    style: context.styles.xsDemilight.copyWith(
                      color: ZColors.pinkDark,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
