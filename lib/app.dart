// final _routerConfig = appNavigationService.config;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zhi_ming/core/theme/themes.dart';
import 'package:zhi_ming/features/chat/presentation/chat_cubit.dart';
import 'package:zhi_ming/features/home/presentation/home_page.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  void initState() {
    super.initState();
    // _setupRouterListener();
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
          providers: [BlocProvider(create: (_) => ChatCubit())],
          child: MaterialApp(
            title: 'Pivot App',
            theme: AppTheme.light(),
            themeMode: ThemeMode.light,
            home: const HomePage(),
            // routerConfig: _routerConfig,
            // scaffoldMessengerKey: scaffoldKey,
          ),
        );
      },
    );
  }
}
