import 'package:flutter_pos/features/auth/domain/entities/app_user.dart';
import 'package:flutter_pos/features/auth/domain/repositories/auth_repository.dart';

class Login {
  const Login(this.repository);

  final AuthRepository repository;

  Future<AppUser> call({required String username, required String password}) {
    return repository.login(username: username, password: password);
  }
}
