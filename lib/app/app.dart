import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/di/app_injection.dart';
import '../core/location/location_cubit.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/app_theme_mode_cubit.dart';
import '../features/auth/application/auth_feedback.dart';
import '../features/auth/application/auth_navigation_controller.dart';
import '../features/auth/application/auth_session_cubit.dart';
import '../features/auth/application/auth_session_state.dart';
import '../features/auth/repository/auth_repository.dart';
import '../features/auth/ui/auth_ui_error_resolver.dart';
import '../features/cart/application/cart_persistence.dart';
import '../features/notifications/presentation/cubit/notifications_cubit.dart';
import '../features/payments/application/laropay_return_navigation_controller.dart';
import '../l10n/app_localizations.dart';

class MyApp extends StatefulWidget {
  final AuthRepository authRepository;
  final AuthSessionCubit authSessionCubit;
  final LocationCubit locationCubit;
  final GoRouter router;
  static final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  const MyApp({
    super.key,
    required this.authRepository,
    required this.authSessionCubit,
    required this.locationCubit,
    required this.router,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription<AuthState>? _authStateSubscription;
  StreamSubscription<AuthSessionState>? _notificationAuthSubscription;
  Future<void> _notificationSyncOperation = Future.value();
  StreamSubscription<Uri>? _appLinkSubscription;
  final AppLinks _appLinks = AppLinks();
  late final AuthNavigationController _authNavigationController;
  late final LaropayReturnNavigationController
  _laropayReturnNavigationController;

  @override
  void initState() {
    super.initState();
    _authNavigationController = AuthNavigationController(
      navigate: widget.router.go,
      clearSession: () async {
        await sl<CartPersistence>().clear();
        await widget.authSessionCubit.logout();
      },
    );
    _laropayReturnNavigationController = LaropayReturnNavigationController(
      navigate: widget.router.go,
    );
    _authStateSubscription = Supabase.instance.client.auth.onAuthStateChange
        .listen(_authNavigationController.handleAuthState);
    _notificationAuthSubscription = widget.authSessionCubit.stream
        .distinct(
          (previous, current) =>
              previous.status == current.status &&
              previous.userId == current.userId,
        )
        .listen(_syncNotifications);
    _syncNotifications(widget.authSessionCubit.state);
    unawaited(_listenForAppLinks());
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    _notificationAuthSubscription?.cancel();
    _appLinkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _listenForAppLinks() async {
    _appLinkSubscription = _appLinks.uriLinkStream.listen(
      (uri) => unawaited(_handleAppLink(uri)),
    );

    final initialLink = await _appLinks.getInitialLink();
    if (initialLink == null) return;

    await _handleAppLink(initialLink);
  }

  Future<void> _handleAppLink(Uri uri) async {
    if (_laropayReturnNavigationController.handleAppLink(uri)) {
      return;
    }

    await _authNavigationController.handleAppLink(uri);
  }

  void _syncNotifications(AuthSessionState state) {
    final previousOperation = _notificationSyncOperation;
    _notificationSyncOperation = () async {
      await previousOperation;
      final cubit = sl<NotificationsCubit>();
      if (state.isAuthenticated) {
        await cubit.startWatching();
      } else {
        await cubit.clear();
      }
    }();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        RepositoryProvider.value(value: widget.authRepository),
        BlocProvider.value(value: widget.authSessionCubit),
        BlocProvider.value(value: widget.locationCubit),
        BlocProvider.value(value: sl<NotificationsCubit>()),
        BlocProvider(create: (_) => AppThemeModeCubit()),
      ],
      child: BlocBuilder<AppThemeModeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            scaffoldMessengerKey: MyApp._scaffoldMessengerKey,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode,
            onGenerateTitle: (context) =>
                AppLocalizations.of(context)!.appTitle,
            routerConfig: widget.router,
            builder: (context, child) {
              return BlocListener<AuthSessionCubit, AuthSessionState>(
                listenWhen: (previous, current) {
                  return previous.message != current.message ||
                      previous.code != current.code ||
                      previous.uiKey != current.uiKey;
                },
                listener: (context, state) {
                  if (!hasAuthFeedback(
                    message: state.message,
                    code: state.code,
                    uiKey: state.uiKey,
                  )) {
                    return;
                  }

                  final l10n = AppLocalizations.of(context)!;
                  final resolvedMessage = AuthUiErrorResolver.resolve(
                    l10n: l10n,
                    code: state.code,
                    uiKey: state.uiKey,
                    message: state.message,
                  );

                  MyApp._scaffoldMessengerKey.currentState
                    ?..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        content: Text(resolvedMessage),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );

                  context.read<AuthSessionCubit>().clearFeedback();
                },
                child: child ?? const SizedBox.shrink(),
              );
            },
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
          );
        },
      ),
    );
  }
}
