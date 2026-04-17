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
    redirect: (context, state) =>
        redirectFor(authState: authBloc.state, location: state.matchedLocation),
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/home', builder: (context, state) => const HomePage()),
      GoRoute(
        path: '/home-customer',
        builder: (context, state) => const HomeCustomerPage(),
      ),
    ],
  );

  String? redirectFor({
    required AuthState authState,
    required String location,
  }) {
    final bool isLoggingIn = location == '/login';

    // Si el estado está cargando, no redirigir todavía.
    // Esto evita el salto visual temporal hacia /login
    // mientras se restaura la sesión.
    if (authState is AuthLoading) return null;

    // Si no está autenticado, solo puede quedarse en /login.
    if (authState is! AuthSuccess) {
      return isLoggingIn ? null : '/login';
    }

    final String role = authState.role;

    // Si ya está autenticado y está en login,
    // redirigir al home correspondiente según rol.
    if (isLoggingIn) {
      return role == UserRoles.admin ? '/home' : '/home-customer';
    }

    // Protección de rutas por rol:
    // customer no puede entrar al home de admin.
    if (role == UserRoles.customer && location == '/home') {
      return '/home-customer';
    }

    // admin no puede entrar al home de customer.
    if (role == UserRoles.admin && location == '/home-customer') {
      return '/home';
    }

    return null;
  }
}
