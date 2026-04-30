import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_session_cubit.dart';
import '../../features/auth/application/auth_session_state.dart';
import '../../features/auth/domain/constants/user_roles.dart';
import '../../features/auth/ui/login_page.dart';
import '../../features/home/home_customer_page.dart';
import '../../features/home/home_page.dart';
import '../../features/workshops/presentation/pages/workshop_profile_page.dart';
import 'go_router_refresh_stream.dart';

class AppRouter {
  final AuthSessionCubit authSessionCubit;

  AppRouter(this.authSessionCubit);

  late final GoRouter router = GoRouter(
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(authSessionCubit.stream),
    redirect: (context, state) => redirectFor(
      authState: authSessionCubit.state,
      location: state.matchedLocation,
    ),
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/home', builder: (context, state) => const HomePage()),
      GoRoute(
        path: '/home-customer',
        builder: (context, state) => const HomeCustomerPage(),
      ),
      GoRoute(
        path: '/workshops/:id',
        builder: (context, state) {
          return WorkshopProfilePage(workshopId: state.pathParameters['id']!);
        },
      ),
    ],
  );

  String? redirectFor({
    required AuthSessionState authState,
    required String location,
  }) {
    final bool isLoggingIn = location == '/login';

    // Si el estado está cargando, no redirigir todavía.
    // Esto evita el salto visual temporal hacia /login
    // mientras se restaura la sesión.
    if (authState.status == AuthSessionStatus.loading ||
        authState.status == AuthSessionStatus.initial) {
      return null;
    }

    // Si no está autenticado, solo puede quedarse en /login.
    if (!authState.isAuthenticated) {
      return isLoggingIn ? null : '/login';
    }

    final String role = authState.role!;

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
