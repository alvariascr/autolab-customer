import 'dart:async';

import 'package:autolab_core/autolab_core.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/di/app_injection.dart' as di;
import '../core/router/app_router.dart';
import '../features/auth/bloc/auth_bloc.dart';
import '../features/auth/bloc/auth_event.dart';
import 'app.dart';

Future<void> bootstrap() async {
  final completer = Completer<void>();

  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      final config = AutolabCoreBootstrap.loadConfig();

      await Supabase.initialize(
        url: config.supabaseUrl.toString(),
        anonKey: config.supabaseAnonKey,
      );

      await di.init(config: config);

      final authBloc = di.sl<AuthBloc>()..add(const RestoreSession());
      final router = AppRouter(authBloc).router;

      runApp(MyApp(authBloc: authBloc, router: router));

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
