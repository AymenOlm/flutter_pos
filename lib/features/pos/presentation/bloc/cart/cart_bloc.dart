import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_pos/features/pos/domain/entities/cart_entity.dart';
import 'package:flutter_pos/features/pos/domain/usecases/calculate_total.dart';
import 'package:flutter_pos/features/pos/presentation/bloc/cart/cart_event.dart';
import 'package:flutter_pos/features/pos/presentation/bloc/cart/cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc({required CalculateTotal calculateTotal})
    : _calculateTotal = calculateTotal,
      super(CartState.initial()) {
    on<AddItem>(_onAddItem);
    on<RemoveItem>(_onRemoveItem);
    on<ClearCart>(_onClearCart);
  }

  final CalculateTotal _calculateTotal;

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

  void _emitUpdatedState(Emitter<CartState> emit, CartEntity cart) {
    emit(state.copyWith(cart: cart, totals: _calculateTotal(cart)));
  }
}
