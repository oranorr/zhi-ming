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
}
