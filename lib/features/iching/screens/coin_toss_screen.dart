import 'dart:math';
import 'package:flutter/material.dart';
import 'package:zhi_ming/features/iching/models/hexagram.dart';
import 'package:zhi_ming/features/iching/services/iching_service.dart';
import 'package:zhi_ming/features/iching/screens/hexagram_result_screen.dart';
import 'package:zhi_ming/features/iching/widgets/iching_shake_popup.dart';
import 'package:zhi_ming/core/services/shake_service/shaker_service_repo.dart';
import 'package:zhi_ming/core/services/shake_service/shake_service_impl.dart';

class CoinTossScreen extends StatefulWidget {
  const CoinTossScreen({super.key});

  @override
  State<CoinTossScreen> createState() => _CoinTossScreenState();
}

class _CoinTossScreenState extends State<CoinTossScreen> {
  final IChingService _ichingService = IChingService();
  final List<int> _lineValues = [];

  // Количество линий в гексаграмме
  static const int _totalLines = 6;

  // Открывает попап для броска монет
  void _showCoinTossPopup() {
    final shakerService = ShakerServiceImpl();

    // Сбрасываем счетчик встряхиваний перед каждым новым броском
    shakerService.resetShakeCount();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => IChingShakePopup(
            shakeService: shakerService,
            onLineGenerated: _onLineGenerated,
            currentLine: _lineValues.length + 1,
            totalLines: _totalLines,
          ),
    );
  }

  // Обрабатывает результат броска
  void _onLineGenerated(int lineValue) {
    setState(() {
      _lineValues.add(lineValue);
    });

    // Если все 6 линий сформированы, переходим к результату
    if (_lineValues.length == _totalLines) {
      _navigateToResult();
    }
  }

  void _resetToss() {
    setState(() {
      _lineValues.clear();
    });
  }

  Future<void> _navigateToResult() async {
    final lines = _lineValues.map((value) => Line(value)).toList();

    // Создаем базовую гексаграмму из значений линий
    final hexagram = Hexagram(lines: lines);

    // Получаем гексаграммы с описаниями из базы
    final (currentHexagram, futureHexagram) = await _ichingService
        .fillHexagramInfo(hexagram);

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => HexagramResultScreen(
              currentHexagram: currentHexagram,
              futureHexagram: futureHexagram,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Гадание И Цзин')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Информация о прогрессе
            Text(
              'Линия ${_lineValues.length + 1} из 6',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),

            // Отображение уже сформированных линий
            if (_lineValues.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Text('Созданные линии:'),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children:
                          _lineValues.map((value) {
                            String lineSymbol;
                            switch (value) {
                              case 6:
                                lineSymbol = '╌●';
                                break;
                              case 7:
                                lineSymbol = '━';
                                break;
                              case 8:
                                lineSymbol = '╌';
                                break;
                              case 9:
                                lineSymbol = '━●';
                                break;
                              default:
                                lineSymbol = '?';
                            }
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Text(
                                lineSymbol,
                                style: const TextStyle(fontSize: 24),
                              ),
                            );
                          }).toList(),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 40),

            // Кнопки действий
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _lineValues.isNotEmpty ? _resetToss : null,
                  child: const Text('Сбросить'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed:
                      _lineValues.length < _totalLines
                          ? _showCoinTossPopup
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  child: const Text(
                    'Бросить монеты',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
