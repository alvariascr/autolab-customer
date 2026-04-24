import 'package:autolab_core/autolab_core.dart';

class FeatureLogger {
  FeatureLogger(this._logger);

  final AppLogger _logger;
  static const _redacted = '<redacted>';
  static const _fullyRedactedKeys = {
    'password',
    'phone',
    'token',
    'accesstoken',
    'refreshtoken',
    'authorization',
  };
  static const _maskedIdentifierKeys = {
    'email',
    'userid',
    'user_id',
  };

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
          .map((entry) => '${entry.key}=${_sanitizeValue(entry.key, entry.value)}')
          .join(' ');

      if (formattedContext.isNotEmpty) {
        buffer.write(' $formattedContext');
      }
    }

    return buffer.toString();
  }

  Object _sanitizeValue(String key, Object? value) {
    if (value == null) {
      return '';
    }

    final normalizedKey = key.toLowerCase();
    if (_fullyRedactedKeys.contains(normalizedKey)) {
      return _redacted;
    }

    if (_maskedIdentifierKeys.contains(normalizedKey) && value is String) {
      if (normalizedKey == 'email') {
        return _maskEmail(value);
      }

      return _maskIdentifier(value);
    }

    return value;
  }

  String _maskEmail(String email) {
    final atIndex = email.indexOf('@');
    if (atIndex <= 0) {
      return _redacted;
    }

    final localPart = email.substring(0, atIndex);
    final domain = email.substring(atIndex);
    final prefix = localPart.substring(0, 1);
    return '$prefix***$domain';
  }

  String _maskIdentifier(String value) {
    if (value.isEmpty) {
      return _redacted;
    }

    if (value.length <= 4) {
      return '${value.substring(0, 1)}***';
    }

    return '${value.substring(0, 3)}***${value.substring(value.length - 2)}';
  }
}
