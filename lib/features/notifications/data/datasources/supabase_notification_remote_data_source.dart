import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/customer_notification_model.dart';
import 'notification_remote_data_source.dart';

class SupabaseNotificationRemoteDataSource
    implements NotificationRemoteDataSource {
  const SupabaseNotificationRemoteDataSource(this.client);

  final SupabaseClient client;

  @override
  Future<List<CustomerNotificationModel>> loadNotifications({
    required String userId,
  }) async {
    final response = await client
        .from('notifications')
        .select('id, workshop_id, title, body, type, is_read, updated_at')
        .eq('user_id', userId)
        .order('updated_at', ascending: false)
        .limit(50);

    return response
        .map(CustomerNotificationModel.fromMap)
        .where((item) => item.id.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Stream<List<CustomerNotificationModel>> watchNotifications({
    required String userId,
  }) {
    return client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('updated_at', ascending: false)
        .limit(50)
        .map(
          (response) => response
              .map(CustomerNotificationModel.fromMap)
              .where((item) => item.id.isNotEmpty)
              .toList(growable: false),
        );
  }

  @override
  Future<void> markAsRead({required String notificationId}) async {
    await client.rpc(
      'mark_customer_notification_read',
      params: {'p_notification_id': notificationId},
    );
  }
}
