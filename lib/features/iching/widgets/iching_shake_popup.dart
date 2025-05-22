import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zhi_ming/core/extensions/build_context_extension.dart';
import 'package:zhi_ming/core/theme/theme_colors.dart';
import 'package:zhi_ming/core/services/shake_service/shaker_service_repo.dart';
import 'dart:developer' as developer;

class IChingShakePopup extends StatefulWidget {
  const IChingShakePopup({
    required this.shakeService,
    required this.onLineGenerated,
    required this.currentLine,
    required this.totalLines,
    super.key,
  });

  final ShakerServiceRepo shakeService;
  final Function(int lineValue) onLineGenerated;
  final int currentLine;
  final int totalLines;

  @override
  State<IChingShakePopup> createState() => _IChingShakePopupState();
}

class _IChingShakePopupState extends State<IChingShakePopup>
    with SingleTickerProviderStateMixin {
  bool isInitial = true;
  late StreamSubscription<int> _shakeSubscription;
  double _progress = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // Состояния монет: true = heads (Ян = 3), false = tails (Инь = 2)
  final List<bool> _coinsState = [false, false, false];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupShakeSubscription();
  }

  void _setupAnimations() {
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
  }

  void _setupShakeSubscription() {
    _shakeSubscription = widget.shakeService.shakeCountStream.listen((count) {
      developer.log(
        'Встряхивание: $count из ${widget.shakeService.maxShakeCount}',
      );

      if (count > 0 && isInitial) {
        setState(() {
          isInitial = false;
        });
        _animationController.reset();
        _animationController.forward();
      }

      // Обновляем состояние монет при каждом встряхивании
      if (count > 0 && !isInitial) {
        _updateCoinsState();
      }

      setState(() {
        _progress = count / widget.shakeService.maxShakeCount;
        if (_progress >= 1) {
          _finishAndGenerateLine();
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
    if (widget.shakeService.currentShakeCount <
        widget.shakeService.maxShakeCount) {
      await HapticFeedback.lightImpact();
      await widget.shakeService.shake();
      developer.log(
        'Тап по монетам: счетчик=${widget.shakeService.currentShakeCount}',
      );
    }
  }

  void _updateCoinsState() {
    setState(() {
      // Используем настоящую случайность вместо детерминированного подхода
      final random = Random();
      _coinsState[0] = random.nextBool();
      _coinsState[1] = random.nextBool();
      _coinsState[2] = random.nextBool();

      developer.log(
        'Состояние монет после встряхивания ${widget.shakeService.currentShakeCount}: '
        '${_coinsState[0] ? "Ян(3)" : "Инь(2)"}, '
        '${_coinsState[1] ? "Ян(3)" : "Инь(2)"}, '
        '${_coinsState[2] ? "Ян(3)" : "Инь(2)"}',
      );
    });
  }

  void _finishAndGenerateLine() {
    final List<int> coinValues =
        _coinsState.map((isHeads) => isHeads ? 3 : 2).toList();

    final sum = coinValues.reduce((a, b) => a + b);

    _logFinalCoinState(coinValues, sum);

    // Сохраняем результат броска (3 монеты) в сервисе
    widget.shakeService.saveCoinThrow(coinValues);
    developer.log(
      'Результат броска ${widget.currentLine} сохранен в ShakerService: $coinValues (сумма: $sum)',
    );

    // Небольшая задержка для отображения результата броска
    Future.delayed(const Duration(milliseconds: 800), () {
      Navigator.of(context).pop();
      widget.onLineGenerated(sum);
    });
  }

  void _logFinalCoinState(List<int> coinValues, int sum) {
    developer.log(
      'Финальное состояние монет: '
      '${_coinsState[0] ? "Ян(3)" : "Инь(2)"}, '
      '${_coinsState[1] ? "Ян(3)" : "Инь(2)"}, '
      '${_coinsState[2] ? "Ян(3)" : "Инь(2)"}',
    );
    developer.log(
      'Значения монет: $coinValues, сумма для генерации линии: $sum',
    );

    // Добавим более подробное логирование
    String lineType;
    switch (sum) {
      case 6: // 3 монеты Инь (2+2+2)
        lineType = 'инь, изменяющаяся (6)';
        break;
      case 7: // 2 монеты Инь, 1 монета Ян (2+2+3)
        lineType = 'ян, неизменяющаяся (7)';
        break;
      case 8: // 1 монета Инь, 2 монеты Ян (2+3+3)
        lineType = 'инь, неизменяющаяся (8)';
        break;
      case 9: // 3 монеты Ян (3+3+3)
        lineType = 'ян, изменяющаяся (9)';
        break;
      default:
        lineType = 'неизвестно';
    }
    developer.log(
      'Результат броска: $lineType для линии ${widget.currentLine} из ${widget.totalLines}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Material(
        type: MaterialType.transparency,
        child: _buildDialogContainer(context),
      ),
    );
  }

  Widget _buildDialogContainer(BuildContext context) {
    return Container(
      width: 330.w,
      height: 330.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade50, Colors.amber.shade100],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _canDismiss ? () => _finishAndGenerateLine() : null,
        child: Center(child: _buildAnimatedContent()),
      ),
    );
  }

  Widget _buildAnimatedContent() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CoinDisplayArea(
                  isInitial: isInitial,
                  coinsState: _coinsState,
                  onTap: _handleTap,
                ),
                SizedBox(height: 24.h),
                ShakeInstructions(
                  isInitial: isInitial,
                  currentLine: widget.currentLine,
                  totalLines: widget.totalLines,
                  currentShakeCount: widget.shakeService.currentShakeCount,
                  maxShakeCount: widget.shakeService.maxShakeCount,
                ),
                if (!isInitial) ...[
                  SizedBox(height: 24.h),
                  ShakeProgressIndicator(progress: _progress),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class CoinDisplayArea extends StatelessWidget {
  const CoinDisplayArea({
    required this.isInitial,
    required this.coinsState,
    required this.onTap,
    super.key,
  });

  final bool isInitial;
  final List<bool> coinsState;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: Container(
          key: ValueKey<bool>(isInitial),
          width: 251.w,
          height: 200.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: !isInitial ? Colors.white.withOpacity(0.1) : null,
          ),
          child: Stack(
            children: [
              if (isInitial)
                Center(child: Image.asset('assets/shake.png'))
              else
                CoinArrangement(coinsState: coinsState),
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: onTap,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CoinArrangement extends StatelessWidget {
  const CoinArrangement({required this.coinsState, super.key});

  final List<bool> coinsState;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CoinImage(isHeads: coinsState[0]),
              const SizedBox(width: 40),
              CoinImage(isHeads: coinsState[1]),
            ],
          ),
          CoinImage(isHeads: coinsState[2]),
        ],
      ),
    );
  }
}

