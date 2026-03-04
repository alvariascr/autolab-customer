import 'package:go_router/go_router.dart';
import 'go_router_refresh_stream.dart';

import '../../common/bloc/authentication_cubit.dart';
import '../../presentation/pages/home_page.dart';
import '../../presentation/pages/login_page.dart';

class AppRouter {
  final AuthenticationCubit authCubit;

  AppRouter(this.authCubit);

  GoRouter get router => GoRouter(
        initialLocation: Routes.login,
        refreshListenable: GoRouterRefreshStream(authCubit.stream),
        redirect: (context, state) {
          final loggedIn = authCubit.isLoggedIn;
          final goingToLogin = state.matchedLocation == Routes.login;

          // Si NO está logueado y va a ruta privada => manda a login
          if (!loggedIn && !goingToLogin) return Routes.login;

          // Si está logueado y va a login => manda a home
          if (loggedIn && goingToLogin) return Routes.home;

          return null;
        },
        routes: [
          GoRoute(
            path: Routes.login,
            builder: (context, state) => const LoginPage(),
          ),
          GoRoute(
            path: Routes.home,
            builder: (context, state) => const HomePage(),
          ),
        ],
      );
}

class Routes {
  static const login = '/login'; // Pública
  static const home = '/home'; // Privada
}