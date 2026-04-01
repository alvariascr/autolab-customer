import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/bloc/auth_bloc.dart';

class MyApp extends StatelessWidget {
  final AuthBloc authBloc;
  final GoRouter router;

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