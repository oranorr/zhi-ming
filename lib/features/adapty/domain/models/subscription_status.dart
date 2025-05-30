import 'package:equatable/equatable.dart';

/// Модель статуса подписки пользователя
/// Содержит информацию о текущем состоянии подписки и доступных функциях
class SubscriptionStatus extends Equatable {
  const SubscriptionStatus({
    required this.isActive,
    required this.remainingFreeRequests,
    required this.maxFreeRequests,
    required this.hasPremiumAccess,
    this.expirationDate,
    this.subscriptionType,
  });

  /// Создает статус для пользователя без подписки
  factory SubscriptionStatus.free({
    required int remainingFreeRequests,
    required int maxFreeRequests,
  }) {
    return SubscriptionStatus(
      isActive: false,
      remainingFreeRequests: remainingFreeRequests,
      maxFreeRequests: maxFreeRequests,
      hasPremiumAccess: false,
    );
  }

  /// Создает статус для пользователя с активной подпиской
  factory SubscriptionStatus.premium({
    required DateTime expirationDate,
    required String subscriptionType,
  }) {
    return SubscriptionStatus(
      isActive: true,
      expirationDate: expirationDate,
      subscriptionType: subscriptionType,
      remainingFreeRequests: 0, // Неограниченно для премиум
      maxFreeRequests: 0,
      hasPremiumAccess: true,
    );
  }

  /// Активна ли подписка в данный момент
  final bool isActive;

  /// Дата окончания подписки (если есть)
  final DateTime? expirationDate;

  /// Тип подписки (monthly, yearly, lifetime)
  final String? subscriptionType;

  /// Количество оставшихся бесплатных запросов
  final int remainingFreeRequests;

  /// Максимальное количество бесплатных запросов
  final int maxFreeRequests;

  /// Есть ли доступ к премиум функциям
  final bool hasPremiumAccess;

  /// Может ли пользователь сделать запрос
  bool get canMakeRequest => hasPremiumAccess || remainingFreeRequests > 0;

  /// Копирует объект с новыми значениями
  SubscriptionStatus copyWith({
    bool? isActive,
    DateTime? expirationDate,
    String? subscriptionType,
    int? remainingFreeRequests,
    int? maxFreeRequests,
    bool? hasPremiumAccess,
  }) {
    return SubscriptionStatus(
      isActive: isActive ?? this.isActive,
      expirationDate: expirationDate ?? this.expirationDate,
      subscriptionType: subscriptionType ?? this.subscriptionType,
      remainingFreeRequests:
          remainingFreeRequests ?? this.remainingFreeRequests,
      maxFreeRequests: maxFreeRequests ?? this.maxFreeRequests,
      hasPremiumAccess: hasPremiumAccess ?? this.hasPremiumAccess,
    );
  }

  @override
  List<Object?> get props => [
    isActive,
    expirationDate,
    subscriptionType,
    remainingFreeRequests,
    maxFreeRequests,
    hasPremiumAccess,
  ];

  @override
  String toString() {
    return 'SubscriptionStatus(isActive: $isActive, expirationDate: $expirationDate, '
        'subscriptionType: $subscriptionType, remainingFreeRequests: $remainingFreeRequests, '
        'maxFreeRequests: $maxFreeRequests, hasPremiumAccess: $hasPremiumAccess)';
  }
}
