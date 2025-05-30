// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

import 'package:zhi_ming/core/theme/theme_colors.dart';
import 'package:zhi_ming/core/widgets/z_navigation_bar.dart';

class ZScaffold extends StatelessWidget {
  final Widget child;
  final bool? isHome;
  final bool? isChat;
  const ZScaffold({
    required this.child,
    super.key,
    this.isHome = true,
    this.isChat = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: isHome == true ? const ZNavigationBar() : null,
      extendBody: isHome ?? false,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient:
              (isChat ?? false)
                  ? ZColors.chatGradient.withOpacity(0.2)
                  : ZColors.homeGradient,
        ),
        child: Center(child: child),
      ),
    );
  }
}
