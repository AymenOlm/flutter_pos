import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_pos/features/pos/domain/entities/cart_entity.dart';
import 'package:flutter_pos/features/pos/domain/entities/product.dart';
import 'package:flutter_pos/features/pos/presentation/bloc/cart/cart_bloc.dart';
import 'package:flutter_pos/features/pos/presentation/bloc/cart/cart_event.dart';
import 'package:flutter_pos/features/pos/presentation/bloc/cart/cart_state.dart';
import 'package:flutter_pos/features/pos/presentation/bloc/product_catalog/product_catalog_bloc.dart';
import 'package:flutter_pos/features/pos/presentation/bloc/product_catalog/product_catalog_event.dart';
import 'package:flutter_pos/features/pos/presentation/bloc/product_catalog/product_catalog_state.dart';

class POSView extends StatelessWidget {
  const POSView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('POS Console')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;

          if (isDesktop) {
            return Row(
              children: const [
                Expanded(flex: 2, child: _ProductPanel()),
                VerticalDivider(width: 1),
                Expanded(child: _CartPanel()),
              ],
            );
          }

          return const Column(
            children: [
              Expanded(flex: 3, child: _ProductPanel()),
              Divider(height: 1),
              Expanded(flex: 2, child: _CartPanel()),
            ],
          );
        },
      ),
    );
  }
}

class _ProductPanel extends StatelessWidget {
  const _ProductPanel();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: const InputDecoration(
              labelText: 'Search products',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              context.read<ProductCatalogBloc>().add(SearchProducts(value));
            },
          ),
          const SizedBox(height: 12),
          Expanded(
            child: BlocBuilder<ProductCatalogBloc, ProductCatalogState>(
              builder: (context, state) {
                if (state.status == ProductCatalogStatus.loading ||
                    state.status == ProductCatalogStatus.initial) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.status == ProductCatalogStatus.error) {
                  return Center(
                    child: Text(state.message ?? 'Something went wrong.'),
                  );
                }

                if (state.filteredProducts.isEmpty) {
                  return const Center(child: Text('No products found.'));
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final cardWidth = constraints.maxWidth > 700 ? 220 : 160;
                    final columns = (constraints.maxWidth / cardWidth)
                        .floor()
                        .clamp(2, 5);

                    return GridView.builder(
                      itemCount: state.filteredProducts.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.25,
                      ),
                      itemBuilder: (context, index) {
                        final product = state.filteredProducts[index];
                        return _ProductCard(product: product);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          context.read<CartBloc>().add(AddItem(product));
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('\$${product.price.toStringAsFixed(2)}'),
                  const Icon(Icons.add_shopping_cart),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartPanel extends StatelessWidget {
  const _CartPanel();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cartItems = state.cart.items.isEmpty
                  ? const Center(child: Text('Cart is empty'))
                  : _CartItemsList(items: state.cart.items);

              if (constraints.maxHeight < 320) {
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CartHeader(state: state),
                      const SizedBox(height: 8),
                      SizedBox(height: 120, child: cartItems),
                      const SizedBox(height: 8),
                      _TotalsSection(state: state),
                    ],
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CartHeader(state: state),
                  const SizedBox(height: 8),
                  Expanded(child: cartItems),
                  const SizedBox(height: 8),
                  _TotalsSection(state: state),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _CartHeader extends StatelessWidget {
  const _CartHeader({required this.state});

  final CartState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Cart', style: Theme.of(context).textTheme.headlineSmall),
        TextButton(
          onPressed: state.cart.items.isEmpty
              ? null
              : () => context.read<CartBloc>().add(const ClearCart()),
          child: const Text('Clear'),
        ),
      ],
    );
  }
}

class _CartItemsList extends StatelessWidget {
  const _CartItemsList({required this.items});

  final List<CartItemEntity> items;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items[index];

        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(item.product.name),
          subtitle: Text('Qty: ${item.quantity}'),
          trailing: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            children: [
              Text('\$${item.lineTotal.toStringAsFixed(2)}'),
              IconButton(
                onPressed: () {
                  context.read<CartBloc>().add(RemoveItem(item.product));
                },
                icon: const Icon(Icons.remove_circle_outline),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TotalsSection extends StatelessWidget {
  const _TotalsSection({required this.state});

  final CartState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _amountRow('Subtotal', state.totals.subtotal),
        _amountRow('Tax (10%)', state.totals.tax),
        const Divider(),
        _amountRow('Total', state.totals.total, isEmphasis: true),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.tonal(
                onPressed: state.cart.items.isEmpty
                    ? null
                    : () => _checkout(context, 'Cash', state),
                child: const Text('Pay Cash'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: state.cart.items.isEmpty
                    ? null
                    : () => _checkout(context, 'Card', state),
                child: const Text('Pay Card'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _amountRow(String label, double amount, {bool isEmphasis = false}) {
    return Builder(
      builder: (context) {
        final style = isEmphasis
            ? Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)
            : Theme.of(context).textTheme.bodyMedium;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: style),
              Text('\$${amount.toStringAsFixed(2)}', style: style),
            ],
          ),
        );
      },
    );
  }

  void _checkout(BuildContext context, String method, CartState state) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$method checkout successful. Total: \$${state.totals.total.toStringAsFixed(2)}',
        ),
      ),
    );

    context.read<CartBloc>().add(const ClearCart());
  }
}
