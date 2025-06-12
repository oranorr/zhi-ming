import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zhi_ming/core/services/user_service.dart';
import 'package:zhi_ming/core/theme/themes.dart';
import 'package:zhi_ming/features/adapty/presentation/paywall.dart';
import 'package:zhi_ming/features/chat/presentation/chat_cubit.dart';
import 'package:zhi_ming/features/home/presentation/home_screen.dart';
import 'package:zhi_ming/features/onboard/presentation/onboard_cubit.dart';
import 'package:zhi_ming/features/onboard/presentation/onboard_screen.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  // Сервис для работы с профилем пользователя
  final UserService _userService = UserService();

  // Флаг, указывающий на прохождение онбординга
  bool _onboardingCompleted = false;

  // Флаг для отслеживания завершения проверки статуса
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    unawaited(_checkOnboardingStatus());
  }

  /// Проверяет, был ли пройден онбординг и загружает профиль пользователя
  Future<void> _checkOnboardingStatus() async {
    try {
      print(
        '[App] Проверка статуса онбординга и загрузка профиля пользователя',
      );

      // Проверяем статус онбординга через UserService
      final onboardingCompleted = await _userService.isOnboardingCompleted();

      // Если онбординг завершен, предзагружаем профиль пользователя
      if (onboardingCompleted) {
        final profile = await _userService.getUserProfile();
        if (profile != null) {
          print('[App] Профиль пользователя загружен: ${profile.name}');
          print(
            '[App] Краткая информация: ${await _userService.getUserSummary()}',
          );
        } else {
          print('[App] Онбординг завершен, но профиль пользователя не найден');
        }
      }

      setState(() {
        _onboardingCompleted = onboardingCompleted;
        _isInitializing = false;
      });

      print(
        '[App] Статус онбординга: ${onboardingCompleted ? "завершен" : "не завершен"}',
      );
    } on Exception catch (e) {
      debugPrint('[App] Ошибка при проверке статуса онбординга: $e');
      setState(() {
        _onboardingCompleted = false;
        _isInitializing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => ChatCubit()),
            BlocProvider(create: (_) => OnboardCubit()),
          ],
          child: MaterialApp(
            title: 'Zhi Ming',
            theme: AppTheme.light(),
            themeMode: ThemeMode.light,
            home:
                // const _LoadingScreen(),
                // const Paywall(),
                _isInitializing
                    ? const _LoadingScreen() // Экран загрузки пока проверяем статус
                    // : !kDebugMode
                    : _onboardingCompleted
                    ? const HomeScreen() // Если онбординг пройден, показываем главную страницу
                    : const OnboardScreen(), // Иначе показываем экран онбординга
            // routerConfig: _routerConfig,
            // scaffoldMessengerKey: scaffoldKey,
          ),
        );
      },
    );
  }
}

/// Виджет экрана загрузки
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          // gradient: LinearGradient(
          //   begin: Alignment(-1.8, 1.8), // широкий разброс
          //   end: Alignment(1.8, -1.5), // противоположный край
          //   colors: [
          //     Color(0x00FFFFFF),
          //     Color(0x44714EFF), // 26% прозрачности
          //     Color(0x66BC73F3), // 40%
          //     Color(0x665990FF), // 40%
          //     Color(0x00FFFFFF),
          //   ],
          //   stops: [0.0, 0.1, 0.14, 0.45, 1.2],
          // ),
        ),

        child: Center(child: Text('loading')),
      ),
    );
  }
}
