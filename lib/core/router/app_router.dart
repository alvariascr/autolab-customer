import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/appointments/presentation/pages/my_appointments_page.dart';
import '../../features/auth/application/auth_session_cubit.dart';
import '../../features/auth/application/auth_session_state.dart';
import '../../features/auth/ui/forgot_password_page.dart';
import '../../features/auth/ui/login_page.dart';
import '../../features/auth/ui/reset_password_page.dart';
import '../../features/home/home_page.dart';
import '../../features/navigation/customer_navigation_shell.dart';
import '../../features/onboarding/customer_onboarding_page.dart';
import '../../features/products/presentation/pages/workshop_search_products_page.dart';
import '../../features/profile/presentation/page/profile_page.dart';
import '../../features/profile/presentation/page/vehicles_page.dart';
import '../../features/splash/startup_splash_page.dart';
import '../../features/workshops/presentation/pages/workshop_appointment_page.dart';
import '../../features/workshops/presentation/pages/workshop_profile_page.dart';
import '../../l10n/app_localizations.dart';
import 'app_redirect_guard.dart';
import 'go_router_refresh_stream.dart';

class AppRouter {
  AppRouter(this.authSessionCubit, {AppRedirectGuard? redirectGuard})
    : _redirectGuard = redirectGuard ?? const AppRedirectGuard();

  final AuthSessionCubit authSessionCubit;
  final AppRedirectGuard _redirectGuard;

  late final GoRouter router = GoRouter(
    initialLocation: StartupSplashPage.routePath,
    refreshListenable: GoRouterRefreshStream(authSessionCubit.stream),
    redirect: (context, state) => redirectFor(
      authState: authSessionCubit.state,
      location: state.matchedLocation,
    ),
    routes: [
      GoRoute(
        path: StartupSplashPage.routePath,
        builder: (context, state) => const StartupSplashPage(),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _authTransitionPage(
          state: state,
          child: const LoginPage(),
          beginOffset: const Offset(-0.08, 0),
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        pageBuilder: (context, state) => _authTransitionPage(
          state: state,
          child: const ForgotPasswordPage(),
          beginOffset: const Offset(0.08, 0),
        ),
      ),
      GoRoute(
        path: '/reset-password',
        pageBuilder: (context, state) => _authTransitionPage(
          state: state,
          child: const ResetPasswordPage(),
          beginOffset: const Offset(0.08, 0),
        ),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomePage()),
      GoRoute(
        path: '/customer-onboarding',
        builder: (context, state) => const CustomerOnboardingPage(),
      ),
      GoRoute(
        path: '/home-customer',
        builder: (context, state) => const CustomerNavigationShell(),
      ),
      GoRoute(
        path: '/appointments',
        builder: (context, state) => const MyAppointmentsPage(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/vehicles',
        builder: (context, state) => const VehiclesPage(),
      ),
      GoRoute(
        path: '/workshops/:id',
        builder: (context, state) {
          final workshopId = state.pathParameters['id']?.trim();

          if (workshopId == null || workshopId.isEmpty) {
            return const _InvalidRoutePage();
          }

          return WorkshopProfilePage(
            workshopId: workshopId,
            paymentStatus: state.uri.queryParameters['payment'],
          );
        },
      ),
      GoRoute(
        path: '/workshops/:id/appointments/new',
        builder: (context, state) {
          final workshopId = state.pathParameters['id']?.trim();

          if (workshopId == null || workshopId.isEmpty) {
            return const _InvalidRoutePage();
          }

          return WorkshopAppointmentPage(workshopId: workshopId);
        },
      ),
      GoRoute(
        path: '/search/workshops/:id/products',
        builder: (context, state) {
          final workshopId = state.pathParameters['id']?.trim();

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

CustomTransitionPage<void> _authTransitionPage({
  required GoRouterState state,
  required Widget child,
  required Offset beginOffset,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 360),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      final offsetAnimation = Tween<Offset>(
        begin: beginOffset,
        end: Offset.zero,
      ).animate(curvedAnimation);

      return FadeTransition(
        opacity: curvedAnimation,
        child: SlideTransition(position: offsetAnimation, child: child),
      );
    },
  );
}

class _InvalidRoutePage extends StatelessWidget {
  const _InvalidRoutePage();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(body: Center(child: Text(l10n.routerInvalidWorkshopId)));
  }
}
