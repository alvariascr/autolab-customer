import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  final String id;
  final String? email;
  final String role;

  const AppUser({required this.id, this.email, required this.role});

  @override
  List<Object?> get props => [id, email, role];
}
