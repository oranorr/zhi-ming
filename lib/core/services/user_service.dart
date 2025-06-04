import 'package:zhi_ming/features/onboard/data/user_profile_service.dart';

/// Глобальный сервис для работы с профилем пользователя
/// Предоставляет единую точку доступа к данным пользователя из любой части приложения
class UserService {
  factory UserService() => _instance;
  UserService._internal();

  /// Singleton instance
  static final UserService _instance = UserService._internal();

  /// Сервис для работы с профилем пользователя
  final UserProfileService _userProfileService = UserProfileService();

  /// Кешированный профиль пользователя
  UserProfile? _cachedProfile;

  /// Получение профиля пользователя (с кешированием)
  Future<UserProfile?> getUserProfile({bool forceRefresh = false}) async {
    try {
      // Если профиль не закеширован или требуется обновление
      if (_cachedProfile == null || forceRefresh) {
        print('[UserService] Загрузка профиля пользователя');
        _cachedProfile = await _userProfileService.loadUserProfile();
      }

      return _cachedProfile;
    } catch (e) {
      print('[UserService] Ошибка при получении профиля пользователя: $e');
      return null;
    }
  }

  /// Проверка, есть ли у пользователя сохраненный профиль
  Future<bool> hasUserProfile() async {
    try {
      return await _userProfileService.hasUserProfile();
    } catch (e) {
      print('[UserService] Ошибка при проверке наличия профиля: $e');
      return false;
    }
  }

  /// Обновление профиля пользователя
  Future<bool> updateUserProfile(UserProfile updatedProfile) async {
    try {
      final success = await _userProfileService.updateUserProfile(
        updatedProfile,
      );

      if (success) {
        // Обновляем кеш
        _cachedProfile = updatedProfile;
        print('[UserService] Профиль пользователя обновлен');
      }

      return success;
    } catch (e) {
      print('[UserService] Ошибка при обновлении профиля: $e');
      return false;
    }
  }

  /// Удаление профиля пользователя и сброс онбординга
  Future<bool> deleteUserProfile() async {
    try {
      final success = await _userProfileService.deleteUserProfile();

      if (success) {
        // Очищаем кеш
        _cachedProfile = null;
        print('[UserService] Профиль пользователя удален');
      }

      return success;
    } catch (e) {
      print('[UserService] Ошибка при удалении профиля: $e');
      return false;
    }
  }

  /// Проверка статуса завершения онбординга
  Future<bool> isOnboardingCompleted() async {
    try {
      return await _userProfileService.isOnboardingCompleted();
    } catch (e) {
      print('[UserService] Ошибка при проверке статуса онбординга: $e');
      return false;
    }
  }

  /// Получение имени пользователя
  Future<String?> getUserName() async {
    final profile = await getUserProfile();
    return profile?.name;
  }

  /// Получение возраста пользователя
  Future<int?> getUserAge() async {
    final profile = await getUserProfile();
    return profile?.age;
  }

  /// Получение интересов пользователя
  Future<List<String>?> getUserInterests() async {
    final profile = await getUserProfile();
    return profile?.interestNames;
  }

  /// Получение даты рождения пользователя в форматированном виде
  Future<String?> getFormattedBirthDate() async {
    final profile = await getUserProfile();
    return profile?.formattedBirthDate;
  }

  /// Получение времени рождения пользователя в форматированном виде
  Future<String?> getFormattedBirthTime() async {
    final profile = await getUserProfile();
    return profile?.formattedBirthTime;
  }

  /// Очистка кеша профиля (полезно для тестирования)
  void clearCache() {
    _cachedProfile = null;
    print('[UserService] Кеш профиля очищен');
  }

  /// Проверка, заполнен ли профиль полностью
  Future<bool> isProfileComplete() async {
    final profile = await getUserProfile();
    return profile?.isComplete ?? false;
  }

  /// Получение краткой информации о пользователе для логирования
  Future<String> getUserSummary() async {
    try {
      final profile = await getUserProfile();

      if (profile == null) {
        return 'Профиль пользователя не найден';
      }

      return 'Пользователь: ${profile.name}, возраст: ${profile.age}, '
          'интересы: ${profile.interestNames.join(', ')}';
    } catch (e) {
      return 'Ошибка при получении информации о пользователе: $e';
    }
  }
}
