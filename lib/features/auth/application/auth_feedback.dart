import 'package:autolab_core/autolab_core.dart';

String? authPresentableMessage(Failure failure) {
  final message = failure.message;
  if (message.isEmpty) {
    return null;
  }

  if (message == failure.code) {
    return null;
  }

  return message;
}

bool hasAuthFeedback({String? message, String? code, String? uiKey}) {
  return (uiKey != null && uiKey.isNotEmpty) ||
      (code != null && code.isNotEmpty) ||
      (message != null && message.isNotEmpty);
}
