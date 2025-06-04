import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zhi_ming/core/extensions/build_context_extension.dart';
import 'package:zhi_ming/core/services/user_service.dart';
import 'package:zhi_ming/core/widgets/z_scaffold.dart';
import 'package:zhi_ming/features/onboard/data/user_profile_service.dart';

/// Отладочный экран для просмотра и управления профилем пользователя
/// Полезен для тестирования функций сохранения и загрузки данных
class UserProfileDebugScreen extends StatefulWidget {
  const UserProfileDebugScreen({super.key});

  @override
  State<UserProfileDebugScreen> createState() => _UserProfileDebugScreenState();
}

class _UserProfileDebugScreenState extends State<UserProfileDebugScreen> {
  final UserService _userService = UserService();
  UserProfile? _currentProfile;
  bool _isLoading = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  /// Загрузка профиля пользователя
  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Загрузка профиля...';
    });

    try {
      print('[UserProfileDebugScreen] Загрузка профиля пользователя');
      final profile = await _userService.getUserProfile(forceRefresh: true);

      setState(() {
        _currentProfile = profile;
        _isLoading = false;
        _statusMessage =
            profile != null ? 'Профиль загружен успешно' : 'Профиль не найден';
      });

      if (profile != null) {
        print('[UserProfileDebugScreen] Профиль загружен: $profile');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Ошибка при загрузке: $e';
      });
      print('[UserProfileDebugScreen] Ошибка при загрузке профиля: $e');
    }
  }

  /// Удаление профиля пользователя
  Future<void> _deleteUserProfile() async {
    final confirmed = await _showConfirmationDialog(
      'Удалить профиль?',
      'Это действие нельзя отменить. Все данные пользователя будут удалены.',
    );

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Удаление профиля...';
    });

    try {
      print('[UserProfileDebugScreen] Удаление профиля пользователя');
      final success = await _userService.deleteUserProfile();

      setState(() {
        _currentProfile = null;
        _isLoading = false;
        _statusMessage =
            success ? 'Профиль успешно удален' : 'Ошибка при удалении профиля';
      });

      if (success) {
        print('[UserProfileDebugScreen] Профиль удален успешно');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Ошибка при удалении: $e';
      });
      print('[UserProfileDebugScreen] Ошибка при удалении профиля: $e');
    }
  }

  /// Показ диалога подтверждения
  Future<bool> _showConfirmationDialog(String title, String content) async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text(title),
                content: Text(content),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Отмена'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Удалить'),
                  ),
                ],
              ),
        ) ??
        false;
  }

  /// Получение краткой информации о пользователе
  Future<void> _showUserSummary() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Получение информации...';
    });

    try {
      final summary = await _userService.getUserSummary();

      if (mounted) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Информация о пользователе'),
                content: Text(summary),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      }

      setState(() {
        _isLoading = false;
        _statusMessage = 'Информация получена';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Ошибка при получении информации: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ZScaffold(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Text('Отладка профиля пользователя', style: context.styles.h2),

            SizedBox(height: 20.h),

            // Статус
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(_statusMessage, style: context.styles.mRegular),
            ),

            SizedBox(height: 20.h),

            // Кнопки управления
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _loadUserProfile,
                    child: const Text('Обновить'),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _showUserSummary,
                    child: const Text('Сводка'),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _deleteUserProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Удалить'),
                  ),
                ),
              ],
            ),

            SizedBox(height: 30.h),

            // Отображение данных профиля
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_currentProfile != null)
              Expanded(child: _buildProfileInfo())
            else
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_off, size: 64.r, color: Colors.grey),
                      SizedBox(height: 16.h),
                      Text(
                        'Профиль пользователя не найден',
                        style: context.styles.lRegular.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Виджет для отображения информации о профиле
  Widget _buildProfileInfo() {
    final profile = _currentProfile!;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Основная информация
          _buildInfoSection('Основная информация', [
            _buildInfoRow('Имя', profile.name),
            _buildInfoRow('Возраст', '${profile.age} лет'),
            _buildInfoRow('Дата рождения', profile.formattedBirthDate),
            if (profile.formattedBirthTime != null)
              _buildInfoRow('Время рождения', profile.formattedBirthTime!),
          ]),

          SizedBox(height: 20.h),

          // Интересы
          _buildInfoSection('Интересы', [
            for (final interest in profile.interestNames)
              _buildInfoRow('•', interest),
          ]),

          SizedBox(height: 20.h),

          // Метаданные
          _buildInfoSection('Метаданные', [
            if (profile.createdAt != null)
              _buildInfoRow('Создано', _formatDateTime(profile.createdAt!)),
            if (profile.updatedAt != null)
              _buildInfoRow('Обновлено', _formatDateTime(profile.updatedAt!)),
            _buildInfoRow('Статус', profile.isComplete ? 'Полный' : 'Неполный'),
          ]),
        ],
      ),
    );
  }

  /// Секция информации
  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: context.styles.h4),
        SizedBox(height: 10.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  /// Строка информации
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.w,
            child: Text(
              label,
              style: context.styles.mRegular.copyWith(color: Colors.grey[600]),
            ),
          ),
          Expanded(child: Text(value, style: context.styles.mRegular)),
        ],
      ),
    );
  }

  /// Форматирование даты и времени
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
