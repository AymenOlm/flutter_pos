import 'package:flutter_pos/features/auth/domain/repositories/auth_repository.dart';

class Logout {
  const Logout(this.repository);

  final AuthRepository repository;

  Future<void> call() {
    return repository.logout();
  }
}
