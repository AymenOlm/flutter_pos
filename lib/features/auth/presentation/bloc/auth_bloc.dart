import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_pos/features/auth/domain/usecases/get_current_user.dart';
import 'package:flutter_pos/features/auth/domain/usecases/login.dart';
import 'package:flutter_pos/features/auth/domain/usecases/logout.dart';
import 'package:flutter_pos/features/auth/presentation/bloc/auth_event.dart';
import 'package:flutter_pos/features/auth/presentation/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required GetCurrentUser getCurrentUser,
    required Login login,
    required Logout logout,
  }) : _getCurrentUser = getCurrentUser,
       _login = login,
       _logout = logout,
       super(AuthState.initial()) {
    on<AuthStarted>(_onStarted);
    on<LoginSubmitted>(_onLoginSubmitted);
    on<LogoutRequested>(_onLogoutRequested);
  }

  final GetCurrentUser _getCurrentUser;
  final Login _login;
  final Logout _logout;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));

    final user = await _getCurrentUser();
    if (user == null) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          user: null,
          clearError: true,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        clearError: true,
      ),
    );
  }

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));

    try {
      final user = await _login(
        username: event.username,
        password: event.password,
      );
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          clearError: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          user: null,
          errorMessage: 'Invalid username or password.',
        ),
      );
      emit(state.copyWith(status: AuthStatus.unauthenticated));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _logout();
    emit(
      state.copyWith(
        status: AuthStatus.unauthenticated,
        user: null,
        clearError: true,
      ),
    );
  }
}
