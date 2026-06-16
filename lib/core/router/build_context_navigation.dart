import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

extension BuildContextNavigation on BuildContext {
  void popOrGo(String fallbackLocation) {
    final router = GoRouter.of(this);

    if (router.canPop()) {
      pop();
      return;
    }

    go(fallbackLocation);
  }
}
