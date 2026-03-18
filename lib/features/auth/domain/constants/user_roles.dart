class UserRoles {
  static const String customer = 'customer';
  static const String admin = 'admin';

  static const List<String> allowed = [
    customer,
    admin,
  ];

  static bool isValid(String role) {
    return allowed.contains(role);
  }
}