//* import 'package:flutter/material.dart';
//* import 'package:flutter_bloc/flutter_bloc.dart';

//* import '../auth/bloc/auth_bloc.dart';
//* import '../auth/bloc/auth_event.dart';

//* class HomePage extends StatelessWidget {
//*   const HomePage({super.key});

//*   @override
//*   Widget build(BuildContext context) {
//*     return Scaffold(
//*       appBar: AppBar(
//*     title: const Text('Home'),
//*     actions: [
//*       IconButton(
//*        onPressed: () {
//*            context.read<AuthBloc>().add(const LogoutRequested());
//*        },
//*          icon: const Icon(Icons.logout),
//*       ),
//*     ],
//*   ),
//*   body: const Center(
//*      child: Text('Ruta privada ✅'),
//*   ),
//* );
//*  }
//*}
