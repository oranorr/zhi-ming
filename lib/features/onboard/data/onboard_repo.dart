import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zhi_ming/core/extensions/build_context_extension.dart';
import 'package:zhi_ming/core/theme/theme_colors.dart';

class OnboardRepo {
  static List<Interest> interests = [
    Interest(
      name: '塔罗牌',
      asset: 'assets/icons/candle.png',
      color: ZColors.blueLight,
    ),
    Interest(
      name: '星座',
      asset: 'assets/icons/stairs.png',
      color: ZColors.purpleMiddle,
    ),
    Interest(
      name: '命理',
      asset: 'assets/icons/flower.png',
      color: ZColors.pinkLight,
    ),
    Interest(
      name: '易经',
      asset: 'assets/scroll.png',
      color: ZColors.yellowMiddle,
    ),
    Interest(
      name: '占星',
      asset: 'assets/icons/image 133.png',
      color: ZColors.purpleLight,
    ),
    Interest(
      name: '手相',
      asset: 'assets/icons/human.png',
      color: ZColors.pinkDark,
    ),
    Interest(
      name: '面相',
      asset: 'assets/icons/heart.png',
      color: ZColors.blueMiddle,
    ),
    Interest(
      name: '风水',
      asset: 'assets/icons/flower_2.png',
      color: ZColors.yellowLight,
    ),
    Interest(
      name: '梦境',
      asset: 'assets/icons/kite.png',
      color: ZColors.purpleMiddle,
    ),
    Interest(
      name: '灵数',
      asset: 'assets/icons/weights.png',
      color: ZColors.blueDark,
    ),
    Interest(name: '算命', asset: 'assets/coins.png', color: ZColors.pinkMiddle),
    Interest(
      name: '紫微斗数',
      asset: 'assets/icons/candle.png',
      color: ZColors.yellowMiddle,
    ),
    Interest(
      name: '水晶球',
      asset: 'assets/icons/image 133.png',
      color: ZColors.blueLight,
    ),
    Interest(
      name: '生辰八字',
      asset: 'assets/scroll.png',
      color: ZColors.purpleLight,
    ),
    Interest(
      name: '符咒',
      asset: 'assets/icons/flower.png',
      color: ZColors.pinkDark,
    ),
    Interest(
      name: '茶叶占卜',
      asset: 'assets/icons/kite.png',
      color: ZColors.blueMiddle,
    ),
    Interest(
      name: '八卦',
      asset: 'assets/icons/weights.png',
      color: ZColors.purpleMiddle,
    ),
    Interest(
      name: '六爻',
      asset: 'assets/icons/stairs.png',
      color: ZColors.yellowLight,
    ),
    Interest(
      name: '姓名学',
      asset: 'assets/icons/human.png',
      color: ZColors.pinkMiddle,
    ),
    Interest(
      name: '灵摆',
      asset: 'assets/icons/heart.png',
      color: ZColors.blueDark,
    ),
  ];
}

class Interest {
  Interest({required this.name, required this.asset, required this.color});
  final String name;
  final String asset;
  final Color color;
}

class InterestChip extends StatefulWidget {
  InterestChip({
    required this.interest,
    required this.isSelected,
    super.key,
    this.onSelectionChanged,
  });
  final Interest interest;
  bool isSelected;
  final Function(Interest, bool)? onSelectionChanged;

  @override
  State<InterestChip> createState() => _InterestChipState();
}

class _InterestChipState extends State<InterestChip> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          widget.isSelected = !widget.isSelected;
        });

        if (widget.onSelectionChanged != null) {
          widget.onSelectionChanged!(widget.interest, widget.isSelected);
        }
      },
      child: Container(
        height: 36.h,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: widget.interest.color,
          borderRadius: BorderRadius.circular(50.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: 24.w,
              height: 24.h,
              child: Image.asset(widget.interest.asset),
            ),
            // SizedBox(width: 5.w),
            Text(widget.interest.name, style: context.styles.mediumDemilight),
            SizedBox(width: 10.w),
            Container(
              width: 24.r,
              height: 24.r,
              decoration: BoxDecoration(
                color: widget.isSelected ? ZColors.blueDark : ZColors.white,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child:
                  widget.isSelected
                      ? Icon(
                        Icons.check,
                        size: 16.r,
                        color: widget.interest.color,
                      )
                      : null,
            ),
            // Container(
            //   width: 24.w,
            //   height: 24.h,
            //   decoration:
            // ),
          ],
        ),
      ),
    );
  }
}
