import 'package:go_router/go_router.dart';

import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/bloc/auth_state.dart';
import '../../features/auth/domain/constants/user_roles.dart';
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
      final String location = state.matchedLocation;
      final bool isLoggingIn = location == '/login';

      if (authState is AuthLoading) return null;

      if (authState is! AuthSuccess) {
        return isLoggingIn ? null : '/login';
      }

      final String role = authState.role;

      if (isLoggingIn) {
        return role == UserRoles.admin ? '/home' : '/home-customer';
      }

      if (role == UserRoles.customer && location == '/home') {
        return '/home-customer';
      }

      if (role == UserRoles.admin && location == '/home-customer') {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/home', builder: (context, state) => const HomePage()),
      GoRoute(
        path: '/home-customer',
        builder: (context, state) => const HomeCustomerPage(),
      ),
    ],
  );
}
