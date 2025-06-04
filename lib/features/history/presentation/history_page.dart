import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:zhi_ming/core/extensions/build_context_extension.dart';
import 'package:zhi_ming/core/theme/theme_colors.dart';
import 'package:zhi_ming/core/theme/z_text_styles.dart';
import 'package:zhi_ming/core/widgets/z_button.dart';
import 'package:zhi_ming/features/history/domain/chat_history_entity.dart';
import 'package:zhi_ming/features/history/presentation/history_cubit.dart';
import 'package:zhi_ming/features/chat/presentation/chat_screen.dart';
import 'package:zhi_ming/features/chat/presentation/chat_cubit.dart';
import 'package:zhi_ming/features/chat/domain/chat_entrypoint_entity.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HistoryCubit()..loadHistory(),
      child: const _HistoryContent(),
    );
  }
}

class _HistoryContent extends StatelessWidget {
  const _HistoryContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 50.h),
        Text(
          '历史记录',
          style: context.styles.h3.copyWith(
            fontWeight: AppFontWeight.demiLight,
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: BlocBuilder<HistoryCubit, HistoryState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return const _LoadingHistory();
                }

                if (state.isEmpty) {
                  return const _EmptyHistory();
                }

                return _HistoryList(chats: state.chats);
              },
            ),
          ),
        ),
        SizedBox(height: 50.h),
      ],
    );
  }
}

/// Виджет состояния загрузки
class _LoadingHistory extends StatelessWidget {
  const _LoadingHistory();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

/// Виджет пустой истории
class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('聊天记录为空', style: context.styles.h2),
        SizedBox(height: 12.h),
        Text('但这很容易解决！开始一次新的占卜吧。', style: context.styles.mDemilight),
        SizedBox(height: 30.h),
        Zbutton(
          action: () {
            // Навигация к новому чату
            debugPrint('[_EmptyHistory] Переход к новому чату');

            Navigator.of(context).push(
              MaterialPageRoute(
                builder:
                    (context) => BlocProvider<ChatCubit>(
                      create: (context) => ChatCubit(),
                      child: ChatScreen(entrypoint: IzinEntrypointEntity()),
                    ),
              ),
            );
          },
          isLoading: false,
          isActive: true,
          text: '请说出你内心的问题',
          textColor: Colors.white,
        ),
      ],
    );
  }
}

/// Виджет списка истории чатов с группировкой по времени
class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.chats});

  final List<ChatHistoryEntity> chats;

  @override
  Widget build(BuildContext context) {
    // Группируем чаты по временным категориям
    final groupedChats = _groupChatsByTime(chats);

    return ListView.builder(
      itemCount: groupedChats.length,
      itemBuilder: (context, index) {
        final group = groupedChats[index];
        return Padding(
          padding: EdgeInsets.only(bottom: 15.h),
          child: _ChatGroup(title: group.title, chats: group.chats),
        );
      },
    );
  }

  /// Группирует чаты по временным категориям
  List<ChatTimeGroup> _groupChatsByTime(List<ChatHistoryEntity> chats) {
    final now = DateTime.now();
    final groups = <ChatTimeGroup>[];

    // Группы для сортировки
    final todayChats = <ChatHistoryEntity>[];
    final yesterdayChats = <ChatHistoryEntity>[];
    final monthGroups = <String, List<ChatHistoryEntity>>{};

    for (final chat in chats) {
      final difference = now.difference(chat.createdAt);

      if (difference.inDays == 0) {
        // Сегодня
        todayChats.add(chat);
      } else if (difference.inDays == 1) {
        // Вчера
        yesterdayChats.add(chat);
      } else {
        // Группируем по месяцам
        final monthKey = DateFormat('yyyy年M月').format(chat.createdAt);
        monthGroups.putIfAbsent(monthKey, () => []).add(chat);
      }
    }

    // Добавляем группы в правильном порядке
    if (todayChats.isNotEmpty) {
      groups.add(ChatTimeGroup(title: '今天', chats: todayChats));
    }

    if (yesterdayChats.isNotEmpty) {
      groups.add(ChatTimeGroup(title: '昨天', chats: yesterdayChats));
    }

    // Добавляем месячные группы (отсортированные по убыванию даты)
    final sortedMonthKeys =
        monthGroups.keys.toList()..sort((a, b) => b.compareTo(a));

    for (final monthKey in sortedMonthKeys) {
      final monthChats = monthGroups[monthKey]!;
      // Сортируем чаты внутри месяца по убыванию времени
      monthChats.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      groups.add(ChatTimeGroup(title: monthKey, chats: monthChats));
    }

    debugPrint('[_HistoryList] Создано ${groups.length} временных групп');
    return groups;
  }
}

