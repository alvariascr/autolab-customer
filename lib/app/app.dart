import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../core/location/location_cubit.dart';
import '../features/auth/application/auth_session_cubit.dart';
import '../features/auth/repository/auth_repository.dart';
import '../l10n/app_localizations.dart';

class MyApp extends StatelessWidget {
  final AuthRepository authRepository;
  final AuthSessionCubit authSessionCubit;
  final LocationCubit locationCubit;
  final GoRouter router;

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
        onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
        routerConfig: router,
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
