import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zhi_ming/core/theme/theme_colors.dart';

class ZDatePicker extends StatefulWidget {
  const ZDatePicker({super.key, this.onDateChanged, this.initialDate});

  final Function(DateTime)? onDateChanged;
  final DateTime? initialDate;

  @override
  State<ZDatePicker> createState() => _ZDatePickerState();
}

class _ZDatePickerState extends State<ZDatePicker> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime(2021, 9, 17);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 213.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: ZColors.white,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CupertinoDatePicker(
        mode: CupertinoDatePickerMode.date,
        initialDateTime: _selectedDate,
        maximumDate: DateTime.now(),
        minimumDate: DateTime(1900),
        onDateTimeChanged: (date) {
          if (mounted) {
            setState(() {
              _selectedDate = date;
            });
            if (widget.onDateChanged != null) {
              widget.onDateChanged!(date);
            }
          }
        },
      ),
    );
  }
}
