import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zhi_ming/core/extensions/build_context_extension.dart';
import 'package:zhi_ming/core/theme/theme_colors.dart';

class OnboardRepo {
  static List<Interest> interests = [
    Interest(
      name: '爱情与关系',
      asset: 'assets/icons/love.png',
      color: ZColors.purpleMiddle,
    ),
    Interest(
      name: '职业与事业',
      asset: 'assets/icons/career.png',
      color: ZColors.blueDark,
    ),
    Interest(
      name: '财富与运势',
      asset: 'assets/icons/money.png',
      color: ZColors.purpleLight,
    ),
    Interest(
      name: '自我成长与内在平衡',
      asset: 'assets/icons/harmony.png',
      color: ZColors.pinkMiddle,
    ),
    Interest(
      name: '家庭与住房',
      asset: 'assets/icons/home.png',
      color: ZColors.yellowLight,
    ),
    Interest(
      name: '未来预测',
      asset: 'assets/icons/future.png',
      color: ZColors.pinkDark,
    ),
    Interest(
      name: '教育与自我实现',
      asset: 'assets/icons/study.png',
      color: ZColors.blueLight,
    ),
    Interest(
      name: '旅行与搬迁',
      asset: 'assets/icons/travel.png',
      color: ZColors.purpleMiddle,
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
        height: 45.h,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: widget.interest.color,
          borderRadius: BorderRadius.circular(50.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox.square(
              dimension: 24.r,
              child: Image.asset(widget.interest.asset),
            ),
            // SizedBox(width: 5.w),
            SizedBox(width: 10.w),
            Text(
              widget.interest.name,
              style: context.styles.xsDemilight.copyWith(height: 1),
            ),
            SizedBox(width: 10.w),
            SizedBox.square(
              dimension: 20.r,
              child: DecoratedBox(
                // width: 20.w,
                // height: 20.h,
                decoration: BoxDecoration(
                  color: widget.isSelected ? ZColors.blueDark : ZColors.white,

                  borderRadius: BorderRadius.circular(6),
                  border:
                      widget.isSelected
                          ? null
                          : Border.all(color: ZColors.gray),
                  // shape:
                ),
                child:
                    widget.isSelected
                        ? Icon(Icons.check, size: 20.r, color: Colors.white)
                        : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
