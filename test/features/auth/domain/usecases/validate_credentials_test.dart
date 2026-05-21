import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_pos/features/auth/domain/errors/auth_failures.dart';
import 'package:flutter_pos/features/auth/domain/usecases/validate_credentials.dart';

void main() {
  group('ValidateCredentials', () {
    const useCase = ValidateCredentials();

    test('accepts non-empty username and password', () {
      expect(
        () => useCase(username: 'admin', password: 'admin123'),
        returnsNormally,
      );
    });

    test('throws when username is empty after trim', () {
      expect(
        () => useCase(username: '   ', password: 'admin123'),
        throwsA(isA<InvalidCredentialInputFailure>()),
      );
    });

    test('throws when password is empty', () {
      expect(
        () => useCase(username: 'admin', password: ''),
        throwsA(isA<InvalidCredentialInputFailure>()),
      );
    });
  });
}
