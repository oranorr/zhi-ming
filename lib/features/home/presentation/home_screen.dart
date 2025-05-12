import 'package:flutter/material.dart';
import 'package:zhi_ming/core/widgets/z_scaffold.dart';
import 'package:zhi_ming/features/home/presentation/home_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return ZScaffold(
      isHome: true,
      child: PageView(
        children: [
          Container(child: Text('book')),
          HomePage(),

          Container(child: Text('user')),
        ],
      ),
    );
  }
}
