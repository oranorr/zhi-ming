// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zhi_ming/core/extensions/build_context_extension.dart';
import 'package:zhi_ming/core/theme/theme_colors.dart';

class Zbutton extends StatefulWidget {
  final VoidCallback action;
  final bool isLoading;
  final bool isActive;
  final String text;
  final Color? color;
  final Color? textColor;
  const Zbutton({
    super.key,
    required this.action,
    required this.isLoading,
    required this.isActive,
    required this.text,
    this.color,
    this.textColor,
  });

  @override
  State<Zbutton> createState() => _ZbuttonState();
}

class _ZbuttonState extends State<Zbutton> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isActive ? widget.action : null,
      child: Container(
        width: double.infinity,
        height: 56.h,
        decoration: BoxDecoration(
          color: widget.color ?? ZColors.blueDark,
          borderRadius: BorderRadius.circular(85),
        ),
        child: Center(
          child: Text(
            widget.text,
            style: context.styles.regular.copyWith(color: widget.textColor),
          ),
        ),
      ),
    );
  }
}
