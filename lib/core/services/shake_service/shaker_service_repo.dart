abstract class ShakerServiceRepo {
  Future<void> shake();

  /// Подписка на события встряхивания
  Stream<int> get shakeCountStream;

  /// Текущее количество встряхиваний
  int get currentShakeCount;

  /// Сброс счетчика встряхиваний
  void resetShakeCount();

  /// Максимальное количество встряхиваний
  int get maxShakeCount;

  /// Сохранение состояния трех монет (одного броска)
  void saveCoinThrow(List<int> coinValues);

  /// Получение результатов всех бросков монет (каждый бросок - список из трех значений монет)
  List<List<int>> getCoinThrows();

  /// Получение сумм всех бросков (каждый элемент - сумма трех монет одного броска)
  List<int> getLineValues();

  /// Сброс всех результатов бросков
  void resetCoinThrows();
}
