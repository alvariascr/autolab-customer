import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/bloc/auth_bloc.dart';
import '../core/location/location_cubit.dart';

class MyApp extends StatelessWidget {
  final AuthBloc authBloc;
  final LocationCubit locationCubit;
  final GoRouter router;

  const MyApp({
    super.key,
    required this.authBloc,
    required this.locationCubit,
    required this.router,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: authBloc),
        BlocProvider.value(value: locationCubit),
      ],
      child: MaterialApp.router(
        title: 'Autolab Customer',
        routerConfig: router,
      ),
    );
  }
}
