import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_pos/core/logging/app_logger.dart';
import 'package:flutter_pos/core/logging/correlation_id.dart';
import 'package:flutter_pos/features/pos/data/datasources/cart_local_data_source.dart';
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
    required CartLocalDataSource cartLocalDataSource,
  }) : _calculateTotal = calculateTotal,
       _saveTransaction = saveTransaction,
       _logger = logger,
       _cartLocalDataSource = cartLocalDataSource,
       super(CartState.initial()) {
    on<RestoreCartRequested>(_onRestoreCartRequested);
    on<AddItem>(_onAddItem);
    on<RemoveItem>(_onRemoveItem);
    on<ClearCart>(_onClearCart);
    on<DiscountChanged>(_onDiscountChanged);
    on<CheckoutSubmitted>(_onCheckoutSubmitted);
    on<CheckoutStatusReset>(_onCheckoutStatusReset);
    add(const RestoreCartRequested());
  }

  final CalculateTotal _calculateTotal;
  final SaveTransaction _saveTransaction;
  final AppLogger _logger;
  final CartLocalDataSource _cartLocalDataSource;

  Future<void> _onRestoreCartRequested(
    RestoreCartRequested event,
    Emitter<CartState> emit,
  ) async {
    try {
      final persistedState = await _cartLocalDataSource.loadCartState();
      if (persistedState == null) {
        return;
      }

      emit(
        state.copyWith(
          cart: persistedState.cart,
          discount: persistedState.discount,
          totals: _calculateTotal(
            persistedState.cart,
            discount: persistedState.discount,
          ),
        ),
      );
    } catch (error, stackTrace) {
      _logger.error(
        feature: 'cart',
        action: 'restore',
        outcome: 'failed',
        errorCode: 'CART_RESTORE_FAILED',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _onAddItem(AddItem event, Emitter<CartState> emit) {
    final updatedCart = state.cart.addItem(event.product);
    _emitUpdatedState(emit, updatedCart);
    _persistCartState(updatedCart, state.discount);
  }

  void _onRemoveItem(RemoveItem event, Emitter<CartState> emit) {
    final updatedCart = state.cart.removeItem(event.product);
    _emitUpdatedState(emit, updatedCart);
    _persistCartState(updatedCart, state.discount);
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
    _clearPersistedCartState();
  }

  Future<void> _onCheckoutSubmitted(
    CheckoutSubmitted event,
    Emitter<CartState> emit,
  ) async {
    final validationError = _checkoutValidationError(event.paymentMethod);
    if (validationError != null) {
      _logger.warning(
        feature: 'checkout',
        action: 'submit',
        outcome: 'blocked_validation_failed',
        errorCode: 'CHECKOUT_VALIDATION_FAILED',
        context: <String, Object?>{
          'paymentMethod': event.paymentMethod,
          'itemCount': state.cart.items.length,
          'total': state.totals.total,
          'reason': validationError,
        },
      );
      emit(
        state.copyWith(
          checkoutStatus: CheckoutStatus.failure,
          errorMessage: validationError,
        ),
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
      _clearPersistedCartState();
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

  String? _checkoutValidationError(String paymentMethod) {
    if (state.cart.items.isEmpty) {
      return 'Add at least one item before checkout.';
    }

    final normalizedMethod = paymentMethod.trim().toLowerCase();
    if (normalizedMethod != 'cash' && normalizedMethod != 'card') {
      return 'Selected payment method is not supported. Use Cash or Card.';
    }

    if (!state.totals.total.isFinite || state.totals.total <= 0) {
      return 'Unable to checkout with the current total. Please review the cart.';
    }

    return null;
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
    _persistCartState(state.cart, event.discount);
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

  Future<void> _persistCartState(CartEntity cart, CartDiscount discount) async {
    try {
      await _cartLocalDataSource.saveCartState(cart: cart, discount: discount);
    } catch (error, stackTrace) {
      _logger.error(
        feature: 'cart',
        action: 'persist',
        outcome: 'failed',
        errorCode: 'CART_PERSIST_FAILED',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _clearPersistedCartState() async {
    try {
      await _cartLocalDataSource.clearCartState();
    } catch (error, stackTrace) {
      _logger.error(
        feature: 'cart',
        action: 'clear_persisted',
        outcome: 'failed',
        errorCode: 'CART_CLEAR_PERSISTED_FAILED',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
