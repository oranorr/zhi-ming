import 'package:flutter/material.dart';
import 'package:zhi_ming/features/iching/screens/coin_toss_screen.dart';

class IChingHomeScreen extends StatelessWidget {
  const IChingHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('И Цзин')),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.amber.shade50, Colors.amber.shade100],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Заголовок
                const Text(
                  'Книга Перемен',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'И Цзин',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w300,
                    color: Colors.amber.shade800,
                  ),
                ),

                const SizedBox(height: 40),

                // Изображение
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '易',
                      style: TextStyle(
                        fontSize: 100,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Описание
                Text(
                  'Древнекитайская система гадания, основанная на символах инь и ян',
                  style: TextStyle(fontSize: 16, color: Colors.amber.shade900),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                Text(
                  'Используйте виртуальный бросок монет для получения своей гексаграммы',
                  style: TextStyle(fontSize: 16, color: Colors.amber.shade900),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 50),

                // Кнопка перехода к гаданию
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CoinTossScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    textStyle: const TextStyle(fontSize: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                    shadowColor: Colors.amber.shade300,
                  ),
                  child: const Text('Начать гадание'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
