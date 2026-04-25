import 'package:flutter_pos/features/auth/domain/entities/app_user.dart';
import 'package:flutter_pos/features/auth/domain/repositories/auth_repository.dart';

class GetCurrentUser {
  const GetCurrentUser(this.repository);

  final AuthRepository repository;

  Future<AppUser?> call() {
    return repository.getCurrentUser();
  }
}
