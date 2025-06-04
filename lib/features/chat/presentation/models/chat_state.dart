import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:zhi_ming/features/chat/domain/message_entity.dart';
import 'package:zhi_ming/features/iching/models/hexagram.dart';

part 'chat_state.g.dart';

/// Состояние чата с полной информацией о текущем диалоге
@JsonSerializable()
class ChatState extends Equatable {
  const ChatState({
    this.isButtonAvailable = false,
    this.isSendAvailable = false,
    this.isLoading = false,
    this.messages = const [],
    this.currentInput = '',
    this.loadingMessageIndex = -1,
    this.lastHexagramContext, // Контекст последнего гадания
    this.currentQuestionContext =
        const [], // Контекст текущего формирующегося вопроса
    this.hasActiveSubscription = false, // Статус подписки
    this.remainingFreeRequests = 0, // Количество оставшихся бесплатных запросов
    this.shouldNavigateToPaywall = false, // Флаг для навигации на paywall
    this.currentChatId, // ID текущего чата для истории
  });

  factory ChatState.fromJson(Map<String, dynamic> json) =>
      _$ChatStateFromJson(json);

  /// Доступность кнопки встряхивания для генерации гексаграмм
  final bool isButtonAvailable;

  /// Доступность кнопки отправки сообщения
  final bool isSendAvailable;

  /// Флаг состояния загрузки
  final bool isLoading;

  /// Список всех сообщений в чате
  final List<MessageEntity> messages;

  /// Текущий ввод пользователя
  final String currentInput;

  /// Индекс сообщения с индикатором загрузки
  final int loadingMessageIndex;

  /// Контекст последнего гадания для обработки последующих вопросов
  final HexagramContext? lastHexagramContext;

  /// Накопленный контекст текущего вопроса (до валидации)
  final List<String> currentQuestionContext;

  /// Статус активной подписки пользователя
  final bool hasActiveSubscription;

  /// Количество оставшихся бесплатных запросов
  final int remainingFreeRequests;

  /// Флаг для навигации на экран оплаты
  final bool shouldNavigateToPaywall;

  /// ID текущего чата для сохранения в истории
  final String? currentChatId;

  /// Создание копии состояния с измененными параметрами
  ChatState copyWith({
    bool? isButtonAvailable,
    bool? isSendAvailable,
    bool? isLoading,
    List<MessageEntity>? messages,
    String? currentInput,
    int? loadingMessageIndex,
    HexagramContext? lastHexagramContext,
    bool clearLastHexagramContext = false,
    List<String>? currentQuestionContext,
    bool? hasActiveSubscription,
    int? remainingFreeRequests,
    bool? shouldNavigateToPaywall,
    String? currentChatId,
    bool clearCurrentChatId = false,
  }) {
    return ChatState(
      isButtonAvailable: isButtonAvailable ?? this.isButtonAvailable,
      isSendAvailable: isSendAvailable ?? this.isSendAvailable,
      isLoading: isLoading ?? this.isLoading,
      messages: messages ?? this.messages,
      currentInput: currentInput ?? this.currentInput,
      loadingMessageIndex: loadingMessageIndex ?? this.loadingMessageIndex,
      lastHexagramContext:
          clearLastHexagramContext
              ? null
              : (lastHexagramContext ?? this.lastHexagramContext),
      currentQuestionContext:
          currentQuestionContext ?? this.currentQuestionContext,
      hasActiveSubscription:
          hasActiveSubscription ?? this.hasActiveSubscription,
      remainingFreeRequests:
          remainingFreeRequests ?? this.remainingFreeRequests,
      shouldNavigateToPaywall:
          shouldNavigateToPaywall ?? this.shouldNavigateToPaywall,
      currentChatId:
          clearCurrentChatId ? null : (currentChatId ?? this.currentChatId),
    );
  }

  /// Сериализация в JSON
  Map<String, dynamic> toJson() => _$ChatStateToJson(this);

  /// Проверка доступности запроса (есть подписка или остались бесплатные запросы)
  bool get canMakeRequest => hasActiveSubscription || remainingFreeRequests > 0;

  /// Проверка наличия контекста последнего гадания
  bool get hasHexagramContext => lastHexagramContext != null;

  /// Проверка наличия накопленного контекста вопроса
  bool get hasQuestionContext => currentQuestionContext.isNotEmpty;

  /// Проверка состояния загрузки с активным индексом
  bool get isLoadingMessage => isLoading && loadingMessageIndex >= 0;

  @override
  List<Object?> get props => [
    isButtonAvailable,
    isSendAvailable,
    isLoading,
    messages,
    currentInput,
    loadingMessageIndex,
    lastHexagramContext,
    currentQuestionContext,
    hasActiveSubscription,
    remainingFreeRequests,
    shouldNavigateToPaywall,
    currentChatId,
  ];
}

/// Класс для хранения контекста последнего гадания
/// Используется для обработки последующих вопросов пользователя
@JsonSerializable()
class HexagramContext {
  const HexagramContext({
    required this.originalQuestion,
    required this.primaryHexagram,
    required this.interpretation,
    this.secondaryHexagram,
  });

  factory HexagramContext.fromJson(Map<String, dynamic> json) =>
      _$HexagramContextFromJson(json);

  /// Исходный вопрос пользователя
  final String originalQuestion;

  /// Основная гексаграмма
  final Hexagram primaryHexagram;

  /// Изменяющаяся гексаграмма (если есть)
  final Hexagram? secondaryHexagram;

  /// Интерпретация гексаграмм
  final String interpretation;

  /// Сериализация в JSON
  Map<String, dynamic> toJson() => _$HexagramContextToJson(this);

  /// Проверка наличия изменяющихся линий
  bool get hasChangingLines => secondaryHexagram != null;

  /// Полное описание контекста для логирования
  String get debugDescription =>
      'Вопрос: "$originalQuestion", '
      'Основная: ${primaryHexagram.number} (${primaryHexagram.name})'
      '${hasChangingLines ? ', Изменяющаяся: ${secondaryHexagram!.number} (${secondaryHexagram!.name})' : ''}';
}
