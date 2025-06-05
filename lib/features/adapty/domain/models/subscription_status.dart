import 'package:equatable/equatable.dart';

/// Модель статуса подписки пользователя
/// Содержит информацию о текущем состоянии подписки и доступных функциях
class SubscriptionStatus extends Equatable {
  const SubscriptionStatus({
    required this.isActive,
    required this.remainingFreeRequests,
    required this.maxFreeRequests,
    required this.hasPremiumAccess,
    required this.hasUsedFreeReading,
    required this.remainingFollowUpQuestions,
    required this.maxFollowUpQuestions,
    this.expirationDate,
    this.subscriptionType,
  });

  /// Создает статус для пользователя без подписки
  factory SubscriptionStatus.free({
    required int remainingFreeRequests,
    required int maxFreeRequests,
    required bool hasUsedFreeReading,
    required int remainingFollowUpQuestions,
    required int maxFollowUpQuestions,
  }) {
    return SubscriptionStatus(
      isActive: false,
      remainingFreeRequests: remainingFreeRequests,
      maxFreeRequests: maxFreeRequests,
      hasPremiumAccess: false,
      hasUsedFreeReading: hasUsedFreeReading,
      remainingFollowUpQuestions: remainingFollowUpQuestions,
      maxFollowUpQuestions: maxFollowUpQuestions,
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
      remainingFreeRequests: 0,
      maxFreeRequests: 0,
      hasPremiumAccess: true,
      hasUsedFreeReading: false,
      remainingFollowUpQuestions: 0,
      maxFollowUpQuestions: 0,
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

  /// Использовал ли пользователь бесплатное гадание
  final bool hasUsedFreeReading;

  /// Количество оставшихся фоллоу-ап вопросов
  final int remainingFollowUpQuestions;

  /// Максимальное количество фоллоу-ап вопросов
  final int maxFollowUpQuestions;

  /// Может ли пользователь начать новое гадание
  bool get canStartNewReading => hasPremiumAccess || !hasUsedFreeReading;

  /// Может ли пользователь задать фоллоу-ап вопрос
  bool get canAskFollowUpQuestion =>
      hasPremiumAccess || remainingFollowUpQuestions > 0;

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
    bool? hasUsedFreeReading,
    int? remainingFollowUpQuestions,
    int? maxFollowUpQuestions,
  }) {
    return SubscriptionStatus(
      isActive: isActive ?? this.isActive,
      expirationDate: expirationDate ?? this.expirationDate,
      subscriptionType: subscriptionType ?? this.subscriptionType,
      remainingFreeRequests:
          remainingFreeRequests ?? this.remainingFreeRequests,
      maxFreeRequests: maxFreeRequests ?? this.maxFreeRequests,
      hasPremiumAccess: hasPremiumAccess ?? this.hasPremiumAccess,
      hasUsedFreeReading: hasUsedFreeReading ?? this.hasUsedFreeReading,
      remainingFollowUpQuestions:
          remainingFollowUpQuestions ?? this.remainingFollowUpQuestions,
      maxFollowUpQuestions: maxFollowUpQuestions ?? this.maxFollowUpQuestions,
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
    hasUsedFreeReading,
    remainingFollowUpQuestions,
    maxFollowUpQuestions,
  ];

  @override
  String toString() {
    return 'SubscriptionStatus(isActive: $isActive, expirationDate: $expirationDate, '
        'subscriptionType: $subscriptionType, remainingFreeRequests: $remainingFreeRequests, '
        'maxFreeRequests: $maxFreeRequests, hasPremiumAccess: $hasPremiumAccess, '
        'hasUsedFreeReading: $hasUsedFreeReading, remainingFollowUpQuestions: $remainingFollowUpQuestions, '
        'maxFollowUpQuestions: $maxFollowUpQuestions)';
  }
}
