import 'dart:async';
import 'package:flutter/foundation.dart';

/// Helper para que GoRouter reevalúe `redirect` cuando cambie un Stream.
/// Usado con `AuthenticationCubit.stream` para refrescar navegación al hacer login/logout.
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}