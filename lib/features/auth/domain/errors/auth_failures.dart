class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class InvalidCredentialsFailure extends AuthFailure {
  const InvalidCredentialsFailure() : super('Invalid username or password.');
}

class AuthLockoutFailure extends AuthFailure {
  const AuthLockoutFailure({required this.remainingSeconds})
    : super(
        'Too many failed attempts. Try again in $remainingSeconds seconds.',
      );

  final int remainingSeconds;
}

class InvalidCredentialInputFailure extends AuthFailure {
  const InvalidCredentialInputFailure(super.message);
}
