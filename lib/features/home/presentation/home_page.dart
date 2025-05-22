import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui'; // Добавляем импорт для ImageFilter
import 'package:zhi_ming/core/extensions/build_context_extension.dart';
import 'package:zhi_ming/core/theme/theme_colors.dart';
import 'package:zhi_ming/core/widgets/z_button.dart';
import 'package:zhi_ming/core/widgets/z_scaffold.dart';
import 'package:zhi_ming/features/chat/domain/chat_entrypoint_entity.dart';
import 'package:zhi_ming/features/chat/presentation/chat_cubit.dart';
import 'package:zhi_ming/features/chat/presentation/chat_screen.dart';
import 'package:zhi_ming/features/home/data/local_repo.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final questions = HomeLocalRepo().questions;
    return ZScaffold(
      isHome: false,
      child: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverHeaderDelegate(
              minHeight: 225.h,
              maxHeight: 260.h,
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
        ],
      ),
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

    return DecoratedBox(
      // Белый фон с динамической прозрачностью и тенью
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(bgOpacity),
        boxShadow: [
          if (shrinkPercentage > 0.05)
            BoxShadow(
              color: Colors.black.withOpacity(0.1 * shrinkPercentage),
              blurRadius: elevation,
              spreadRadius: elevation / 3,
            ),
        ],
      ),
      // Содержимое хедера с усиленным градиентом
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient:
              ZColors.homeGradient, // Используем созданный усиленный градиент
        ),
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.topCenter,
          child: _Header(isExpanded: isExpanded),
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
  const _Header({super.key, this.isExpanded = false});
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
            SizedBox(height: 16.h),
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
        Image.asset('assets/ded.png'),
      ],
    );
  }
}

class _ScrollButton extends StatelessWidget {
  const _ScrollButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
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
                    Text('开启你的命运之旅', style: context.styles.regular),
                    Text('探索八字的奥秘', style: context.styles.medium),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
