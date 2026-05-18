import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_session_cubit.dart';
import '../../features/auth/application/auth_session_state.dart';
import '../../features/auth/ui/forgot_password_page.dart';
import '../../features/auth/ui/login_page.dart';
import '../../features/auth/ui/reset_password_page.dart';
import '../../features/home/home_customer_page.dart';
import '../../features/home/home_page.dart';
import '../../features/products/presentation/pages/workshop_search_products_page.dart';
import '../../features/workshops/presentation/pages/workshop_appointment_page.dart';
import '../../features/workshops/presentation/pages/workshop_profile_page.dart';
import 'app_redirect_guard.dart';
import 'go_router_refresh_stream.dart';

class AppRouter {
  AppRouter(this.authSessionCubit, {AppRedirectGuard? redirectGuard})
    : _redirectGuard = redirectGuard ?? const AppRedirectGuard();

  final AuthSessionCubit authSessionCubit;
  final AppRedirectGuard _redirectGuard;

  late final GoRouter router = GoRouter(
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(authSessionCubit.stream),
    redirect: (context, state) => redirectFor(
      authState: authSessionCubit.state,
      location: state.matchedLocation,
    ),
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => const ResetPasswordPage(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomePage()),
      GoRoute(
        path: '/home-customer',
        builder: (context, state) => const HomeCustomerPage(),
      ),
      GoRoute(
        path: '/workshops/:id',
        builder: (context, state) {
          final workshopId = state.pathParameters['id'];

          if (workshopId == null || workshopId.isEmpty) {
            return const _InvalidRoutePage();
          }

          return WorkshopProfilePage(workshopId: workshopId);
        },
      ),
      GoRoute(
        path: '/workshops/:id/appointment',
        builder: (context, state) {
          final workshopId = state.pathParameters['id'];

          if (workshopId == null || workshopId.isEmpty) {
            return const _InvalidRoutePage();
          }

          return WorkshopAppointmentPage(workshopId: workshopId);
        },
      ),
      GoRoute(
        path: '/search/workshops/:id/products',
        builder: (context, state) {
          final workshopId = state.pathParameters['id'];

          if (workshopId == null || workshopId.isEmpty) {
            return const _InvalidRoutePage();
          }

          return WorkshopSearchProductsPage(
            workshopId: workshopId,
            query: state.uri.queryParameters['query'] ?? '',
          );
        },
      ),
    ],
  );

  String? redirectFor({
    required AuthSessionState authState,
    required String location,
  }) => _redirectGuard.redirectFor(authState: authState, location: location);
}

class _InvalidRoutePage extends StatelessWidget {
  const _InvalidRoutePage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('ID de taller no valido')));
  }
}
