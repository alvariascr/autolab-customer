import 'package:autolab_core/autolab_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/constants/user_roles.dart';
import 'user_role_data_source.dart';

class UserRoleDataSourceImpl implements UserRoleDataSource {
  final SupabaseClient client;

  UserRoleDataSourceImpl(this.client);

  @override
  Future<String> getUserRole(String userId) async {
    final response = await client
        .from('user_profiles')
        .select('role')
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) {
      throw const AuthFailure(message: 'Perfil de usuario no encontrado');
    }

    final role = response['role'] as String?;

    if (role == null || role.isEmpty) {
      throw const AuthFailure(message: 'Rol no definido para el usuario');
    }

    if (!UserRoles.isValid(role)) {
      throw const AuthFailure(message: 'Rol no autorizado');
    }

    return role;
  }
}