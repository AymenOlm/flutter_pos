import 'package:equatable/equatable.dart';

import 'package:flutter_pos/core/errors/failures.dart';
import 'package:flutter_pos/features/auth/domain/entities/app_user.dart';

enum AuthStatus { loading, authenticated, unauthenticated, failure }

class AuthState extends Equatable {
  const AuthState({required this.status, this.user, this.failure});

  factory AuthState.initial() {
    return const AuthState(status: AuthStatus.loading);
  }

  final AuthStatus status;
  final AppUser? user;
  final Failure? failure;

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    Failure? failure,
    bool clearFailure = false,
    bool clearUser = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [status, user, failure];
}
