import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zhi_ming/core/extensions/build_context_extension.dart';
import 'package:zhi_ming/core/theme/theme_colors.dart';
import 'package:zhi_ming/core/services/shake_service/shaker_service_repo.dart';
import 'package:zhi_ming/features/iching/models/hexagram.dart';
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
    if (!isInitial &&
        widget.shakeService.currentShakeCount <
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
    // Используем текущее состояние монет (которое обновляется при каждом встряхивании)
    // Вычисляем сумму значений (Ян=3, Инь=2)
    final List<int> coinValues =
        _coinsState.map((isHeads) => isHeads ? 3 : 2).toList();

    final sum = coinValues.reduce((a, b) => a + b);

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
            gradient: LinearGradient(
              colors: [Colors.amber.shade50, Colors.amber.shade100],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _canDismiss ? () => _finishAndGenerateLine() : null,
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
                                    if (isInitial)
                                      Center(
                                        child: Image.asset('assets/shake.png'),
                                      )
                                    else
                                      Center(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: List.generate(3, (index) {
                                            return Padding(
                                              padding: const EdgeInsets.all(8),
                                              child: Image.asset(
                                                _coinsState[index]
                                                    ? 'assets/heads.png'
                                                    : 'assets/tails.png',
                                                width: 60,
                                                height: 60,
                                              ),
                                            );
                                          }),
                                        ),
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
                                  ? 'Встряхните телефон или нажмите для броска монет\nЛиния ${widget.currentLine} из ${widget.totalLines}'
                                  : 'Продолжайте встряхивать телефон или нажимайте на монеты\n${widget.shakeService.currentShakeCount}/${widget.shakeService.maxShakeCount} действий',
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
                                color: Colors.amber.shade700,
                                backgroundColor: Colors.amber.shade200,
                              ),
                            ),
                          ],
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
