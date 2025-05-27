import 'package:flutter/material.dart';

abstract class ZColors {
  static const LinearGradient homeGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.3, 0.6, 0.85, 1.0],
    colors: [
      Color.fromRGBO(255, 255, 255, 0), // #FFFFFF 0%
      Color.fromRGBO(113, 78, 255, 0.2), // #714EFF 20%
      Color.fromRGBO(188, 115, 243, 0.2), // #BC73F3 20%
      Color.fromRGBO(89, 144, 255, 0.15), // #5990FF 15%
      Color.fromRGBO(255, 255, 255, 0), // #FFFFFF 0%
    ],
  );
  static const LinearGradient chatGradient = LinearGradient(
    begin: AlignmentDirectional(0.3, -0.8),
    end: AlignmentDirectional(-0.3, 0.8),
    stops: [0.0, 0.2, 0.5, 0.8, 1.0],
    colors: [
      Color.fromRGBO(240, 241, 242, 1), // F0F1F2 base color
      Color.fromRGBO(113, 78, 255, 0.04), // 714EFF very soft
      Color.fromRGBO(188, 115, 243, 0.08), // BC73F3 gentle center
      Color.fromRGBO(89, 144, 255, 0.05), // 5990FF very soft
      Color.fromRGBO(240, 241, 242, 1), // F0F1F2 base color
    ],
  );
  static const Color black = Colors.black;
  static const Color blueDark = Color(0xff7379F3);
  static const Color blueMiddle = Color(0xff96D8E9);
  static const Color blueLight = Color(0xffC0F2FF);
  static const Color purpleMiddle = Color(0xffADA9E8);
  static const Color purpleLight = Color(0xffD7D4FF);
  static const Color pinkDark = Color(0xffD6A0EA);
  static const Color pinkMiddle = Color(0xffF3D3FF);
  static const Color pinkLight = Color(0xffEEEFFF);
  static const Color yellowMiddle = Color(0xffCBE39D);
  static const Color yellowLight = Color(0xffEDFFCC);
  static const Color white = Color(0xffFFFDF9);
  static const Color gray = Color(0xffE6E5E8);
  static const Color grayDark = Color(0xff929292);
}
