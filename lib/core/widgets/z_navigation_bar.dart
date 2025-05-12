import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:zhi_ming/core/theme/theme_colors.dart';

class ZNavigationBar extends StatefulWidget {
  const ZNavigationBar({super.key});

  @override
  State<ZNavigationBar> createState() => _ZNavigationBarState();
}

class _ZNavigationBarState extends State<ZNavigationBar> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final Color iconColor = ZColors.blueDark;
    final Color indicatorColor = ZColors.pinkLight;
    final Color navigationBarBackgroundColor = Colors.white;
    final assets = ['assets/book.svg', 'assets/home.svg', 'assets/user.svg'];

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20.0,
        vertical: 34,
      ).copyWith(top: 0),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: navigationBarBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.white,
              blurRadius: 50,
              offset: Offset(1, 30),
            ),
          ],
          borderRadius: BorderRadius.circular(50.0),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(50.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              assets.length,
              (index) => GestureDetector(
                onTap: () {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        _currentIndex == index
                            ? indicatorColor.withOpacity(1)
                            : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
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
