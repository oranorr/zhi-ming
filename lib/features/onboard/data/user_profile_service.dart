import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhi_ming/features/onboard/data/onboard_repo.dart';

/// Сервис для управления профилем пользователя
/// Сохраняет и загружает данные пользователя локально
class UserProfileService {
  factory UserProfileService() => _instance;
  UserProfileService._internal();
  static const String _userProfileKey = 'user_profile';
  static const String _onboardingCompletedKey = 'onboarding_completed';

  /// Singleton instance
  static final UserProfileService _instance = UserProfileService._internal();

  /// Сохранение профиля пользователя
  Future<bool> saveUserProfile(UserProfile profile) async {
    try {
      print('[UserProfileService] Сохранение профиля пользователя: $profile');

      final prefs = await SharedPreferences.getInstance();

      // Создаем обновленный профиль с текущими временными метками
      final updatedProfile = profile.copyWith(
        createdAt: profile.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Сохраняем профиль в JSON формате
      final profileJson = jsonEncode(updatedProfile.toJson());
      await prefs.setString(_userProfileKey, profileJson);

      print('[UserProfileService] Профиль успешно сохранен');
      return true;
    } catch (e) {
      print('[UserProfileService] Ошибка при сохранении профиля: $e');
      return false;
    }
  }

  /// Загрузка профиля пользователя
  Future<UserProfile?> loadUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileString = prefs.getString(_userProfileKey);

      if (profileString == null) {
        print('[UserProfileService] Профиль пользователя не найден');
        return null;
      }

      final profileJson = jsonDecode(profileString) as Map<String, dynamic>;
      final profile = UserProfile.fromJson(profileJson);

      print(
        '[UserProfileService] Профиль пользователя успешно загружен: ${profile.name}',
      );
      return profile;
    } catch (e) {
      print('[UserProfileService] Ошибка при загрузке профиля: $e');
      return null;
    }
  }

  /// Проверка, существует ли профиль пользователя
  Future<bool> hasUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_userProfileKey);
    } catch (e) {
      print('[UserProfileService] Ошибка при проверке наличия профиля: $e');
      return false;
    }
  }

  /// Удаление профиля пользователя
  Future<bool> deleteUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userProfileKey);
      await prefs.remove(_onboardingCompletedKey);

      print('[UserProfileService] Профиль пользователя удален');
      return true;
    } catch (e) {
      print('[UserProfileService] Ошибка при удалении профиля: $e');
      return false;
    }
  }

  /// Обновление профиля пользователя
  Future<bool> updateUserProfile(UserProfile updatedProfile) async {
    try {
      final existingProfile = await loadUserProfile();
      if (existingProfile == null) {
        print('[UserProfileService] Профиль не найден для обновления');
        return false;
      }

      // Сохраняем дату создания из существующего профиля
      final profileToSave = updatedProfile.copyWith(
        createdAt: existingProfile.createdAt,
        updatedAt: DateTime.now(),
      );

      return await saveUserProfile(profileToSave);
    } catch (e) {
      print('[UserProfileService] Ошибка при обновлении профиля: $e');
      return false;
    }
  }

  /// Сохранение статуса завершения онбординга
  Future<bool> saveOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingCompletedKey, true);
      print('[UserProfileService] Статус завершения онбординга сохранен');
      return true;
    } catch (e) {
      print(
        '[UserProfileService] Ошибка при сохранении статуса онбординга: $e',
      );
      return false;
    }
  }

  /// Проверка статуса завершения онбординга
  Future<bool> isOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_onboardingCompletedKey) ?? false;
    } catch (e) {
      print('[UserProfileService] Ошибка при проверке статуса онбординга: $e');
      return false;
    }
  }
}

/// Упрощенная модель профиля пользователя без json_annotation
/// для избежания проблем с генерацией кода
class UserProfile {
  const UserProfile({
    required this.name,
    required this.birthDate,
    this.birthTime,
    this.interests = const [],
    this.createdAt,
    this.updatedAt,
  });

  /// Фабричный конструктор для создания из JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] as String,
      birthDate: DateTime.parse(json['birthDate'] as String),
      birthTime:
          json['birthTime'] != null
              ? TimeOfDay(
                hour: json['birthTime']['hour'] as int,
                minute: json['birthTime']['minute'] as int,
              )
              : null,
      interests:
          (json['interests'] as List<dynamic>?)
              ?.map(
                (item) => OnboardRepo.interests.firstWhere(
                  (interest) => interest.name == item['name'],
                  orElse:
                      () => Interest(
                        name: item['name'] as String,
                        asset: 'assets/icons/default.png',
                        color: Colors.grey,
                      ),
                ),
              )
              .toList() ??
          [],
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : null,
      updatedAt:
          json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'] as String)
              : null,
    );
  }

  /// Имя пользователя
  final String name;

  /// Дата рождения
  final DateTime birthDate;

  /// Время рождения (может быть null, если пользователь пропустил)
  final TimeOfDay? birthTime;

  /// Список выбранных интересов
  final List<Interest> interests;

  /// Дата создания профиля
  final DateTime? createdAt;

  /// Дата последнего обновления профиля
  final DateTime? updatedAt;

  /// Создание копии с изменениями
  UserProfile copyWith({
    String? name,
    DateTime? birthDate,
    TimeOfDay? birthTime,
    List<Interest>? interests,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      birthTime: birthTime ?? this.birthTime,
      interests: interests ?? this.interests,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Конвертация в JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'birthDate': birthDate.toIso8601String(),
      'birthTime':
          birthTime != null
              ? {'hour': birthTime!.hour, 'minute': birthTime!.minute}
              : null,
      'interests':
          interests.map((interest) => {'name': interest.name}).toList(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Получение возраста пользователя
  int get age {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  /// Проверка, заполнен ли профиль полностью
  bool get isComplete {
    return name.isNotEmpty && interests.isNotEmpty;
  }

  /// Форматированная дата рождения
  String get formattedBirthDate {
    return '${birthDate.year}-${birthDate.month.toString().padLeft(2, '0')}-${birthDate.day.toString().padLeft(2, '0')}';
  }

  /// Форматированное время рождения
  String? get formattedBirthTime {
    if (birthTime == null) return null;
    return '${birthTime!.hour.toString().padLeft(2, '0')}:${birthTime!.minute.toString().padLeft(2, '0')}';
  }

  /// Список названий интересов
  List<String> get interestNames {
    return interests.map((interest) => interest.name).toList();
  }

  @override
  String toString() {
    return 'UserProfile(name: $name, birthDate: $formattedBirthDate, '
        'birthTime: $formattedBirthTime, interests: ${interestNames.join(', ')})';
  }
}
