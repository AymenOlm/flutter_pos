import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_pos/core/logging/app_logger.dart';
import 'package:flutter_pos/features/pos/data/datasources/cart_local_data_source.dart';
import 'package:flutter_pos/features/pos/domain/entities/cart_entity.dart';
import 'package:flutter_pos/features/pos/domain/entities/product.dart';
import 'package:flutter_pos/features/pos/domain/entities/transaction_record.dart';
import 'package:flutter_pos/features/pos/domain/repositories/sales_repository.dart';
import 'package:flutter_pos/features/pos/domain/usecases/calculate_total.dart';
import 'package:flutter_pos/features/pos/domain/usecases/save_transaction.dart';
import 'package:flutter_pos/features/pos/presentation/bloc/cart/cart_bloc.dart';
import 'package:flutter_pos/features/pos/presentation/bloc/cart/cart_event.dart';
import 'package:flutter_pos/features/pos/presentation/bloc/cart/cart_state.dart';

class _FakeSaveTransaction extends SaveTransaction {
  _FakeSaveTransaction() : super(_FakeSalesRepository());
}

class _FakeSalesRepository implements SalesRepository {
  @override
  Future<void> saveTransaction(TransactionRecord record) async {}

  @override
  Future<List<TransactionRecord>> getTransactions() async =>
      <TransactionRecord>[];
}

class _FakeCartLocalDataSource implements CartLocalDataSource {
  PersistedCartState? loadedState;
  CartEntity? savedCart;
  CartDiscount? savedDiscount;
  int clearCalls = 0;

  @override
  Future<void> clearCartState() async {
    clearCalls += 1;
  }

  @override
  Future<PersistedCartState?> loadCartState() async {
    return loadedState;
  }

  @override
  Future<void> saveCartState({
    required CartEntity cart,
    required CartDiscount discount,
  }) async {
    savedCart = cart;
    savedDiscount = discount;
  }
}

void main() {
  group('CartBloc persistence', () {
    test('restores cart and discount on init', () async {
      final localDataSource = _FakeCartLocalDataSource()
        ..loadedState = PersistedCartState(
          cart: CartEntity(
            items: const [
              CartItemEntity(
                product: Product(
                  id: 'p-1',
                  name: 'Coffee',
                  price: 3.50,
                  category: 'Beverages',
                ),
                quantity: 2,
              ),
            ],
          ),
          discount: const CartDiscount(type: DiscountType.fixed, value: 1),
        );

      final bloc = CartBloc(
        calculateTotal: const CalculateTotal(),
        saveTransaction: _FakeSaveTransaction(),
        logger: AppLogger(sinks: const []),
        cartLocalDataSource: localDataSource,
      );

      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(bloc.state.cart.items.length, 1);
      expect(bloc.state.cart.items.first.quantity, 2);
      expect(bloc.state.discount.value, 1);
      await bloc.close();
    });

    test('persists cart when item is added', () async {
      final localDataSource = _FakeCartLocalDataSource();
      final bloc = CartBloc(
        calculateTotal: const CalculateTotal(),
        saveTransaction: _FakeSaveTransaction(),
        logger: AppLogger(sinks: const []),
        cartLocalDataSource: localDataSource,
      );

      bloc.add(
        const AddItem(
          Product(
            id: 'p-1',
            name: 'Coffee',
            price: 3.50,
            category: 'Beverages',
          ),
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(localDataSource.savedCart?.items.length, 1);
      expect(localDataSource.savedDiscount, const CartDiscount.none());
      await bloc.close();
    });

    test('clears persisted cart on clear action', () async {
      final localDataSource = _FakeCartLocalDataSource();
      final bloc = CartBloc(
        calculateTotal: const CalculateTotal(),
        saveTransaction: _FakeSaveTransaction(),
        logger: AppLogger(sinks: const []),
        cartLocalDataSource: localDataSource,
      );

      bloc.add(const ClearCart());
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(localDataSource.clearCalls, 1);
      await bloc.close();
    });

    test(
      'returns clear failure message for unsupported payment method',
      () async {
        final localDataSource = _FakeCartLocalDataSource();
        final bloc = CartBloc(
          calculateTotal: const CalculateTotal(),
          saveTransaction: _FakeSaveTransaction(),
          logger: AppLogger(sinks: const []),
          cartLocalDataSource: localDataSource,
        );

        bloc.add(
          const AddItem(
            Product(
              id: 'p-1',
              name: 'Coffee',
              price: 3.50,
              category: 'Beverages',
            ),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));

        bloc.add(const CheckoutSubmitted(paymentMethod: 'Crypto'));
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(bloc.state.checkoutStatus, CheckoutStatus.failure);
        expect(
          bloc.state.errorMessage,
          'Selected payment method is not supported. Use Cash or Card.',
        );
        await bloc.close();
      },
    );
  });
}
