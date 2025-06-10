import 'package:flutter/foundation.dart'; // Для kDebugMode
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zhi_ming/core/extensions/build_context_extension.dart';
import 'package:zhi_ming/core/theme/theme_colors.dart';
import 'package:zhi_ming/core/widgets/z_button.dart';
import 'package:zhi_ming/features/adapty/data/repositories/adapty_repository_impl.dart';
import 'package:zhi_ming/features/chat/domain/chat_entrypoint_entity.dart';
import 'package:zhi_ming/features/chat/presentation/chat_cubit.dart';
import 'package:zhi_ming/features/chat/presentation/chat_screen.dart';
import 'package:zhi_ming/features/home/data/local_repo.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final questions = HomeLocalRepo().questions;
    return CustomScrollView(
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _SliverHeaderDelegate(
            minHeight: 250.h,
            maxHeight: 270.h,
            child: const _Header(),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 10.h)),
        const SliverToBoxAdapter(child: _ScrollButton()),
        SliverToBoxAdapter(child: SizedBox(height: 10.h)),
        // const SliverToBoxAdapter(child: _IChingButton()),
        // SliverToBoxAdapter(child: SizedBox(height: 10.h)),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => questions[index].buildTile(context),
            childCount: questions.length,
          ),
        ),
        // Дебажная кнопка в самом низу страницы
        if (kDebugMode)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Center(
                child: GestureDetector(
                  onTap: () async {
                    final repository = AdaptyRepositoryImpl.instance;

                    // Деактивируем подписку
                    await repository.logout();

                    // Сбрасываем счетчик бесплатных запросов
                    await repository.initialize();

                    // Обновляем состояние ChatCubit если он доступен
                    try {
                      final chatCubit = context.read<ChatCubit>();
                      await chatCubit.clear(); // Полностью очищаем состояние
                    } catch (e) {
                      // ChatCubit может быть недоступен, это нормально
                      debugPrint('ChatCubit недоступен: $e');
                    }

                    // Показываем уведомление
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🔄 Подписка и счетчик сброшены'),
                          duration: Duration(seconds: 2),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh, color: Colors.white, size: 24.w),
                        SizedBox(width: 8.w),
                        Text(
                          'Debug Reset',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showTestActions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Тестовые действия',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Сбросить подписку'),
                onTap: () async {
                  Navigator.pop(context);
                  final repository = AdaptyRepositoryImpl.instance;

                  // Деактивируем подписку
                  await repository.logout();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Подписка сброшена')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Сбросить бесплатные запросы'),
                onTap: () async {
                  Navigator.pop(context);
                  final repository = AdaptyRepositoryImpl.instance;

                  // Сбрасываем счетчик через повторную инициализацию
                  await repository.logout();
                  await repository.initialize();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Бесплатные запросы сброшены'),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  _SliverHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });
  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final shrinkPercentage = shrinkOffset / maxHeight;
    final scale = 1.0 - (shrinkPercentage * 0.1);
    final isExpanded = shrinkOffset < 1;

    // Быстрый переход от прозрачности к непрозрачности
    final bgOpacity = shrinkPercentage < 0.05 ? 0.0 : 1.0;

    // Рассчитаем elevation на основе процента скролла
    final elevation = shrinkPercentage * 10; // Максимальная тень - 10

    // Добавляем отступ сверху для безопасной зоны, когда хедер не развернут
    final safeAreaPadding = MediaQuery.of(context).padding.top;
    final topPadding = !isExpanded ? safeAreaPadding : 0.0;

    return DecoratedBox(
      // Белый фон с динамической прозрачностью и тенью
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(bgOpacity),
        boxShadow: [
          if (shrinkPercentage > 0.05)
            BoxShadow(
              color: Colors.black.withOpacity(0.5 * shrinkPercentage),
              blurRadius: elevation,
              spreadRadius: elevation / 3,
            ),
        ],
      ),
      // Содержимое хедера с усиленным градиентом
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isExpanded ? Colors.transparent : null,
          gradient: isExpanded ? null : ZColors.homeGradient,
          //     ZColors.homeGradient, // Используем созданный усиленный градиент
        ),
        child: Padding(
          padding: EdgeInsets.only(top: topPadding),
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.topCenter,
            child: _Header(isExpanded: isExpanded),
          ),
        ),
      ),
    );
  }

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => minHeight;

  @override
  bool shouldRebuild(covariant _SliverHeaderDelegate oldDelegate) {
    return oldDelegate.minHeight != minHeight ||
        oldDelegate.maxHeight != maxHeight ||
        oldDelegate.child != child;
  }
}

class _Header extends StatelessWidget {
  const _Header({this.isExpanded = false});
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        // Удаляем все комментарии, так как градиент теперь в SliverHeaderDelegate
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 27.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _buildTextAndGrandDad(context),
            SizedBox(height: 8.h),
            Zbutton(
              action: () {
                final cubit = context.read<ChatCubit>();
                cubit.toggleButton(false);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder:
                        (context) => BlocProvider.value(
                          value: cubit,
                          child: ChatScreen(entrypoint: IzinEntrypointEntity()),
                        ),
                  ),
                );
              },
              isLoading: false,
              isActive: true,
              text: '请说出你内心的问题',
              textColor: ZColors.white,
            ),
            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }

  Widget _buildTextAndGrandDad(BuildContext context) {
    return Row(
      children: [
        Column(
          children: [
            Text('你好，梅', style: context.styles.h1),
            SizedBox(height: 15.h),
            Text('今天你想问什么?', style: context.styles.h3),
          ],
        ),
        const Spacer(),
        Column(
          children: [
            SizedBox(
              width: 100.w,
              height: 100.h,
              child: Image.asset('assets/ded.png', fit: BoxFit.cover),
            ),
          ],
        ),
      ],
    );
  }
}

class _ScrollButton extends StatelessWidget {
  const _ScrollButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: GestureDetector(
        onTap: () {
          // [_ScrollButton] Открываем чат с Ба-Дзы entrypoint
          debugPrint('[_ScrollButton] Переход к Ба-Дзы гаданию');

          final cubit = context.read<ChatCubit>();
          cubit.toggleButton(false);

          Navigator.of(context).push(
            MaterialPageRoute(
              builder:
                  (context) => BlocProvider.value(
                    value: cubit,
                    child: ChatScreen(entrypoint: BaDzyEntrypointEntity()),
                  ),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            height: 110.h,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/back.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(18.w, 14.h, 0, 14.h),
              child: Row(
                // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Image.asset('assets/scroll.png', width: 73.w, height: 82.h),
                  SizedBox(width: 21.w),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('开启你的命运之旅', style: context.styles.lRegular),
                      Text('探索八字的奥秘', style: context.styles.mRegular),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
