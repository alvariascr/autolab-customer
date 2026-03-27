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
      throw AuthFailure.fromErrorItem(ErrorCatalog.userProfileNotFound);
    }

    final role = response['role'] as String?;

    if (role == null || role.isEmpty) {
      throw AuthFailure.fromErrorItem(ErrorCatalog.undefinedUserRole);
    }

    if (!UserRoles.isValid(role)) {
      throw AuthFailure.fromErrorItem(ErrorCatalog.unauthorized);
    }

    return role;
  }
}