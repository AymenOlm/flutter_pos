import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_pos/core/errors/failures.dart';
import 'package:flutter_pos/features/auth/domain/entities/app_user.dart';
import 'package:flutter_pos/features/auth/domain/errors/auth_failures.dart';
import 'package:flutter_pos/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_pos/features/auth/domain/usecases/get_current_user.dart';
import 'package:flutter_pos/features/auth/domain/usecases/login.dart';
import 'package:flutter_pos/features/auth/domain/usecases/logout.dart';
import 'package:flutter_pos/features/auth/domain/usecases/validate_credentials.dart';
import 'package:flutter_pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_pos/features/auth/presentation/bloc/auth_event.dart';
import 'package:flutter_pos/features/auth/presentation/bloc/auth_state.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.currentUser});

  AppUser? currentUser;
  AppUser? loginResult;
  Failure? loginFailure;
  int getCurrentUserCalls = 0;
  int loginCalls = 0;
  int logoutCalls = 0;

  @override
  Future<Either<Failure, AppUser?>> getCurrentUser() async {
    getCurrentUserCalls += 1;
    return right(currentUser);
  }

  @override
  Future<Either<Failure, AppUser>> login({
    required String username,
    required String password,
  }) async {
    loginCalls += 1;

    if (loginFailure != null) {
      return left(loginFailure!);
    }

    return right(
      loginResult ??
          AppUser(id: 'fallback', username: username, role: UserRole.seller),
    );
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    logoutCalls += 1;
    currentUser = null;
    return right(unit);
  }
}

void main() {
  group('AuthBloc', () {
    test('starts loading and authenticates after AuthStarted', () async {
      final repository = _FakeAuthRepository(
        currentUser: const AppUser(
          id: 'u-admin-1',
          username: 'admin',
          role: UserRole.admin,
        ),
      );
      final bloc = AuthBloc(
        getCurrentUser: GetCurrentUser(repository),
        login: Login(repository, const ValidateCredentials()),
        logout: Logout(repository),
      );
      addTearDown(bloc.close);

      expect(bloc.state.status, AuthStatus.loading);

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthState>().having(
            (state) => state.status,
            'status',
            AuthStatus.loading,
          ),
          isA<AuthState>()
              .having(
                (state) => state.status,
                'status',
                AuthStatus.authenticated,
              )
              .having((state) => state.user, 'user', repository.currentUser),
        ]),
      );

      bloc.add(const AuthStarted());

      await expectation;

      expect(bloc.state.status, AuthStatus.authenticated);
      expect(bloc.state.user, repository.currentUser);
      expect(repository.getCurrentUserCalls, 1);
    });

    test('emits failure then unauthenticated when login fails', () async {
      final repository = _FakeAuthRepository()
        ..loginFailure = const InvalidCredentialsFailure();
      final bloc = AuthBloc(
        getCurrentUser: GetCurrentUser(repository),
        login: Login(repository, const ValidateCredentials()),
        logout: Logout(repository),
      );
      addTearDown(bloc.close);

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthState>().having(
            (state) => state.status,
            'status',
            AuthStatus.loading,
          ),
          isA<AuthState>()
              .having((state) => state.status, 'status', AuthStatus.failure)
              .having(
                (state) => state.failure,
                'failure',
                isA<InvalidCredentialsFailure>(),
              ),
          isA<AuthState>().having(
            (state) => state.status,
            'status',
            AuthStatus.unauthenticated,
          ),
        ]),
      );

      bloc.add(const LoginSubmitted(username: 'admin', password: 'wrong'));

      await expectation;

      expect(bloc.state.status, AuthStatus.unauthenticated);
      expect(bloc.state.failure, isNull);
      expect(repository.loginCalls, 1);
    });

    test('logs out to an unauthenticated state and clears the user', () async {
      final repository = _FakeAuthRepository(
        currentUser: const AppUser(
          id: 'u-seller-1',
          username: 'seller',
          role: UserRole.seller,
        ),
      );
      final bloc = AuthBloc(
        getCurrentUser: GetCurrentUser(repository),
        login: Login(repository, const ValidateCredentials()),
        logout: Logout(repository),
      );
      addTearDown(bloc.close);

      final startedExpectation = expectLater(
        bloc.stream,
        emitsThrough(
          isA<AuthState>().having(
            (state) => state.status,
            'status',
            AuthStatus.authenticated,
          ),
        ),
      );

      bloc.add(const AuthStarted());

      await startedExpectation;

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthState>()
              .having(
                (state) => state.status,
                'status',
                AuthStatus.unauthenticated,
              )
              .having((state) => state.user, 'user', isNull),
        ]),
      );

      bloc.add(const LogoutRequested());

      await expectation;

      expect(bloc.state.status, AuthStatus.unauthenticated);
      expect(bloc.state.user, isNull);
      expect(repository.logoutCalls, 1);
    });
  });
}
