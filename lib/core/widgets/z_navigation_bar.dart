import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:zhi_ming/core/theme/theme_colors.dart';

class ZNavigationBar extends StatelessWidget {
  const ZNavigationBar({
    required this.currentIndex,
    required this.onTap,
    super.key,
  });
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    const Color iconColor = ZColors.blueDark;
    const Color indicatorColor = ZColors.pinkLight;
    const Color navigationBarBackgroundColor = Colors.white;
    final assets = ['assets/book.svg', 'assets/home.svg', 'assets/user.svg'];

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 34,
      ).copyWith(top: 0),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: navigationBarBackgroundColor,
          boxShadow: const [
            BoxShadow(
              color: Colors.white,
              blurRadius: 50,
              offset: Offset(1, 30),
            ),
          ],
          borderRadius: BorderRadius.circular(50),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              assets.length,
              (index) => GestureDetector(
                onTap: () => onTap(index),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color:
                        currentIndex == index
                            ? indicatorColor.withOpacity(1)
                            : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: SvgPicture.asset(assets[index], color: iconColor),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
