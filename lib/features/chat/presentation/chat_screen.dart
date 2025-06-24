import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zhi_ming/core/theme/theme_colors.dart';
import 'package:zhi_ming/core/widgets/z_button.dart';
import 'package:zhi_ming/core/widgets/z_scaffold.dart';
import 'package:zhi_ming/features/chat/domain/chat_entrypoint_entity.dart';
import 'package:zhi_ming/features/chat/presentation/chat_cubit.dart';
import 'package:zhi_ming/features/chat/presentation/input_send.dart';
import 'package:zhi_ming/features/chat/presentation/mixins/chat_screen_mixin.dart';
import 'package:zhi_ming/features/chat/presentation/models/chat_state.dart';
import 'package:zhi_ming/features/chat/presentation/widgets/chat_app_bar.dart';
import 'package:zhi_ming/features/chat/presentation/widgets/message_widget.dart';

/// [ChatScreen] Основной экран чата с И-Цзин
class ChatScreen extends StatefulWidget {
  const ChatScreen({required this.entrypoint, super.key});
  final ChatEntrypointEntity entrypoint;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with ChatScreenMixin {
  @override
  ChatEntrypointEntity get entrypoint => widget.entrypoint;

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChatCubit, ChatState>(
      listener: handleBlocListener,
      child: BlocBuilder<ChatCubit, ChatState>(
        builder: (context, state) {
          return WillPopScope(
            onWillPop: () async {
              await handleBackPressed();
              return mounted;
            },
            child: ZScaffold(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    SizedBox(height: 35.h),
                    // [ChatScreen] AppBar с кнопкой очистки для Ба-Дзы в режиме дебага
                    ChatAppBar(
                      entrypoint: entrypoint,
                      onBackPressed: handleBackPressed,
                      onClearChatPressed:
                          entrypoint is BaDzyEntrypointEntity
                              ? handleClearBaDzyChat
                              : null,
                    ),
                    // Основной список сообщений
                    Expanded(
                      child: GestureDetector(
                        // Закрываем клавиатуру при тапе на список
                        onTap: hideKeyboard,
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: state.messages.length,
                          itemBuilder: (context, index) {
                            final message =
                                state.messages[state.messages.length -
                                    1 -
                                    index];
                            final isLoading =
                                state.isLoading &&
                                index == state.messages.length - 1 &&
                                !message.isMe;

                            return Padding(
                              padding: EdgeInsets.only(
                                bottom:
                                    index != state.messages.length - 1
                                        ? 24.h
                                        : 0,
                              ),
                              child: MessageWidget(
                                isMe: message.isMe,
                                isLoading: isLoading,
                                text: message.text,
                                hexagrams: message.hexagrams,
                                message: message,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    // Скрываем кнопку встряхивания в режиме только чтения
                    if (state.isButtonAvailable && !entrypoint.isReadOnlyMode)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Zbutton(
                          action: handleShakeButtonPressed,
                          isLoading: false,
                          isActive: true,
                          text: '抛硬币',
                          textColor: ZColors.white,
                        ),
                      ),
                    // Скрываем виджет ввода в режиме только чтения
                    if (!entrypoint.isReadOnlyMode)
                      InputSendWidget(
                        onSend: handleSendMessage,
                        onTextChanged: (text) => cubit.updateInput(text),
                        isSendAvailable: state.isSendAvailable,
                        currentInput: state.currentInput,
                        focusNode: focusNode,
                        isGenerating: state.isLoading,
                        onStopGeneration: handleStopGeneration,
                      ),
                    SizedBox(height: 35.h),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
