import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:zhi_ming/core/extensions/build_context_extension.dart';
import 'package:zhi_ming/features/chat/domain/chat_entrypoint_entity.dart';
import 'package:zhi_ming/features/chat/presentation/chat_cubit.dart';
import 'package:zhi_ming/features/chat/presentation/chat_screen.dart';

class QuestionEntity {
  QuestionEntity({
    required this.title,
    required this.subtitle,
    required this.backColor,
    required this.arrowColor,
  });
  final String title;
  final String subtitle;
  final Color backColor;
  final Color arrowColor;

  Widget buildTile(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: GestureDetector(
            onTap: () {
              // Создаем CardEntrypointEntity с предварительно заданным вопросом (title)
              final entrypoint = CardEntrypointEntity(
                predefinedQuestion: title,
              );

              // Открываем экран чата и передаем entrypoint
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (context) => BlocProvider<ChatCubit>(
                        create: (context) => ChatCubit(),
                        child: ChatScreen(entrypoint: entrypoint),
                      ),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(minHeight: 75.h),
              decoration: BoxDecoration(
                color: backColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 12.h),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            style: context.styles.mMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            subtitle,
                            style: context.styles.sDemilight,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: arrowColor),
                      ),
                      padding: EdgeInsets.all(12.w),
                      child: SvgPicture.asset(
                        'assets/arrow-right.svg',
                        color: arrowColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 12.h),
      ],
    );
  }
}
