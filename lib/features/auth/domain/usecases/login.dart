import 'package:flutter_pos/features/auth/domain/entities/app_user.dart';
import 'package:flutter_pos/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_pos/features/auth/domain/usecases/validate_credentials.dart';

class Login {
  const Login(this.repository, this.validateCredentials);

  final AuthRepository repository;
  final ValidateCredentials validateCredentials;

  Future<AppUser> call({required String username, required String password}) {
    validateCredentials(username: username, password: password);
    return repository.login(username: username, password: password);
  }
}
