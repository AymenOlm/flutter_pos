import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_pos/features/pos/domain/entities/cart_entity.dart';
import 'package:flutter_pos/features/pos/domain/entities/product.dart';
import 'package:flutter_pos/features/pos/domain/usecases/calculate_total.dart';
import 'package:flutter_pos/features/pos/presentation/bloc/cart/cart_bloc.dart';
import 'package:flutter_pos/features/pos/presentation/bloc/cart/cart_event.dart';
import 'package:flutter_pos/features/pos/presentation/bloc/cart/cart_state.dart';
import 'package:flutter_pos/features/pos/presentation/bloc/product_catalog/product_catalog_bloc.dart';
import 'package:flutter_pos/features/pos/presentation/bloc/product_catalog/product_catalog_event.dart';
import 'package:flutter_pos/features/pos/presentation/bloc/product_catalog/product_catalog_state.dart';
import 'package:flutter_pos/features/pos/presentation/views/checkout_success_view.dart';

class POSView extends StatelessWidget {
  const POSView({super.key, this.onLogoutRequested});

  final VoidCallback? onLogoutRequested;

  @override
  Widget build(BuildContext context) {
    return BlocListener<CartBloc, CartState>(
      listenWhen: (previous, current) =>
          previous.checkoutStatus != current.checkoutStatus,
      listener: (context, state) async {
        if (state.checkoutStatus == CheckoutStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          context.read<CartBloc>().add(const CheckoutStatusReset());
          return;
        }

        if (state.checkoutStatus == CheckoutStatus.success &&
            state.lastTransaction != null) {
          final transaction = state.lastTransaction!;
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CheckoutSuccessView(record: transaction),
            ),
          );

          if (!context.mounted) {
            return;
          }

          context.read<CartBloc>().add(const CheckoutStatusReset());
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('POS Console'),
          actions: [
            if (onLogoutRequested != null)
              IconButton(
                onPressed: onLogoutRequested,
                icon: const Icon(Icons.logout),
                tooltip: 'Logout',
              ),
          ],
        ),
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
        _DiscountControls(state: state),
        const SizedBox(height: 12),
        _amountRow('Subtotal', state.totals.subtotal),
        if (state.totals.discountAmount > 0)
          _amountRow(
            'Discount (${state.discount.type.displayName})',
            state.totals.discountAmount,
            isNegative: true,
          ),
        _amountRow('Tax (10%)', state.totals.tax),
        const Divider(),
        _amountRow('Total', state.totals.total, isEmphasis: true),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.tonal(
                onPressed:
                    state.cart.items.isEmpty ||
                        state.checkoutStatus == CheckoutStatus.submitting
                    ? null
                    : () => _checkout(context, 'Cash'),
                child: const Text('Pay Cash'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed:
                    state.cart.items.isEmpty ||
                        state.checkoutStatus == CheckoutStatus.submitting
                    ? null
                    : () => _checkout(context, 'Card'),
                child: const Text('Pay Card'),
              ),
            ),
          ],
        ),
        if (state.checkoutStatus == CheckoutStatus.submitting) ...[
          const SizedBox(height: 8),
          const LinearProgressIndicator(),
        ],
      ],
    );
  }

  Widget _amountRow(
    String label,
    double amount, {
    bool isEmphasis = false,
    bool isNegative = false,
  }) {
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
              Text(
                '${isNegative ? '-' : ''}\$${amount.toStringAsFixed(2)}',
                style: style,
              ),
            ],
          ),
        );
      },
    );
  }

  void _checkout(BuildContext context, String method) {
    context.read<CartBloc>().add(CheckoutSubmitted(paymentMethod: method));
  }
}

class _DiscountControls extends StatefulWidget {
  const _DiscountControls({required this.state});

  final CartState state;

  @override
  State<_DiscountControls> createState() => _DiscountControlsState();
}

class _DiscountControlsState extends State<_DiscountControls> {
  late final TextEditingController _amountController;
  late DiscountType _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.state.discount.type;
    _amountController = TextEditingController(
      text: widget.state.discount.value > 0
          ? widget.state.discount.value.toStringAsFixed(2)
          : '',
    );
  }

  @override
  void didUpdateWidget(covariant _DiscountControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.discount != widget.state.discount) {
      _selectedType = widget.state.discount.type;
      _amountController.text = widget.state.discount.value > 0
          ? widget.state.discount.value.toStringAsFixed(2)
          : '';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _dispatchDiscount() {
    final parsedValue = double.tryParse(_amountController.text.trim()) ?? 0;
    context.read<CartBloc>().add(
      DiscountChanged(
        discount: CartDiscount(type: _selectedType, value: parsedValue),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPercentage = _selectedType == DiscountType.percentage;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Discount', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                DropdownButton<DiscountType>(
                  value: _selectedType,
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _selectedType = value;
                    });
                    _dispatchDiscount();
                  },
                  items: const [
                    DropdownMenuItem(
                      value: DiscountType.fixed,
                      child: Text('Fixed'),
                    ),
                    DropdownMenuItem(
                      value: DiscountType.percentage,
                      child: Text('Percentage'),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: isPercentage
                          ? 'Discount percentage'
                          : 'Discount amount',
                      prefixText: isPercentage ? null : '\$',
                      suffixText: isPercentage ? '%' : null,
                    ),
                    onChanged: (_) => _dispatchDiscount(),
                  ),
                ),
              ],
            ),
            if (widget.state.totals.discountAmount > 0) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedType = DiscountType.fixed;
                      _amountController.clear();
                    });
                    context.read<CartBloc>().add(
                      const DiscountChanged(discount: CartDiscount.none()),
                    );
                  },
                  child: const Text('Clear discount'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
