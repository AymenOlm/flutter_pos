import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_pos/features/auth/presentation/bloc/auth_event.dart';
import 'package:flutter_pos/features/pos/domain/entities/product.dart';
import 'package:flutter_pos/features/pos/domain/entities/transaction_record.dart';
import 'package:flutter_pos/features/pos/domain/repositories/product_repository.dart';
import 'package:flutter_pos/features/pos/domain/repositories/sales_repository.dart';
import 'package:flutter_pos/features/pos/domain/usecases/calculate_total.dart';
import 'package:flutter_pos/features/pos/presentation/di/service_locator.dart';

class AdminHomeView extends StatefulWidget {
  const AdminHomeView({super.key});

  @override
  State<AdminHomeView> createState() => _AdminHomeViewState();
}

class _AdminHomeViewState extends State<AdminHomeView> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Console'),
        actions: [
          IconButton(
            onPressed: () {
              context.read<AuthBloc>().add(const LogoutRequested());
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: IndexedStack(
        index: _tabIndex,
        children: const [
          _AdminOverviewTab(),
          _ProductManagementTab(),
          _SalesTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (index) {
          setState(() => _tabIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Products',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Sales',
          ),
        ],
      ),
    );
  }
}

class _AdminOverviewTab extends StatelessWidget {
  const _AdminOverviewTab();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TransactionRecord>>(
      future: sl<SalesRepository>().getTransactions(),
      builder: (context, snapshot) {
        final transactions = snapshot.data ?? const <TransactionRecord>[];
        final totalRevenue = transactions.fold<double>(
          0,
          (sum, item) => sum + item.total,
        );

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Today Summary',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _metricCard('Transactions', '${transactions.length}'),
                  _metricCard(
                    'Revenue',
                    '\$${totalRevenue.toStringAsFixed(2)}',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _metricCard(String label, String value) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductManagementTab extends StatefulWidget {
  const _ProductManagementTab();

  @override
  State<_ProductManagementTab> createState() => _ProductManagementTabState();
}

class _ProductManagementTabState extends State<_ProductManagementTab> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  bool _loading = false;
  late Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = sl<ProductRepository>().getProducts();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Product>>(
      future: _productsFuture,
      builder: (context, snapshot) {
        final products = snapshot.data ?? const <Product>[];

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Product name',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 120,
                    child: TextField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Price'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _loading ? null : () => _addProduct(context),
                    child: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: products.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return ListTile(
                      title: Text(product.name),
                      subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
                      trailing: IconButton(
                        onPressed: () async {
                          await sl<ProductRepository>().deleteProduct(
                            product.id,
                          );
                          if (context.mounted) {
                            setState(() {
                              _productsFuture = sl<ProductRepository>()
                                  .getProducts();
                            });
                          }
                        },
                        icon: const Icon(Icons.delete_outline),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addProduct(BuildContext context) async {
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text.trim());

    if (name.isEmpty || price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid product data.')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await sl<ProductRepository>().upsertProduct(
        Product(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          name: name,
          price: price,
        ),
      );

      if (!context.mounted) {
        return;
      }

      _nameController.clear();
      _priceController.clear();
      setState(() {
        _productsFuture = sl<ProductRepository>().getProducts();
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Product added.')));
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add product: $error')),
        );
      }
    } finally {
      if (context.mounted) {
        setState(() => _loading = false);
      }
    }
  }
}

class _SalesTab extends StatelessWidget {
  const _SalesTab();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TransactionRecord>>(
      future: sl<SalesRepository>().getTransactions(),
      builder: (context, snapshot) {
        final sales = snapshot.data ?? const <TransactionRecord>[];

        if (sales.isEmpty) {
          return const Center(child: Text('No sales yet.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: sales.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final sale = sales[index];
            return ListTile(
              title: Text('Transaction #${sale.id}'),
              subtitle: Text(
                '${sale.paymentMethod} • ${sale.createdAt.toLocal()}\nItems: ${sale.cart.items.length} • Discount: ${sale.discountAmount > 0 ? sale.discountType.displayName : 'none'}',
              ),
              trailing: Text('\$${sale.total.toStringAsFixed(2)}'),
            );
          },
        );
      },
    );
  }
}
