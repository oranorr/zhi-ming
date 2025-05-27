import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zhi_ming/core/theme/theme_colors.dart';

class ZTimePicker extends StatefulWidget {
  const ZTimePicker({super.key, this.onTimeChanged, this.initialTime});

  final Function(TimeOfDay)? onTimeChanged;
  final TimeOfDay? initialTime;

  @override
  State<ZTimePicker> createState() => _ZTimePickerState();
}

class _ZTimePickerState extends State<ZTimePicker> {
  late TimeOfDay _selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedTime = widget.initialTime ?? const TimeOfDay(hour: 12, minute: 0);
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
        mode: CupertinoDatePickerMode.time,
        initialDateTime: DateTime(
          2024,
          1,
          1,
          _selectedTime.hour,
          _selectedTime.minute,
        ),
        onDateTimeChanged: (datetime) {
          if (mounted) {
            final newTime = TimeOfDay(
              hour: datetime.hour,
              minute: datetime.minute,
            );
            setState(() {
              _selectedTime = newTime;
            });
            if (widget.onTimeChanged != null) {
              widget.onTimeChanged!(newTime);
            }
          }
        },
      ),
    );
  }
}
