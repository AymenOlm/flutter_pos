import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_pos/features/pos/domain/entities/cart_entity.dart';
import 'package:flutter_pos/features/pos/domain/usecases/calculate_total.dart';
import 'package:flutter_pos/features/pos/domain/usecases/save_transaction.dart';
import 'package:flutter_pos/features/pos/presentation/bloc/cart/cart_event.dart';
import 'package:flutter_pos/features/pos/presentation/bloc/cart/cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc({
    required CalculateTotal calculateTotal,
    required SaveTransaction saveTransaction,
  }) : _calculateTotal = calculateTotal,
       _saveTransaction = saveTransaction,
       super(CartState.initial()) {
    on<AddItem>(_onAddItem);
    on<RemoveItem>(_onRemoveItem);
    on<ClearCart>(_onClearCart);
    on<CheckoutSubmitted>(_onCheckoutSubmitted);
    on<CheckoutStatusReset>(_onCheckoutStatusReset);
  }

  final CalculateTotal _calculateTotal;
  final SaveTransaction _saveTransaction;

  void _onAddItem(AddItem event, Emitter<CartState> emit) {
    final updatedCart = state.cart.addItem(event.product);
    _emitUpdatedState(emit, updatedCart);
  }

  void _onRemoveItem(RemoveItem event, Emitter<CartState> emit) {
    final updatedCart = state.cart.removeItem(event.product);
    _emitUpdatedState(emit, updatedCart);
  }

  void _onClearCart(ClearCart event, Emitter<CartState> emit) {
    _emitUpdatedState(emit, state.cart.clear());
  }

  Future<void> _onCheckoutSubmitted(
    CheckoutSubmitted event,
    Emitter<CartState> emit,
  ) async {
    if (state.cart.items.isEmpty) {
      return;
    }

    emit(
      state.copyWith(
        checkoutStatus: CheckoutStatus.submitting,
        clearErrorMessage: true,
      ),
    );

    try {
      final record = await _saveTransaction(
        SaveTransactionParams(
          cart: state.cart,
          totals: state.totals,
          paymentMethod: event.paymentMethod,
        ),
      );

      const emptyCart = CartEntity();
      emit(
        state.copyWith(
          cart: emptyCart,
          totals: _calculateTotal(emptyCart),
          checkoutStatus: CheckoutStatus.success,
          lastTransaction: record,
          clearErrorMessage: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          checkoutStatus: CheckoutStatus.failure,
          errorMessage:
              'Checkout failed. Please verify local storage and try again.',
        ),
      );
    }
  }

  void _onCheckoutStatusReset(
    CheckoutStatusReset event,
    Emitter<CartState> emit,
  ) {
    emit(
      state.copyWith(
        checkoutStatus: CheckoutStatus.idle,
        clearErrorMessage: true,
        clearLastTransaction: true,
      ),
    );
  }

  void _emitUpdatedState(Emitter<CartState> emit, CartEntity cart) {
    emit(
      state.copyWith(
        cart: cart,
        totals: _calculateTotal(cart),
        checkoutStatus: CheckoutStatus.idle,
        clearErrorMessage: true,
      ),
    );
  }
}
