// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:zhi_ming/core/extensions/build_context_extension.dart';

class QuestionEntity {
  final String title;
  final String subtitle;
  final Color backColor;
  final Color arrowColor;

  QuestionEntity({
    required this.title,
    required this.subtitle,
    required this.backColor,
    required this.arrowColor,
  });

  Widget buildTile(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Container(
            width: double.infinity,
            height: 70.h,
            decoration: BoxDecoration(
              color: backColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 12.h),
              child: Row(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: context.styles.medium),
                      // SizedBox(height: 12.h),
                      Text(subtitle, style: context.styles.small),
                    ],
                  ),
                  Spacer(),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: arrowColor),
                    ),
                    padding: EdgeInsets.all(12.w),
                    child: SvgPicture.asset('assets/arrow-right.svg'),
                  ),
                  // Text()
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 12.h),
      ],
    );
  }
}
