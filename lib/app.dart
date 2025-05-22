// final _routerConfig = appNavigationService.config;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhi_ming/core/theme/themes.dart';
import 'package:zhi_ming/features/chat/presentation/chat_cubit.dart';
import 'package:zhi_ming/features/home/presentation/home_page.dart';
import 'package:zhi_ming/features/onboard/presentation/onboard_cubit.dart';
import 'package:zhi_ming/features/onboard/presentation/onboard_screen.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  // Константа для ключа в SharedPreferences
  static const String _onboardingCompletedKey = 'onboarding_completed';

  // Флаг, указывающий на прохождение онбординга
  bool _onboardingCompleted = false;

  // Флаг для отслеживания завершения проверки статуса
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  /// Проверяет, был ли пройден онбординг
  Future<void> _checkOnboardingStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final onboardingCompleted =
          prefs.getBool(_onboardingCompletedKey) ?? false;

      setState(() {
        _onboardingCompleted = onboardingCompleted;
        _isInitializing = false;
      });
    } catch (e) {
      print('Ошибка при проверке статуса онбординга: $e');
      setState(() {
        _onboardingCompleted = false;
        _isInitializing = false;
      });
    }
  }

  // void _setupRouterListener() {
  //   _routerConfig.routeInformationProvider.addListener(() {
  //     // Получаем текущую локацию
  //     final String currentPath = appNavigationService.currentPath;
  //     final String? currentScreenName = _extractScreenName(currentPath);

  //     if (currentScreenName != null) {
  //       // Логируем просмотр экрана
  //       analytics.logScreenView(
  //         screenName: currentScreenName,
  //         screenClass: currentScreenName,
  //       );
  //     }
  //   });
  // }

  // String? _extractScreenName(String path) {
  //   // Удаляем параметры URL и получаем название экрана
  //   final uri = Uri.parse(path);
  //   final cleanPath = uri.path;

  //   // Возвращаем последний сегмент пути как название экрана
  //   // Или первый сегмент, если путь состоит только из одного сегмента
  //   final segments = cleanPath.split('/').where((s) => s.isNotEmpty).toList();
  //   if (segments.isEmpty) return 'Home';
  //   return segments.last;
  // }

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
            title: 'Pivot App',
            theme: AppTheme.light(),
            themeMode: ThemeMode.light,
            home:
                _isInitializing
                    ? const _LoadingScreen() // Экран загрузки пока проверяем статус
                    // : !kDebugMode
                    : _onboardingCompleted
                    ? const HomePage() // Если онбординг пройден, показываем главную страницу
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
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
