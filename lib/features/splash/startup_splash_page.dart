import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/autolab_customer.dart';

class StartupSplashPage extends StatefulWidget {
  const StartupSplashPage({super.key});

  static const routePath = '/startup-splash';
  static const duration = Duration(seconds: 4);

  @override
  State<StartupSplashPage> createState() => _StartupSplashPageState();
}

class _StartupSplashPageState extends State<StartupSplashPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(StartupSplashPage.duration, _goToInitialRoute);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _goToInitialRoute() {
    if (!mounted) return;

    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AutolabCustomer.primary,
      child: SizedBox.expand(
        child: Image(
          image: AssetImage('assets/images/splash/splash_intro.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
