import 'package:equatable/equatable.dart';

import 'package:flutter_pos/features/auth/domain/entities/app_user.dart';

enum AuthStatus { loading, authenticated, unauthenticated, failure }

class AuthState extends Equatable {
  const AuthState({required this.status, this.user, this.errorMessage});

  factory AuthState.initial() {
    return const AuthState(status: AuthStatus.loading);
  }

  final AuthStatus status;
  final AppUser? user;
  final String? errorMessage;

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, user, errorMessage];
}
