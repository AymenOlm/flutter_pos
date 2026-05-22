sealed class Failure {
  const Failure(this.message);

  final String message;

  @override
  String toString() => message;
}

final class DatabaseFailure extends Failure {
  const DatabaseFailure([super.message = 'A database error occurred.']);
}

final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'A network error occurred.']);
}

sealed class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

final class InvalidCredentialsFailure extends AuthFailure {
  const InvalidCredentialsFailure() : super('Invalid username or password.');
}

final class AuthLockoutFailure extends AuthFailure {
  const AuthLockoutFailure({required this.remainingSeconds})
    : super(
        'Too many failed attempts. Try again in $remainingSeconds seconds.',
      );

  final int remainingSeconds;
}

sealed class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

final class GenericValidationFailure extends ValidationFailure {
  const GenericValidationFailure(super.message);
}

final class InvalidCredentialInputFailure extends ValidationFailure {
  const InvalidCredentialInputFailure(super.message);
}
