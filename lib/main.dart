import 'package:adapty_flutter/adapty_flutter.dart';
import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zhi_ming/app.dart';
import 'package:zhi_ming/features/adapty/data/repositories/adapty_repository_impl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация Adapty SDK с предоставленным API ключом
  // ВНИМАНИЕ: Для публичной демонстрации ключ заменён на заглушку.
  // Подставьте свой реальный ключ для работы приложения в продакшн/разработке.
  // WARNING: For public demo, the key is replaced with a placeholder.
  // Insert your real Adapty API key for production/development use.
  try {
    await Adapty().activate(
      configuration: AdaptyConfiguration(apiKey: 'YOUR_ADAPTY_API_KEY')
        ..withLogLevel(
          AdaptyLogLevel.verbose,
        ), // Включаем подробные логи для отладки
    );
    debugPrint('[main] Adapty SDK успешно активирован');

    // Инициализация нашего репозитория Adapty
    await AdaptyRepositoryImpl.instance.initialize();
    debugPrint('[main] AdaptyRepository успешно инициализирован');
  } catch (e) {
    debugPrint('[main] Ошибка инициализации Adapty: $e');
  }

  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: await getApplicationDocumentsDirectory(),
  );

  runApp(const App());
}
