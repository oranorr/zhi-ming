import 'package:flutter/material.dart';
import 'package:zhi_ming/core/extensions/build_context_extension.dart';
import 'package:zhi_ming/core/widgets/z_scaffold.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ZScaffold(
      isHome: false,
      child: Text('Profile Page brother', style: context.styles.h1),
    );
  }
}
