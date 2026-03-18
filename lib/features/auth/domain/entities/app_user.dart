class AppUser {
  final String id;
  final String? email;
  final String role;

  const AppUser({
    required this.id,
    this.email,
    required this.role,
  });
}
