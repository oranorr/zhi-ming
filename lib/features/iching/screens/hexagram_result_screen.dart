import 'package:flutter/material.dart';
import 'package:zhi_ming/features/iching/models/hexagram.dart';
import 'package:zhi_ming/features/iching/widgets/hexagram_widget.dart';

class HexagramResultScreen extends StatelessWidget {
  const HexagramResultScreen({
    required this.currentHexagram,
    super.key,
    this.futureHexagram,
  });
  final Hexagram currentHexagram;
  final Hexagram? futureHexagram;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Результат гадания')),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Text(
                  'Ваша гексаграмма И Цзин',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),

                // Первая гексаграмма (текущая ситуация)
                HexagramWidget(
                  hexagram: currentHexagram,
                  title: 'Текущая ситуация',
                  width: 120,
                  lineHeight: 16,
                ),

                // Вторая гексаграмма (возможное будущее), если есть
                if (futureHexagram != null) ...[
                  const SizedBox(height: 40),

                  // Стрелка между гексаграммами
                  Icon(
                    Icons.arrow_downward,
                    size: 40,
                    color: Colors.grey.shade700,
                  ),

                  const SizedBox(height: 24),

                  HexagramWidget(
                    hexagram: futureHexagram!,
                    title: 'Тенденция развития',
                    width: 120,
                    lineHeight: 16,
                  ),

                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Линии с кружками - изменяющиеся. Они показывают трансформацию ситуации с течением времени.',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 24),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Ваша гексаграмма не содержит изменяющихся линий, что указывает на стабильную ситуацию.',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Новое гадание'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
