import 'package:equatable/equatable.dart';

enum UserRole { admin, seller }

class AppUser extends Equatable {
  const AppUser({required this.id, required this.username, required this.role});

  final String id;
  final String username;
  final UserRole role;

  @override
  List<Object?> get props => [id, username, role];
}
