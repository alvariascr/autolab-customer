import 'package:autolab_core/autolab_core.dart';

class AuthRateLimitFailure extends Failure {
  final Duration remaining;

  const AuthRateLimitFailure({
    required this.remaining,
    required String message,
    String? code,
    String? uiKey,
    Object? cause,
    StackTrace? stackTrace,
  }) : super(
         message,
         code: code,
         uiKey: uiKey,
         cause: cause,
         stackTrace: stackTrace,
       );
}
