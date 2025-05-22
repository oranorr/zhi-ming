import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:zhi_ming/features/chat/domain/message_entity.dart';

part 'onboard_state.g.dart';

@JsonSerializable()
class OnboardState extends Equatable {
  const OnboardState({
    this.isDatePickerVisible = false,
    this.messages = const [],
    this.currentInput = '',
    this.currentQuestionIndex = 0,
    this.birthDate,
    this.isCompleted = false,
    this.isLoading = false,
  });

  factory OnboardState.fromJson(Map<String, dynamic> json) =>
      _$OnboardStateFromJson(json);

  final bool isDatePickerVisible;
  final List<MessageEntity> messages;
  final String currentInput;
  final int currentQuestionIndex;
  final DateTime? birthDate;
  final bool isCompleted;
  final bool isLoading;

  OnboardState copyWith({
    bool? isDatePickerVisible,
    List<MessageEntity>? messages,
    String? currentInput,
    int? currentQuestionIndex,
    DateTime? birthDate,
    bool? isCompleted,
    bool? isLoading,
  }) {
    return OnboardState(
      isDatePickerVisible: isDatePickerVisible ?? this.isDatePickerVisible,
      messages: messages ?? this.messages,
      currentInput: currentInput ?? this.currentInput,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      birthDate: birthDate ?? this.birthDate,
      isCompleted: isCompleted ?? this.isCompleted,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  Map<String, dynamic> toJson() => _$OnboardStateToJson(this);

  @override
  List<Object?> get props => [
    isDatePickerVisible,
    messages,
    currentInput,
    currentQuestionIndex,
    birthDate,
    isCompleted,
    isLoading,
  ];
}
