// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:zhi_ming/core/extensions/build_context_extension.dart';
import 'package:zhi_ming/core/theme/theme_colors.dart';

class InputSendWidget extends StatefulWidget {
  const InputSendWidget({
    required this.onSend,
    required this.onTextChanged,
    required this.isSendAvailable,
    required this.currentInput,
    this.focusNode,
    super.key,
  });

  final VoidCallback onSend;
  final ValueChanged<String> onTextChanged;
  final bool isSendAvailable;
  final String currentInput;
  final FocusNode? focusNode;

  @override
  State<InputSendWidget> createState() => _InputSendWidgetState();
}

class _InputSendWidgetState extends State<InputSendWidget> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentInput);
    _controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(InputSendWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentInput != oldWidget.currentInput &&
        widget.currentInput != _controller.text) {
      _controller.text = widget.currentInput;
    }
  }

  void _onTextChanged() {
    widget.onTextChanged(_controller.text);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onTextChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      // height: 100.h,
      decoration: BoxDecoration(
        color: ZColors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12).copyWith(bottom: 0),
            child: TextInputWidget(
              controller: _controller,
              focusNode: widget.focusNode,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(0, 12.h, 8.w, 8.h),
                child: _SendButton(
                  isActive: widget.isSendAvailable,
                  onTap: widget.isSendAvailable ? widget.onSend : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TextInputWidget extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  const TextInputWidget({required this.controller, this.focusNode, super.key});

  @override
  Widget build(BuildContext context) {
    return TextField(
      // autofocus: true,
      maxLines: null,
      minLines: 1,
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
        hintText: '消息',
        hintStyle: context.styles.mRegular.copyWith(color: ZColors.purpleLight),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool isActive;
  final VoidCallback? onTap;
  const _SendButton({required this.isActive, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        width: 44.w,
        height: 44.h,
        decoration: BoxDecoration(
          color: isActive ? ZColors.purpleLight : ZColors.gray,
          shape: BoxShape.circle,
        ),
        duration: Durations.medium1,
        child: SvgPicture.asset(
          'assets/send.svg',
          fit: BoxFit.scaleDown,
          color: isActive ? ZColors.blueDark : ZColors.white,
        ),
      ),
    );
  }
}