/// Модель для группы чатов по времени
class ChatTimeGroup {
  const ChatTimeGroup({required this.title, required this.chats});

  final String title;
  final List<ChatHistoryEntity> chats;
}

/// Виджет группы чатов с заголовком
class _ChatGroup extends StatelessWidget {
  const _ChatGroup({required this.title, required this.chats});

  final String title;
  final List<ChatHistoryEntity> chats;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        // color: Colors.white.withOpacity(0.05),ы
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Padding(
        padding: EdgeInsets.all(12.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: context.styles.sDemilight.copyWith(
                color: ZColors.grayDark,
              ),
            ),
            SizedBox(height: 5.h),
            // Передаем информацию о том, является ли элемент последним
            ...chats.asMap().entries.map((entry) {
              final index = entry.key;
              final chat = entry.value;
              final isLast = index == chats.length - 1;

              return _ChatHistoryTile(chat: chat, isLast: isLast);
            }),
          ],
        ),
      ),
    );
  }
}

/// Виджет элемента истории чата
class _ChatHistoryTile extends StatefulWidget {
  const _ChatHistoryTile({required this.chat, required this.isLast});

  final ChatHistoryEntity chat;
  final bool isLast;

  @override
  State<_ChatHistoryTile> createState() => _ChatHistoryTileState();
}

class _ChatHistoryTileState extends State<_ChatHistoryTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _isPressed = true;
        });
      },
      onTapUp: (_) {
        setState(() {
          _isPressed = false;
        });

        // Навигация к чату в режиме только чтения
        debugPrint('[_ChatHistoryTile] Открытие чата: ${widget.chat.id}');

        // Создаем HistoryEntrypointEntity с данными чата
        final entrypoint = HistoryEntrypointEntity(chatHistory: widget.chat);

        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (context) => BlocProvider<ChatCubit>(
                  create: (context) => ChatCubit(),
                  child: ChatScreen(entrypoint: entrypoint),
                ),
          ),
        );
      },
      onTapCancel: () {
        setState(() {
          _isPressed = false;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 44.h,
        decoration: BoxDecoration(
          color: _isPressed ? const Color(0xffF5F3EF) : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
        ),
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  // Основное содержимое чата
                  Expanded(
                    flex: 20,
                    child: Text(
                      widget.chat.mainQuestion,
                      // 'sljkefhlskjdfkljashdfkljhasdkljfhalskjdhfalksjdhflkasjdhfasd',
                      style: context.styles.sDemilight,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  Icon(
                    Icons.chevron_right,
                    color: Colors.black.withOpacity(0.4),
                    size: 20.w,
                  ),
                ],
              ),
            ),
            // Показываем Divider только если элемент не последний в группе
            if (!widget.isLast)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: const Divider(color: ZColors.gray, height: 1),
              ),
          ],
        ),
      ),
    );
  }

  /// Создает превью сообщения
  Widget _buildMessagePreview(BuildContext context, message) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        message.text,
        style: context.styles.sDemilight.copyWith(
          color: Colors.white.withOpacity(0.7),
          height: 1.3,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// Форматирует только время (без даты)
  String _formatTimeOnly(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  /// Форматирует дату в человекочитаемый вид (оставляем для совместимости)
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      // Сегодня
      return '今天 ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays == 1) {
      // Вчера
      return '昨天 ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays < 7) {
      // На этой неделе
      final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      final weekday = weekdays[date.weekday - 1];
      return '$weekday ${DateFormat('HH:mm').format(date)}';
    } else {
      // Старше недели
      return DateFormat('MM月dd日 HH:mm').format(date);
    }
  }
}


// class _ChatGroups extends StatelessWidget {
//   const _ChatGroups({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const Placeholder();
//   }
// }