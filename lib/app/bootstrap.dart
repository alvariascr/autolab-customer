import 'dart:async';

import 'package:autolab_core/autolab_core.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/di/app_injection.dart' as di;
import '../core/location/location_cubit.dart';
import '../core/router/app_router.dart';
import '../features/auth/application/auth_session_cubit.dart';
import '../features/auth/repository/auth_repository.dart';
import 'app.dart';

Future<void> bootstrap() async {
  final completer = Completer<void>();

  runZonedGuarded(
    () async {
      debugPrint('[bootstrap] starting Flutter bootstrap');
      WidgetsFlutterBinding.ensureInitialized();

      final config = AutolabCoreBootstrap.loadConfig();

      await Supabase.initialize(
        url: config.supabaseUrl.toString(),
        anonKey: config.supabaseAnonKey,
      );

      await di.init(config: config);

      final authRepository = di.sl<AuthRepository>();
      final authSessionCubit = di.sl<AuthSessionCubit>()..restoreSession();
      final locationCubit = di.sl<LocationCubit>();
      final router = AppRouter(authSessionCubit).router;

      debugPrint('[bootstrap] dependencies ready, running app');
      runApp(
        MyApp(
          authRepository: authRepository,
          authSessionCubit: authSessionCubit,
          locationCubit: locationCubit,
          router: router,
        ),
      );

      if (!completer.isCompleted) {
        completer.complete();
      }
    },
    (error, stackTrace) {
      if (CoreDI.instance.isRegistered<GlobalErrorHandler>()) {
        CoreDI.get<GlobalErrorHandler>().handle(error, stackTrace);
      } else {
        debugPrint('[bootstrap] error antes de DI: $error');
        debugPrintStack(stackTrace: stackTrace);
      }

      if (!completer.isCompleted) {
        completer.completeError(error, stackTrace);
      }
    },
  );

  await completer.future;
}
