import 'package:equatable/equatable.dart';

/// Модель продукта подписки
/// Содержит информацию о доступных планах подписки
class SubscriptionProduct extends Equatable {
  const SubscriptionProduct({
    required this.productId,
    required this.title,
    required this.description,
    required this.price,
    required this.priceAmountMicros,
    required this.currencyCode,
    required this.subscriptionPeriod,
    required this.hasFreeTrial,
    required this.pricePerPeriod,
    this.freeTrialDays,
    this.isRecommended = false,
    this.discountPercentage,
    this.originalPrice,
  });

  /// Создает продукт для месячной подписки
  factory SubscriptionProduct.monthly({
    required String productId,
    required String price,
    required int priceAmountMicros,
    required String currencyCode,
    bool hasFreeTrial = false,
    int? freeTrialDays,
  }) {
    return SubscriptionProduct(
      productId: productId,
      isRecommended: true,
      title: '1个月',
      description: '在1个月 ¥18.9 然后 ¥28',
      price: price,
      priceAmountMicros: priceAmountMicros,
      currencyCode: currencyCode,
      subscriptionPeriod: 'monthly',
      hasFreeTrial: hasFreeTrial,
      freeTrialDays: freeTrialDays,
      pricePerPeriod: '$price/月',
    );
  }

  /// Создает продукт для годовой подписки
  factory SubscriptionProduct.yearly({
    required String productId,
    required String price,
    required int priceAmountMicros,
    required String currencyCode,
    bool hasFreeTrial = false,
    int? freeTrialDays,
    int? discountPercentage,
  }) {
    return SubscriptionProduct(
      productId: productId,
      title: '1年',
      description: '¥11.5每月',
      price: price,
      priceAmountMicros: priceAmountMicros,
      currencyCode: currencyCode,
      subscriptionPeriod: 'annual',
      hasFreeTrial: hasFreeTrial,
      freeTrialDays: freeTrialDays,
      pricePerPeriod: '$price/年',
      // isRecommended: true, // Годовая подписка обычно рекомендуемая
      discountPercentage: discountPercentage,
    );
  }

  /// Уникальный идентификатор продукта
  final String productId;

  /// Название продукта для отображения
  final String title;

  /// Описание продукта
  final String description;

  /// Цена в локальной валюте (отформатированная строка)
  final String price;

  /// Цена в микроединицах (для вычислений)
  final int priceAmountMicros;

  /// Код валюты (USD, RUB, etc.)
  final String currencyCode;

  /// Период подписки (monthly, yearly, lifetime)
  final String subscriptionPeriod;

  /// Есть ли бесплатный пробный период
  final bool hasFreeTrial;

  /// Длительность пробного периода в днях
  final int? freeTrialDays;

  /// Цена за период (например, "¥68/месяц")
  final String pricePerPeriod;

  /// Является ли этот продукт рекомендуемым
  final bool isRecommended;

  /// Процент скидки (если есть)
  final int? discountPercentage;

  /// Оригинальная цена (для отображения зачеркнутой цены при скидке)
  final String? originalPrice;

  /// Копирует объект с новыми значениями
  SubscriptionProduct copyWith({
    String? productId,
    String? title,
    String? description,
    String? price,
    int? priceAmountMicros,
    String? currencyCode,
    String? subscriptionPeriod,
    bool? hasFreeTrial,
    int? freeTrialDays,
    String? pricePerPeriod,
    bool? isRecommended,
    int? discountPercentage,
    String? originalPrice,
  }) {
    return SubscriptionProduct(
      productId: productId ?? this.productId,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      priceAmountMicros: priceAmountMicros ?? this.priceAmountMicros,
      currencyCode: currencyCode ?? this.currencyCode,
      subscriptionPeriod: subscriptionPeriod ?? this.subscriptionPeriod,
      hasFreeTrial: hasFreeTrial ?? this.hasFreeTrial,
      freeTrialDays: freeTrialDays ?? this.freeTrialDays,
      pricePerPeriod: pricePerPeriod ?? this.pricePerPeriod,
      isRecommended: isRecommended ?? this.isRecommended,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      originalPrice: originalPrice ?? this.originalPrice,
    );
  }

  @override
  List<Object?> get props => [
    productId,
    title,
    description,
    price,
    priceAmountMicros,
    currencyCode,
    subscriptionPeriod,
    hasFreeTrial,
    freeTrialDays,
    pricePerPeriod,
    isRecommended,
    discountPercentage,
    originalPrice,
  ];

  @override
  String toString() {
    return 'SubscriptionProduct(productId: $productId, title: $title, '
        'price: $price, subscriptionPeriod: $subscriptionPeriod, '
        'isRecommended: $isRecommended)';
  }
}
