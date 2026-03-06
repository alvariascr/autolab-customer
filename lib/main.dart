import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:autolab_core/autolab_core.dart';

import 'core/di/injection_container.dart' as di;
import 'core/di/injection_container.dart';
import 'core/router/app_router.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carga y valida variables de entorno (fail-fast)
  final config = AutolabCoreBootstrap.loadConfig();

  // Inicializa Supabase ANTES de usar GetIt
  await Supabase.initialize(
    url: config.supabaseUrl.toString(),
    anonKey: config.supabaseAnonKey,
  );

  // Inicializa dependencias
  await di.init();

  final authBloc = sl<AuthBloc>()..add(const RestoreSession());
  final router = AppRouter(authBloc).router;

  runApp(MyApp(authBloc: authBloc, router: router));
}

class MyApp extends StatelessWidget {
  final AuthBloc authBloc;
  final dynamic router;

  const MyApp({
    super.key,
    required this.authBloc,
    required this.router,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: authBloc,
      child: MaterialApp.router(
        title: 'Autolab Customer',
        routerConfig: router,
      ),
    );
  }
}