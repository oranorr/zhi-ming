import 'package:flutter/material.dart';
import 'package:zhi_ming/features/adapty/adapty.dart';
import 'package:zhi_ming/features/adapty/presentation/widgets/subscription_status_widget.dart';

/// Страница для тестирования функциональности Adapty
/// Позволяет проверить работу подписок и управления пользователями
class AdaptyTestPage extends StatefulWidget {
  const AdaptyTestPage({super.key});

  @override
  State<AdaptyTestPage> createState() => _AdaptyTestPageState();
}

class _AdaptyTestPageState extends State<AdaptyTestPage> {
  List<SubscriptionProduct> _products = [];
  bool _isLoadingProducts = false;
  String? _productsError;

  String? _userId;
  bool _isLoadingUserId = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadUserId();
  }

  /// Загрузка доступных продуктов
  Future<void> _loadProducts() async {
    try {
      setState(() {
        _isLoadingProducts = true;
        _productsError = null;
      });

      if (!AdaptyService.instance.isInitialized) {
        throw StateError('AdaptyService не инициализирован');
      }

      final products =
          await AdaptyService.instance.repository.getAvailableProducts();

      if (mounted) {
        setState(() {
          _products = products;
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _productsError = e.toString();
          _isLoadingProducts = false;
        });
      }
    }
  }

  /// Загрузка ID пользователя
  Future<void> _loadUserId() async {
    try {
      setState(() {
        _isLoadingUserId = true;
      });

      if (!AdaptyService.instance.isInitialized) {
        return;
      }

      final userId = await AdaptyService.instance.repository.getUserId();

      if (mounted) {
        setState(() {
          _userId = userId;
          _isLoadingUserId = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingUserId = false;
        });
      }
    }
  }

  /// Тестирование уменьшения бесплатных запросов
  Future<void> _testDecrementFreeRequests() async {
    try {
      if (!AdaptyService.instance.isInitialized) {
        throw StateError('AdaptyService не инициализирован');
      }

      await AdaptyService.instance.repository.decrementFreeRequests();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Бесплатный запрос использован'),
            backgroundColor: Colors.green,
          ),
        );
        // Обновляем статус подписки
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Тестирование восстановления покупок
  Future<void> _testRestorePurchases() async {
    try {
      if (!AdaptyService.instance.isInitialized) {
        throw StateError('AdaptyService не инициализирован');
      }

      final restored =
          await AdaptyService.instance.repository.restorePurchases();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              restored
                  ? 'Покупки успешно восстановлены'
                  : 'Активные покупки не найдены',
            ),
            backgroundColor: restored ? Colors.green : Colors.orange,
          ),
        );
        // Обновляем статус подписки
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка восстановления: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Тестирование Adapty'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Статус подписки
            const Text(
              'Статус подписки',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const SubscriptionStatusWidget(),

            const SizedBox(height: 24),

            // Информация о пользователе
            const Text(
              'Информация о пользователе',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.person),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ID пользователя:',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          if (_isLoadingUserId)
                            const Text('Загрузка...')
                          else if (_userId != null)
                            Text(
                              _userId!,
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            )
                          else
                            const Text(
                              'Не удалось получить',
                              style: TextStyle(color: Colors.grey),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _loadUserId,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Доступные продукты
            const Text(
              'Доступные продукты',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.shopping_cart),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Продукты подписки',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          onPressed: _loadProducts,
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_isLoadingProducts)
                      const Center(child: CircularProgressIndicator())
                    else if (_productsError != null)
                      Column(
                        children: [
                          Text(
                            'Ошибка: $_productsError',
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _loadProducts,
                            child: const Text('Повторить'),
                          ),
                        ],
                      )
                    else if (_products.isEmpty)
                      const Text('Продукты не найдены')
                    else
                      Column(
                        children:
                            _products.map((product) {
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  leading: Icon(
                                    product.subscriptionPeriod == 'monthly'
                                        ? Icons.calendar_month
                                        : product.subscriptionPeriod == 'yearly'
                                        ? Icons.calendar_today
                                        : Icons.star,
                                    color: Colors.amber,
                                  ),
                                  title: Text(product.productId),
                                  subtitle: Text(
                                    '${product.price} (${product.subscriptionPeriod})',
                                  ),
                                  trailing:
                                      product.discountPercentage != null
                                          ? Chip(
                                            label: Text(
                                              '-${product.discountPercentage}%',
                                            ),
                                            backgroundColor: Colors.green,
                                            labelStyle: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          )
                                          : null,
                                  onTap: () {
                                    // TODO: Реализовать покупку
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Покупка ${product.productId} будет реализована позже',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            }).toList(),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Действия для тестирования
            const Text(
              'Действия для тестирования',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _testDecrementFreeRequests,
                        icon: const Icon(Icons.remove_circle),
                        label: const Text('Использовать бесплатный запрос'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _testRestorePurchases,
                        icon: const Icon(Icons.restore),
                        label: const Text('Восстановить покупки'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
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
}
