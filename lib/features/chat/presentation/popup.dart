import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zhi_ming/core/extensions/build_context_extension.dart';
import 'package:zhi_ming/core/theme/theme_colors.dart';
import 'package:zhi_ming/core/services/shake_service/shaker_service_repo.dart';

class ShakePhoneWidget extends StatefulWidget {
  const ShakePhoneWidget({required this.shakeService, super.key});
  final ShakerServiceRepo shakeService;

  @override
  State<ShakePhoneWidget> createState() => ShakePhoneWidgetState();
}

class ShakePhoneWidgetState extends State<ShakePhoneWidget>
    with SingleTickerProviderStateMixin {
  bool isInitial = true;
  late StreamSubscription<int> _shakeSubscription;
  double _progress = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();

    _shakeSubscription = widget.shakeService.shakeCountStream.listen((count) {
      if (count > 0 && isInitial) {
        setState(() {
          isInitial = false;
        });
        _animationController.reset();
        _animationController.forward();
      }
      setState(() {
        _progress = count / widget.shakeService.maxShakeCount;
        if (_progress >= 1) {
          Navigator.of(context).pop();
        }
      });
    });
  }

  @override
  void dispose() {
    _shakeSubscription.cancel();
    _animationController.dispose();
    super.dispose();
  }

  bool get _canDismiss =>
      !isInitial &&
      widget.shakeService.currentShakeCount >=
          widget.shakeService.maxShakeCount;

  Future<void> _handleTap() async {
    if (!isInitial &&
        widget.shakeService.currentShakeCount <
            widget.shakeService.maxShakeCount) {
      await HapticFeedback.lightImpact();
      await widget.shakeService.shake();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          width: 330.w,
          height: 330.h,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFEEEFFF), Color(0xFFEDFFCC)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _canDismiss ? () => Navigator.of(context).pop() : null,
            child: Center(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: _handleTap,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 500),
                              child: Container(
                                key: ValueKey<bool>(isInitial),
                                width: 251.w,
                                height: 174.h,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color:
                                      !isInitial
                                          ? Colors.white.withOpacity(0.1)
                                          : null,
                                ),
                                child: Stack(
                                  children: [
                                    Image.asset(
                                      isInitial
                                          ? 'assets/shake.png'
                                          : 'assets/coins.png',
                                    ),
                                    if (!isInitial)
                                      Positioned.fill(
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            onTap: _handleTap,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 24.h),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              key: ValueKey<bool>(isInitial),
                              isInitial
                                  ? '摇动手机以投掷硬币。\n总共需要进行6次投掷。'
                                  : '摇动以进行下一次投掷或点击硬币\n已完成 ${widget.shakeService.currentShakeCount}/6 次',
                              style: context.styles.medium,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          if (!isInitial) ...[
                            SizedBox(height: 24.h),
                            SizedBox(
                              width: 175.w,
                              child: LinearProgressIndicator(
                                borderRadius: BorderRadius.circular(100),
                                value: _progress,
                                color: ZColors.blueDark,
                                backgroundColor: ZColors.gray,
                              ),
                            ),
                          ],
                          // if (_canDismiss) ...[
                          //   SizedBox(height: 16.h),
                          //   TextButton(
                          //     onPressed: () => Navigator.of(context).pop(),
                          //     child: Text(
                          //       '完成',
                          //       style: context.styles.medium.copyWith(
                          //         color: ZColors.blueDark,
                          //       ),
                          //     ),
                          //   ),
                          // ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
