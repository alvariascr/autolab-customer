import 'package:go_router/go_router.dart';

import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/bloc/auth_state.dart';
import '../../features/auth/ui/login_page.dart';
import '../../features/home/home_customer_page.dart';
import '../../features/home/home_page.dart';
import 'go_router_refresh_stream.dart';

class AppRouter {
  final AuthBloc authBloc;

  AppRouter(this.authBloc);

  late final GoRouter router = GoRouter(
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) {
      final authState = authBloc.state;
      final currentLocation = state.matchedLocation;
      final goingToLogin = currentLocation == '/login';

      if (authState is! AuthSuccess) {
        return goingToLogin ? null : '/login';
      }

      if (authState.role == 'customer') {
        if (currentLocation != '/home-customer') {
          return '/home-customer';
        }
        return null;
      }

      if (authState.role == 'admin') {
        if (currentLocation != '/home') {
          return '/home';
        }
        return null;
      }

      return '/login';
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/home-customer',
        builder: (context, state) => const HomeCustomerPage(),
      ),
    ],
  );
}