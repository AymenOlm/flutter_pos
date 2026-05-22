import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_pos/core/errors/failures.dart';
import 'package:flutter_pos/features/auth/domain/errors/auth_failures.dart';
import 'package:flutter_pos/features/auth/domain/usecases/validate_credentials.dart';

void main() {
  group('ValidateCredentials', () {
    const useCase = ValidateCredentials();

    test('accepts non-empty username and password', () {
      expect(useCase(username: 'admin', password: 'admin123').isRight(), true);
    });

    test('throws when username is empty after trim', () {
      final result = useCase(username: '   ', password: 'admin123');
      expect(result.isLeft(), true);
      expect(
        result.fold((failure) => failure, (_) => null),
        isA<InvalidCredentialInputFailure>(),
      );
    });

    test('throws when password is empty', () {
      final result = useCase(username: 'admin', password: '');
      expect(result.isLeft(), true);
      expect(
        result.fold((failure) => failure, (_) => null),
        isA<InvalidCredentialInputFailure>(),
      );
    });
  });
}
