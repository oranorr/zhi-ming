import 'package:flutter/material.dart';
import 'package:zhi_ming/features/adapty/adapty.dart';

/// Виджет для отображения статуса подписки пользователя
/// Показывает информацию о премиум-доступе или оставшихся бесплатных запросах
class SubscriptionStatusWidget extends StatefulWidget {
  const SubscriptionStatusWidget({super.key});

  @override
  State<SubscriptionStatusWidget> createState() =>
      _SubscriptionStatusWidgetState();
}

class _SubscriptionStatusWidgetState extends State<SubscriptionStatusWidget> {
  SubscriptionStatus? _subscriptionStatus;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionStatus();
  }

  /// Загрузка статуса подписки
  Future<void> _loadSubscriptionStatus() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      if (!AdaptyService.instance.isInitialized) {
        throw StateError('AdaptyService не инициализирован');
      }

      final status =
          await AdaptyService.instance.repository.getSubscriptionStatus();

      if (mounted) {
        setState(() {
          _subscriptionStatus = status;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Загрузка статуса подписки...'),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                children: [
                  Icon(Icons.error, color: Colors.red),
                  SizedBox(width: 8),
                  Text(
                    'Ошибка загрузки',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadSubscriptionStatus,
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }

    final status = _subscriptionStatus!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  status.hasPremiumAccess ? Icons.star : Icons.star_border,
                  color: status.hasPremiumAccess ? Colors.amber : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  status.hasPremiumAccess
                      ? 'Премиум подписка'
                      : 'Бесплатный доступ',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (status.hasPremiumAccess) ...[
              // Информация о премиум подписке
              _buildInfoRow(
                'Тип подписки:',
                status.subscriptionType ?? 'Неизвестно',
              ),
              if (status.expirationDate != null)
                _buildInfoRow(
                  'Действует до:',
                  _formatDate(status.expirationDate!),
                ),
            ] else ...[
              // Информация о бесплатном доступе
              _buildInfoRow(
                'Оставшиеся запросы:',
                '${status.remainingFreeRequests}/${status.maxFreeRequests}',
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value:
                    status.maxFreeRequests > 0
                        ? status.remainingFreeRequests / status.maxFreeRequests
                        : 0,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  status.remainingFreeRequests > 0 ? Colors.blue : Colors.red,
                ),
              ),
            ],

            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loadSubscriptionStatus,
                    child: const Text('Обновить'),
                  ),
                ),
                if (!status.hasPremiumAccess) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Открыть экран покупки подписки
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Экран покупки подписки будет добавлен позже',
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Премиум'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Создание строки с информацией
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  /// Форматирование даты
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
