import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:autolab_core/autolab_core.dart';

import 'core/di/injection_container.dart' as di;
import 'core/di/injection_container.dart';
import 'core/router/app_router.dart';
import 'common/bloc/authentication_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔐 Carga y valida variables de entorno (fail-fast)
  final config = AutolabCoreBootstrap.loadConfig();
  // (opcional) si no lo usas aún, no pasa nada. La validación ya se ejecutó.
  // ignore: unused_local_variable
  final _ = config;

  await di.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Prueba mínima de integración con autolab_core
    // ignore: unused_local_variable
    final coreMsg = CoreTest.hello();

    final authCubit = sl<AuthenticationCubit>();
    final router = AppRouter(authCubit).router;

    return BlocProvider.value(
      value: authCubit,
      child: MaterialApp.router(
        title: 'Autolab Customer',
        routerConfig: router,
      ),
    );
  }
}