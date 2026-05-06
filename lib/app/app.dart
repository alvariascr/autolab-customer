import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/location/location_cubit.dart';
import '../features/auth/application/auth_feedback.dart';
import '../features/auth/application/auth_session_cubit.dart';
import '../features/auth/application/auth_session_state.dart';
import '../features/auth/repository/auth_repository.dart';
import '../features/auth/ui/auth_ui_error_resolver.dart';
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

  @override
  void initState() {
    super.initState();
    _authStateSubscription = Supabase.instance.client.auth.onAuthStateChange
        .listen((data) {
          if (data.event == AuthChangeEvent.passwordRecovery) {
            widget.router.go('/reset-password');
          }
        });
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        RepositoryProvider.value(value: widget.authRepository),
        BlocProvider.value(value: widget.authSessionCubit),
        BlocProvider.value(value: widget.locationCubit),
      ],
      child: MaterialApp.router(
        scaffoldMessengerKey: MyApp._scaffoldMessengerKey,
        onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
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
      ),
    );
  }
}
