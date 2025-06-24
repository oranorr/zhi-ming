import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zhi_ming/core/extensions/build_context_extension.dart';
import 'package:zhi_ming/core/services/user_service.dart';
import 'package:zhi_ming/core/widgets/z_button.dart';
import 'package:zhi_ming/features/adapty/data/repositories/adapty_repository_impl.dart';
import 'package:zhi_ming/features/adapty/domain/models/subscription_status.dart';
import 'package:zhi_ming/features/onboard/data/user_profile_service.dart';

/// Простая страница профиля пользователя для редактирования основных данных
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final UserService _userService = UserService();
  UserProfile? _userProfile;
  SubscriptionStatus? _subscriptionStatus;
  bool _isLoading = true;
  bool _isResetting = false;

  // Контроллеры для полей
  late TextEditingController _nameController;
  late TextEditingController _birthDateController;
  late TextEditingController _birthTimeController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _birthDateController = TextEditingController();
    _birthTimeController = TextEditingController();
    _loadUserProfile();
    _loadSubscriptionStatus();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birthDateController.dispose();
    _birthTimeController.dispose();
    super.dispose();
  }

  /// Загрузка профиля пользователя
  Future<void> _loadUserProfile() async {
    try {
      print('[ProfilePage] Загрузка профиля пользователя');
      final profile = await _userService.getUserProfile(forceRefresh: true);

      if (profile != null) {
        setState(() {
          _userProfile = profile;
          _nameController.text = profile.name;
          _birthDateController.text = profile.formattedBirthDate;
          _birthTimeController.text = profile.formattedBirthTime ?? '';
          _isLoading = false;
        });
        print('[ProfilePage] Профиль загружен: ${profile.name}');
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('[ProfilePage] Ошибка при загрузке профиля: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Загрузка статуса подписки
  Future<void> _loadSubscriptionStatus() async {
    try {
      print('[ProfilePage] Загрузка статуса подписки');

      // Проверяем, инициализирован ли Adapty
      if (AdaptyRepositoryImpl.instance.isInitialized) {
        final subscriptionStatus =
            await AdaptyRepositoryImpl.instance.getSubscriptionStatus();

        if (mounted) {
          setState(() {
            _subscriptionStatus = subscriptionStatus;
          });
          print(
            '[ProfilePage] Статус подписки загружен: ${subscriptionStatus.isActive}',
          );
        }
      } else {
        print('[ProfilePage] AdaptyRepository не инициализирован');
      }
    } catch (e) {
      print('[ProfilePage] Ошибка при загрузке статуса подписки: $e');
    }
  }

  /// Автоматическое сохранение имени при изменении
  Future<void> _autoSaveName() async {
    if (_userProfile == null) return;

    try {
      print(
        '[ProfilePage] Автосохранение имени: ${_nameController.text.trim()}',
      );

      final updatedProfile = _userProfile!.copyWith(
        name: _nameController.text.trim(),
      );

      final success = await _userService.updateUserProfile(updatedProfile);

      if (success) {
        setState(() {
          _userProfile = updatedProfile;
        });
        print('[ProfilePage] Имя автоматически сохранено');
      }
    } catch (e) {
      print('[ProfilePage] Ошибка при автосохранении имени: $e');
    }
  }

  /// Автоматическое сохранение даты рождения
  Future<void> _autoSaveBirthDate(DateTime selectedDate) async {
    if (_userProfile == null) return;

    try {
      print(
        '[ProfilePage] Автосохранение даты рождения: ${selectedDate.toIso8601String()}',
      );

      final updatedProfile = _userProfile!.copyWith(birthDate: selectedDate);

      final success = await _userService.updateUserProfile(updatedProfile);

      if (success) {
        setState(() {
          _userProfile = updatedProfile;
          _birthDateController.text = updatedProfile.formattedBirthDate;
        });
        print('[ProfilePage] Дата рождения автоматически сохранена');
      }
    } catch (e) {
      print('[ProfilePage] Ошибка при автосохранении даты рождения: $e');
    }
  }

  /// Автоматическое сохранение времени рождения
  Future<void> _autoSaveBirthTime(TimeOfDay selectedTime) async {
    if (_userProfile == null) return;

    try {
      print(
        '[ProfilePage] Автосохранение времени рождения: ${selectedTime.hour}:${selectedTime.minute}',
      );

      final updatedProfile = _userProfile!.copyWith(birthTime: selectedTime);

      final success = await _userService.updateUserProfile(updatedProfile);

      if (success) {
        setState(() {
          _userProfile = updatedProfile;
          _birthTimeController.text = updatedProfile.formattedBirthTime ?? '';
        });
        print('[ProfilePage] Время рождения автоматически сохранено');
      }
    } catch (e) {
      print('[ProfilePage] Ошибка при автосохранении времени рождения: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('个人主页'), // "Личная главная"
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _userProfile == null
              ? _buildErrorState()
              : _buildProfileForm(),
    );
  }

  /// Состояние ошибки
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64.r, color: Colors.grey),
          SizedBox(height: 16.h),
          Text(
            '未找到个人资料', // "Профиль не найден"
            style: context.styles.h3.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// Форма редактирования профиля
  Widget _buildProfileForm() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),

      child: Column(
        children: [
          SizedBox(height: 20.h),

          // Поле имени - теперь с автосохранением
          _buildInputField(
            label: '名称', // "Имя"
            controller: _nameController,
            enabled: true,
            onChanged: (value) {
              // Автосохранение имени с небольшой задержкой после ввода
              Future.delayed(const Duration(milliseconds: 500), () {
                if (_nameController.text.trim() != _userProfile?.name) {
                  _autoSaveName();
                }
              });
            },
          ),

          SizedBox(height: 20.h),

          // Поле даты рождения - теперь кликабельное
          _buildInputField(
            label: '出生日期', // "Дата рождения"
            controller: _birthDateController,
            enabled: true, // Отключаем прямое редактирование
            onTap: _showDatePicker, // Добавляем обработчик нажатия
          ),

          SizedBox(height: 20.h),

          // Поле времени рождения - теперь кликабельное
          _buildInputField(
            label: '出生时辰', // "Время рождения"
            controller: _birthTimeController,
            enabled: true, // Отключаем прямое редактирование
            onTap: _showTimePicker, // Добавляем обработчик нажатия
          ),

          SizedBox(height: 30.h),

          // Кнопка AI&Privacy
          _buildAIPrivacyButton(),

          // const Spacer(),
          SizedBox(height: 190.h),

          // Показываем VIP блок только если есть активная подписка
          if (_subscriptionStatus?.isActive ?? false) _buildVIPBlock(),

          // Раздел отладки (только в debug режиме)
          if (kDebugMode) ...[SizedBox(height: 40.h), _buildDebugSection()],

          SizedBox(height: 100.h),
        ],
      ),
    );
  }

  /// Поле ввода
  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required bool enabled,
    VoidCallback? onTap,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок поля
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
          child: Text(label, style: context.styles.mRegular),
        ),

        // Поле ввода
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            onTap: onTap,
            readOnly: onTap != null, // Если есть onTap, делаем поле read-only
            style: context.styles.mDemilight,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 12.h,
              ),
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  /// VIP блок - отображается только при активной подписке
  Widget _buildVIPBlock() {
    // Получаем дату истечения подписки
    final expirationDate = _subscriptionStatus?.expirationDate;

    // Форматируем дату для отображения
    String expirationText = '无限期有效'; // "Действует бессрочно"
    if (expirationDate != null) {
      expirationText =
          '订阅有效期至${expirationDate.year}年${expirationDate.month}月${expirationDate.day}日';
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E8), // Светло-зеленый фон как на картинке
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        children: [
          // Иконка короны
          SizedBox(
            width: 32.w,
            height: 32.h,
            child: SvgPicture.asset('assets/crown.svg'),
          ),

          SizedBox(width: 12.w),

          // Текст VIP
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VIP会员已生效', // "VIP членство активировано"
                  style: context.styles.mMedium.copyWith(
                    color: Colors.green[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  expirationText,
                  style: context.styles.sDemilight.copyWith(
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Раздел отладки - отображается только в debug режиме
  Widget _buildDebugSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🔧 Отладка (DEBUG)',
            style: context.styles.mMedium.copyWith(
              color: Colors.red[800],
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12.h),

          Text(
            'Статус подписки:',
            style: context.styles.sDemilight.copyWith(color: Colors.red[700]),
          ),
          Text(
            'hasUsedFreeReading: ${_subscriptionStatus?.hasUsedFreeReading ?? 'unknown'}',
            style: context.styles.sDemilight.copyWith(color: Colors.red[600]),
          ),
          Text(
            'canStartNewReading: ${_subscriptionStatus?.canStartNewReading ?? 'unknown'}',
            style: context.styles.sDemilight.copyWith(color: Colors.red[600]),
          ),
          Text(
            'remainingFollowUpQuestions: ${_subscriptionStatus?.remainingFollowUpQuestions ?? 'unknown'}',
            style: context.styles.sDemilight.copyWith(color: Colors.red[600]),
          ),

          SizedBox(height: 16.h),

          // Кнопки для сброса данных
          Row(
            children: [
              Expanded(
                child: Zbutton(
                  action: _resetFreeReadingFlag,
                  isLoading: _isResetting,
                  isActive: !_isResetting,
                  text: 'Сброс флага',
                  textColor: Colors.white,
                  color: Colors.orange,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Zbutton(
                  action: _resetAllUserData,
                  isLoading: _isResetting,
                  isActive: !_isResetting,
                  text: 'Сброс всех данных',
                  textColor: Colors.white,
                  color: Colors.red,
                ),
              ),
            ],
          ),

          SizedBox(height: 8.h),

          // Кнопка для логирования состояния
          Zbutton(
            action: _logUserState,
            isLoading: false,
            isActive: true,
            text: 'Логировать состояние в консоль',
            textColor: Colors.white,
            color: Colors.blue,
          ),
        ],
      ),
    );
  }

  /// Показать попап выбора даты в стиле Apple
  Future<void> _showDatePicker() async {
    print('[ProfilePage] Показ попапа выбора даты');

    // Инициализируем временную дату текущей датой рождения
    DateTime? tempSelectedDate = _userProfile?.birthDate;

    print(
      '[ProfilePage] Инициализирована временная дата: ${tempSelectedDate?.toIso8601String()}',
    );

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          height: 400.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            children: [
              // Заголовок попапа
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.w),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                child: Text(
                  '请选择出生日期', // "Пожалуйста, выберите дату рождения"
                  style: context.styles.mRegular,
                  textAlign: TextAlign.center,
                ),
              ),

              // Picker для выбора даты
              Expanded(
                child: StatefulBuilder(
                  builder: (context, setModalState) {
                    return CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.date,
                      initialDateTime:
                          tempSelectedDate ?? DateTime(1990, 5, 20),
                      minimumDate: DateTime(1900),
                      maximumDate: DateTime.now(),
                      onDateTimeChanged: (DateTime date) {
                        print(
                          '[ProfilePage] Изменена дата в пикере: ${date.toIso8601String()}',
                        );
                        setModalState(() {
                          tempSelectedDate = date;
                        });
                      },
                    );
                  },
                ),
              ),

              // Кнопка сохранения
              SizedBox(height: 10.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Zbutton(
                  action: () {
                    print(
                      '[ProfilePage] Сохранение выбранной даты: ${tempSelectedDate?.toIso8601String()}',
                    );

                    if (tempSelectedDate != null) {
                      // Автоматическое сохранение при нажатии кнопки
                      _autoSaveBirthDate(tempSelectedDate!);
                    }

                    Navigator.of(context).pop();
                  },
                  isLoading: false,
                  isActive: true,
                  text: '保存',
                  textColor: Colors.white,
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        );
      },
    );
  }

  /// Показать попап выбора времени в стиле Apple
  Future<void> _showTimePicker() async {
    print('[ProfilePage] Показ попапа выбора времени');

    // Инициализируем временное время текущим временем рождения или 12:00
    TimeOfDay? tempSelectedTime = _userProfile?.birthTime;

    print(
      '[ProfilePage] Инициализировано временное время: ${tempSelectedTime?.hour}:${tempSelectedTime?.minute}',
    );

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          height: 400.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            children: [
              // Заголовок попапа
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.w),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                child: Text(
                  '请选择出生时辰', // "Пожалуйста, выберите время рождения"
                  style: context.styles.mRegular,
                  textAlign: TextAlign.center,
                ),
              ),

              // Picker для выбора времени
              Expanded(
                child: StatefulBuilder(
                  builder: (context, setModalState) {
                    return CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.time,
                      use24hFormat: true,
                      initialDateTime: DateTime(
                        2024,
                        1,
                        1,
                        tempSelectedTime?.hour ?? 12,
                        tempSelectedTime?.minute ?? 0,
                      ),
                      onDateTimeChanged: (DateTime dateTime) {
                        print(
                          '[ProfilePage] Изменено время в пикере: ${dateTime.hour}:${dateTime.minute}',
                        );
                        setModalState(() {
                          tempSelectedTime = TimeOfDay(
                            hour: dateTime.hour,
                            minute: dateTime.minute,
                          );
                        });
                      },
                    );
                  },
                ),
              ),

              // Кнопка сохранения
              SizedBox(height: 10.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Zbutton(
                  action: () {
                    print(
                      '[ProfilePage] Сохранение выбранного времени: ${tempSelectedTime?.hour}:${tempSelectedTime?.minute}',
                    );

                    if (tempSelectedTime != null) {
                      // Автоматическое сохранение при нажатии кнопки
                      _autoSaveBirthTime(tempSelectedTime!);
                    }

                    Navigator.of(context).pop();
                  },
                  isLoading: false,
                  isActive: true,
                  text: '保存',
                  textColor: Colors.white,
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        );
      },
    );
  }

  /// Сброс флага бесплатного гадания (для отладки)
  Future<void> _resetFreeReadingFlag() async {
    try {
      setState(() {
        _isResetting = true;
      });

      await AdaptyRepositoryImpl.instance.resetFreeReadingFlag();
      await _loadSubscriptionStatus(); // Перезагружаем статус

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Флаг бесплатного гадания сброшен'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('[ProfilePage] Ошибка сброса флага: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка сброса флага: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResetting = false;
        });
      }
    }
  }

  /// Полный сброс всех данных пользователя (для отладки)
  Future<void> _resetAllUserData() async {
    try {
      setState(() {
        _isResetting = true;
      });

      await AdaptyRepositoryImpl.instance.resetUserData();
      await _loadSubscriptionStatus(); // Перезагружаем статус

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Все данные пользователя сброшены'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('[ProfilePage] Ошибка сброса данных: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка сброса данных: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResetting = false;
        });
      }
    }
  }

  /// Логирование состояния пользователя в консоль
  Future<void> _logUserState() async {
    try {
      print('[ProfilePage] Логирование состояния пользователя');

      // Детальное логирование через репозиторий
      await AdaptyRepositoryImpl.instance.logUserState();

      // Логирование информации о пользователе
      print('Пользователь: $_userProfile');
      print('Статус подписки UI: $_subscriptionStatus');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Состояние пользователя логировано в консоль'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('[ProfilePage] Ошибка логирования состояния пользователя: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка логирования состояния пользователя: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Кнопка AI&Privacy
  Widget _buildAIPrivacyButton() {
    return SizedBox(
      width: double.infinity,
      child: Zbutton(
        action: _showAIPrivacyModal,
        isLoading: false,
        isActive: true,
        text: 'AI&Privacy',
        textColor: Colors.white,
        color: const Color(0xFF6B73FF), // Красивый синий цвет
      ),
    );
  }

  /// Показать модальное окно с информацией о AI и Privacy
  Future<void> _showAIPrivacyModal() async {
    print('[ProfilePage] Показ модального окна AI&Privacy');

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            children: [
              // Заголовок модального окна
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.w),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'AI & Privacy',
                        style: context.styles.h3.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // Кнопка закрытия
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 32.w,
                        height: 32.h,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Icon(
                          Icons.close,
                          size: 20.r,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Содержимое модального окна
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Китайский текст
                      _buildLanguageSection(
                        language: '中文',
                        title: 'AI 查询数据',
                        content:
                            '当您在应用内输入文字进行问卦或追问时，我们会将该文字及随机生成的会话 ID 通过 TLS 加密传输至 DeepSeek、Qwen 语言模型，仅用于即时生成回答。\n\n该数据在模型返回结果后即被丢弃，我们不会存储、共享或用于任何其他目的。',
                      ),

                      SizedBox(height: 30.h),

                      // Английский текст
                      _buildLanguageSection(
                        language: 'English',
                        title: 'AI Query Data',
                        content:
                            'When you type a question or follow-up in the app, the text and a random session ID are transmitted over TLS to the DeepSeek and Qwen language models solely to generate a response.\n\nThe payload is discarded immediately after the reply is returned. We do not store, share, or use this data for any other purpose.',
                      ),

                      SizedBox(height: 40.h),

                      // Кнопка с ссылкой на политику конфиденциальности
                      _buildPrivacyPolicyButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Секция с текстом на определенном языке
  Widget _buildLanguageSection({
    required String language,
    required String title,
    required String content,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Язык
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: const Color(0xFF6B73FF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              language,
              style: context.styles.sDemilight.copyWith(
                color: const Color(0xFF6B73FF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          SizedBox(height: 12.h),

          // Заголовок
          Text(
            title,
            style: context.styles.mMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),

          SizedBox(height: 8.h),

          // Содержимое
          Text(
            content,
            style: context.styles.sDemilight.copyWith(
              color: Colors.black54,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Кнопка с ссылкой на политику конфиденциальности
  Widget _buildPrivacyPolicyButton() {
    return SizedBox(
      width: double.infinity,
      child: Zbutton(
        action: _openPrivacyPolicy,
        isLoading: false,
        isActive: true,
        text: 'Privacy Policy',
        textColor: Colors.white,
        color: const Color(0xFF34A853), // Зеленый цвет для политики
      ),
    );
  }

  /// Открыть политику конфиденциальности в браузере
  Future<void> _openPrivacyPolicy() async {
    print('[ProfilePage] Открытие политики конфиденциальности');

    const url = 'https://zhiming.app/privacy-policy.html';

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        print('[ProfilePage] Политика конфиденциальности открыта');
      } else {
        print('[ProfilePage] Не удалось открыть политику конфиденциальности');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Не удалось открыть политику конфиденциальности'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print(
        '[ProfilePage] Ошибка при открытии политики конфиденциальности: $e',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ошибка при открытии политики конфиденциальности: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
