import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_pos/core/logging/app_logger.dart';
import 'package:flutter_pos/core/logging/correlation_id.dart';
import 'package:flutter_pos/features/pos/domain/entities/cart_entity.dart';
import 'package:flutter_pos/features/pos/domain/usecases/calculate_total.dart';
import 'package:flutter_pos/features/pos/domain/usecases/save_transaction.dart';
import 'package:flutter_pos/features/pos/presentation/bloc/cart/cart_event.dart';
import 'package:flutter_pos/features/pos/presentation/bloc/cart/cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc({
    required CalculateTotal calculateTotal,
    required SaveTransaction saveTransaction,
    required AppLogger logger,
  }) : _calculateTotal = calculateTotal,
       _saveTransaction = saveTransaction,
       _logger = logger,
       super(CartState.initial()) {
    on<AddItem>(_onAddItem);
    on<RemoveItem>(_onRemoveItem);
    on<ClearCart>(_onClearCart);
    on<DiscountChanged>(_onDiscountChanged);
    on<CheckoutSubmitted>(_onCheckoutSubmitted);
    on<CheckoutStatusReset>(_onCheckoutStatusReset);
  }

  final CalculateTotal _calculateTotal;
  final SaveTransaction _saveTransaction;
  final AppLogger _logger;

  void _onAddItem(AddItem event, Emitter<CartState> emit) {
    final updatedCart = state.cart.addItem(event.product);
    _emitUpdatedState(emit, updatedCart);
  }

  void _onRemoveItem(RemoveItem event, Emitter<CartState> emit) {
    final updatedCart = state.cart.removeItem(event.product);
    _emitUpdatedState(emit, updatedCart);
  }

  void _onClearCart(ClearCart event, Emitter<CartState> emit) {
    emit(
      state.copyWith(
        cart: const CartEntity(),
        totals: _calculateTotal(const CartEntity()),
        discount: const CartDiscount.none(),
        checkoutStatus: CheckoutStatus.idle,
        clearErrorMessage: true,
      ),
    );
  }

  Future<void> _onCheckoutSubmitted(
    CheckoutSubmitted event,
    Emitter<CartState> emit,
  ) async {
    if (state.cart.items.isEmpty) {
      _logger.warning(
        feature: 'checkout',
        action: 'submit',
        outcome: 'blocked_empty_cart',
        errorCode: 'CHECKOUT_EMPTY_CART',
      );
      return;
    }

    final correlationId = CorrelationId.create(prefix: 'checkout');

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
          discount: state.discount,
          paymentMethod: event.paymentMethod,
        ),
      );

      _logger.info(
        feature: 'checkout',
        action: 'save_transaction',
        outcome: 'success',
        correlationId: correlationId,
        context: <String, Object?>{
          'paymentMethod': event.paymentMethod,
          'itemCount': state.cart.items.length,
          'total': state.totals.total,
        },
      );

      const emptyCart = CartEntity();
      emit(
        state.copyWith(
          cart: emptyCart,
          totals: _calculateTotal(emptyCart),
          discount: const CartDiscount.none(),
          checkoutStatus: CheckoutStatus.success,
          lastTransaction: record,
          clearErrorMessage: true,
        ),
      );
    } catch (error, stackTrace) {
      _logger.error(
        feature: 'checkout',
        action: 'save_transaction',
        outcome: 'failed',
        correlationId: correlationId,
        errorCode: 'CHECKOUT_SAVE_FAILED',
        context: <String, Object?>{
          'paymentMethod': event.paymentMethod,
          'itemCount': state.cart.items.length,
          'total': state.totals.total,
        },
        error: error,
        stackTrace: stackTrace,
      );
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

  void _onDiscountChanged(DiscountChanged event, Emitter<CartState> emit) {
    emit(
      state.copyWith(
        discount: event.discount,
        totals: _calculateTotal(state.cart, discount: event.discount),
        checkoutStatus: CheckoutStatus.idle,
        clearErrorMessage: true,
      ),
    );
  }

  void _emitUpdatedState(Emitter<CartState> emit, CartEntity cart) {
    emit(
      state.copyWith(
        cart: cart,
        totals: _calculateTotal(cart, discount: state.discount),
        checkoutStatus: CheckoutStatus.idle,
        clearErrorMessage: true,
      ),
    );
  }
}
