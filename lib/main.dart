import 'package:flutter/material.dart';
import 'package:autolab_core/autolab_core.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(CoreTest.hello()),
        ),
      ),
    );
  }
}