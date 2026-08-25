import 'package:autolab_customer/features/notifications/presentation/cubit/notifications_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('notifications siempre es inmutable', () {
    final state = NotificationsState();

    expect(state.notifications.clear, throwsUnsupportedError);
  });
}
