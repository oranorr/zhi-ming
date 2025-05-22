import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:zhi_ming/core/extensions/build_context_extension.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zhi_ming/core/theme/theme_colors.dart';
import 'package:zhi_ming/core/widgets/z_button.dart';

class ZDatePicker extends StatefulWidget {
  const ZDatePicker({super.key});

  @override
  State<ZDatePicker> createState() => _ZDatePickerState();
}

class _ZDatePickerState extends State<ZDatePicker> {
  DateTime _selectedDate = DateTime(2021, 9, 17);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 420.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFEEEFFF), // голубой
            Color(0xFFEDFFCC), // салатовый
          ],
          stops: [0.0, 1.0],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 24.h),
          Text('你的出生日期是什么?', style: context.styles.h1),
          SizedBox(height: 16.h),
          SizedBox(
            height: 240.h,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              initialDateTime: _selectedDate,
              maximumDate: DateTime.now(),
              minimumDate: DateTime(1900),
              onDateTimeChanged: (date) {
                setState(() {
                  _selectedDate = date;
                });
              },
            ),
          ),
          SizedBox(height: 24.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Zbutton(
              action: () {
                Navigator.of(context).pop(_selectedDate);
              },
              isLoading: false,
              isActive: true,
              text: '保存',
              color: const Color(0xFF7C7CFF),
              textColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
