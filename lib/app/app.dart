import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../core/location/location_cubit.dart';
import '../features/auth/application/auth_session_cubit.dart';
import '../features/auth/application/auth_session_state.dart';
import '../features/auth/repository/auth_repository.dart';
import '../features/auth/ui/auth_ui_error_resolver.dart';
import '../l10n/app_localizations.dart';

class MyApp extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        RepositoryProvider.value(value: authRepository),
        BlocProvider.value(value: authSessionCubit),
        BlocProvider.value(value: locationCubit),
      ],
      child: MaterialApp.router(
        scaffoldMessengerKey: _scaffoldMessengerKey,
        onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
        routerConfig: router,
        builder: (context, child) {
          return BlocListener<AuthSessionCubit, AuthSessionState>(
            listenWhen: (previous, current) {
              return previous.message != current.message ||
                  previous.code != current.code ||
                  previous.uiKey != current.uiKey;
            },
            listener: (context, state) {
              if (state.message == null &&
                  (state.code == null || state.code!.isEmpty) &&
                  (state.uiKey == null || state.uiKey!.isEmpty)) {
                return;
              }

              final l10n = AppLocalizations.of(context)!;
              final resolvedMessage = AuthUiErrorResolver.resolve(
                l10n: l10n,
                code: state.code,
                uiKey: state.uiKey,
                message: state.message,
              );

              _scaffoldMessengerKey.currentState
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
