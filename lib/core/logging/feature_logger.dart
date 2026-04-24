import 'package:autolab_core/autolab_core.dart';

class FeatureLogger {
  FeatureLogger(this._logger);

  final AppLogger _logger;

  void info({
    required String feature,
    required String action,
    String? code,
    Map<String, Object?> context = const {},
  }) {
    _logger.i(_buildMessage(feature, action, code: code, context: context));
  }

  void warn({
    required String feature,
    required String action,
    String? code,
    Map<String, Object?> context = const {},
    Object? error,
    StackTrace? stackTrace,
  }) {
    _logger.w(
      _buildMessage(feature, action, code: code, context: context),
      error: error,
      stackTrace: stackTrace,
    );
  }

  void error({
    required String feature,
    required String action,
    String? code,
    Map<String, Object?> context = const {},
    Object? error,
    StackTrace? stackTrace,
  }) {
    _logger.e(
      _buildMessage(feature, action, code: code, context: context),
      error: error,
      stackTrace: stackTrace,
    );
  }

  String _buildMessage(
    String feature,
    String action, {
    String? code,
    Map<String, Object?> context = const {},
  }) {
    final buffer = StringBuffer('[$feature.$action]');

    if (code != null && code.isNotEmpty) {
      buffer.write(' code=$code');
    }

    if (context.isNotEmpty) {
      final formattedContext = context.entries
          .where((entry) => entry.value != null)
          .map((entry) => '${entry.key}=${entry.value}')
          .join(' ');

      if (formattedContext.isNotEmpty) {
        buffer.write(' $formattedContext');
      }
    }

    return buffer.toString();
  }
}