class CoinImage extends StatelessWidget {
  const CoinImage({required this.isHeads, super.key});

  final bool isHeads;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (Widget child, Animation<double> animation) {
        final rotationAnimation = Tween<double>(
          begin: 0,
          end: 1,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut));

        return AnimatedBuilder(
          animation: rotationAnimation,
          child: child,
          builder: (context, widget) {
            final isHalfwayDone = rotationAnimation.value >= 0.5;
            final rotationValue =
                isHalfwayDone
                    ? (1 - rotationAnimation.value) * pi
                    : rotationAnimation.value * pi;

            return Transform(
              transform: Matrix4.rotationY(rotationValue),
              alignment: Alignment.center,
              child: widget,
            );
          },
        );
      },
      child: Image.asset(
        isHeads ? 'assets/heads.png' : 'assets/tails.png',
        key: ValueKey<bool>(isHeads),
        width: 100,
        height: 100,
      ),
    );
  }
}

class ShakeInstructions extends StatelessWidget {
  const ShakeInstructions({
    required this.isInitial,
    required this.currentLine,
    required this.totalLines,
    required this.currentShakeCount,
    required this.maxShakeCount,
    super.key,
  });

  final bool isInitial;
  final int currentLine;
  final int totalLines;
  final int currentShakeCount;
  final int maxShakeCount;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Text(
        key: ValueKey<bool>(isInitial),
        isInitial
            ? 'Встряхните телефон или нажмите для броска монет\nЛиния $currentLine из $totalLines'
            : 'Продолжайте встряхивать телефон или нажимайте на монеты\n$currentShakeCount/$maxShakeCount действий',
        style: context.styles.medium,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class ShakeProgressIndicator extends StatelessWidget {
  const ShakeProgressIndicator({required this.progress, super.key});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 175.w,
      child: LinearProgressIndicator(
        borderRadius: BorderRadius.circular(100),
        value: progress,
        color: Colors.amber.shade700,
        backgroundColor: Colors.amber.shade200,
      ),
    );
  }
}
