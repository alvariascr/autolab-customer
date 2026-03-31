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
  WidgetsFlutterBinding.ensureInitialized();

  final config = AutolabCoreBootstrap.loadConfig();

  await Supabase.initialize(
    url: config.supabaseUrl.toString(),
    anonKey: config.supabaseAnonKey,
  );

  await di.init(config: config);

  CoreDI.get<GlobalErrorHandler>().registerFlutterHandlers();

  final authBloc = di.sl<AuthBloc>()..add(const RestoreSession());
  final router = AppRouter(authBloc).router;

  runZonedGuarded(
        () {
      runApp(
        MyApp(
          authBloc: authBloc,
          router: router,
        ),
      );
    },
        (error, stackTrace) {
      CoreDI.get<GlobalErrorHandler>().handle(error, stackTrace);
    },
  );
}