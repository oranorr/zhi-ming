// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:zhi_ming/core/extensions/build_context_extension.dart';
import 'package:zhi_ming/core/services/adapty/adapty_service.dart';
import 'package:zhi_ming/core/services/adapty/adapty_service_impl.dart';
import 'package:zhi_ming/core/widgets/z_button.dart';
import 'package:zhi_ming/features/home/presentation/home_page.dart';

class Paywall extends StatefulWidget {
  const Paywall({super.key});

  @override
  State<Paywall> createState() => _PaywallState();
}

class _PaywallState extends State<Paywall> {
  static final AdaptyService _adaptyService = AdaptyServiceImpl();

  @override
  void initState() {
    super.initState();
    // Инициализация уже не нужна, так как сервис статический
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Основной цветной градиент
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFEDFFCC), // светло-зеленый
                    Color(0xFFEEEFFF), // светло-фиолетовый
                    Color(0xFFD6A0EA), // розово-фиолетовый
                    Color(0xFFA6AAFE), // голубовато-фиолетовый
                  ],
                  stops: [0.0, 0.32, 0.57, 1.0],
                ),
              ),
              child: SizedBox(width: double.infinity, height: double.infinity),
            ),
            // Белый градиент поверх
            Opacity(
              opacity: 0.42,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xffF2F2F2), // светло-серый с прозрачностью
                      Color(0xffFFFFFF), // полностью прозрачный белый
                    ],
                    stops: [0.0, 0.42],
                  ),
                ),
                // child: Center(child: Text('Paywall')),
              ),
            ),
            _PaywallBody(),
          ],
        ),
      ),
    );
  }
}

class _PaywallBody extends StatefulWidget {
  const _PaywallBody({super.key});

  @override
  State<_PaywallBody> createState() => __PaywallBodyState();
}

class __PaywallBodyState extends State<_PaywallBody> {
  int selectedPlanIndex = 0; // Первый план выбран по умолчанию
  bool isSuccess = false;

  @override
  Widget build(BuildContext context) {
    if (isSuccess) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          alignment: Alignment.topCenter,
          children: [
            Positioned(
              top: 100.h,
              left: 0,
              right: 0,
              child: Image.asset('assets/confetty.png'),
            ),
            Positioned(
              top: 290.h,
              left: 0,
              right: 0,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  children: [
                    SizedBox(
                      width: 170.w,
                      height: 170.h,
                      child: Image.asset('assets/big_check.png'),
                    ),
                    SizedBox(height: 36.h),
                    Text('您的购买已成功完成！', style: context.styles.h2),
                    SizedBox(height: 12.h),
                    Text(
                      '恭喜您获得VIP专属权限，可查看个人八字命盘和深度运势分析！',
                      style: context.styles.h2,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Zbutton(
              action: () {
                // Возврат на домашний экран
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const HomePage()),
                  (route) => false,
                );
              },
              isLoading: false,
              isActive: true,
              text: '完成',
              textColor: Colors.white,
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 50.h),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    // Закрытие paywall и возврат на домашний экран
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const HomePage()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.close, size: 30),
                  padding: EdgeInsets.zero,
                  style: IconButton.styleFrom(padding: EdgeInsets.zero),
                ),
              ],
            ),
            SizedBox(
              height: 114.h,
              width: 111.w,
              child: Image.asset('assets/heads.png'),
            ),
            SizedBox(height: 18.h),
            Text('您的占卜已结束', style: context.styles.h2),
            SizedBox(height: 6.h),
            Text('升级VIP，畅享全部功能', style: context.styles.h2),
            SizedBox(height: 24.h),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('要继续并了解更多：', style: context.styles.mRegular),
                      SizedBox(height: 10.h),
                      ..._buildAdvantages(),
                      SizedBox(height: 32.h),
                      ..._buildPlans(),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              '自动续订，可随时取消。\n条款和隐私政策。恢复购买',
              style: context.styles.mDemilight.copyWith(
                color: Colors.black,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),
            Zbutton(
              action: () async {
                // Активируем подписку
                await _PaywallState._adaptyService.activateSubscription();
                setState(() {
                  isSuccess = true;
                });
              },
              isLoading: false,
              isActive: true,
              text: '立即更新',
              textColor: Colors.white,
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAdvantages() {
    List<String> texts = ['无限占卜', '无限的澄清和问题', '保存所有牌局在历史记录中'];
    return texts
        .map(
          (e) => Row(
            children: [
              SvgPicture.asset('assets/crown.svg', width: 16.w, height: 16.h),
              SizedBox(width: 12.w),
              Text(e, style: context.styles.mDemilight),
            ],
          ),
        )
        .toList();
  }

  List<Widget> _buildPlans() {
    final plans = [
      {
        'title': '1个月',
        'price': '¥18.9每月',
        'description': '在1个月 ¥18.9 然后 ¥28',
        'bonus:': '¥28',
      },
      {'title': '3个月', 'price': '¥58', 'description': '¥19.3每月'},
      {'title': '1年', 'price': '¥138', 'description': '¥11.5每月'},
    ];
    return plans
        .asMap()
        .entries
        .map(
          (entry) => _PlanCard(
            plan: entry.value,
            isSelected: selectedPlanIndex == entry.key,
            onTap: () => setState(() => selectedPlanIndex = entry.key),
            needsBottomPadding: entry.key == plans.length - 1,
          ),
        )
        .toList();
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.isSelected,
    required this.onTap,
    required this.needsBottomPadding,
    super.key,
  });
  final Map<String, String> plan;
  final bool isSelected;
  final VoidCallback onTap;
  final bool needsBottomPadding;

  @override
  Widget build(BuildContext context) {
    final hasDiscount = plan['bonus:'] != null;

    return Padding(
      padding: EdgeInsets.only(bottom: !needsBottomPadding ? 10.h : 0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          width: double.infinity,
          // height: 80.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Основное содержимое
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Row(
                  children: [
                    // Checkbox/иконка выбора
                    Container(
                      width: 24.w,
                      height: 24.h,
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? const Color(0xFF6B73FF)
                                : Colors.transparent,
                        border: Border.all(
                          color:
                              isSelected
                                  ? const Color(0xFF6B73FF)
                                  : Colors.grey.shade300,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child:
                          isSelected
                              ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              )
                              : null,
                    ),
                    SizedBox(width: 16.w),
                    // Информация о плане
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            plan['title'] ?? '',
                            style: context.styles.h3.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          if (plan['description'] != null)
                            Text(
                              plan['description']!,
                              style: context.styles.sDemilight.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Цена
                    Row(
                      // crossAxisAlignment: CrossAxisAlignment.end,
                      // mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (hasDiscount && plan['bonus:'] != null)
                          Text(
                            plan['bonus:']!,
                            style: context.styles.h3.copyWith(
                              color: Colors.grey.shade400,
                              decoration: TextDecoration.lineThrough,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        SizedBox(width: 4.w),
                        Text(
                          plan['price'] ?? '',
                          style: context.styles.h3.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Кнопка скидки для первого плана
              if (hasDiscount)
                Positioned(
                  right: 143.w,
                  top: -13.h,
                  child: Container(
                    width: 50.w,
                    height: 25.h,
                    // padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B73FF),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Center(
                      child: Text(
                        '折扣',
                        style: context.styles.mRegular.copyWith(
                          color: Colors.white,
                          height: 1.h,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
