import 'package:autolab_core/autolab_core.dart';

class AuthRateLimitFailure extends Failure {
  final Duration remaining;

  const AuthRateLimitFailure({
    required this.remaining,
    required String message,
  }) : super(message);
}