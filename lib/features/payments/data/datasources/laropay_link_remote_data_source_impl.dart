import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/laropay_gateway_config.dart';
import '../../domain/entities/laropay_link_request.dart';
import '../models/laropay_link_model.dart';
import 'laropay_link_remote_data_source.dart';

class LaropayLinkRemoteDataSourceImpl implements LaropayLinkRemoteDataSource {
  const LaropayLinkRemoteDataSourceImpl({
    required http.Client client,
    required LaropayGatewayConfig config,
    required String? Function() authTokenProvider,
  }) : _client = client,
       _config = config,
       _authTokenProvider = authTokenProvider;

  final http.Client _client;
  final LaropayGatewayConfig _config;
  final String? Function() _authTokenProvider;

  @override
  Future<LaropayLinkModel> generateLink(LaropayLinkRequest request) async {
    final uri = _config.generateLinkUri;
    if (!_config.isConfigured || uri == null) {
      throw StateError('LAROPAY_GENERATE_LINK_URL is not configured');
    }

    final authToken = _authTokenProvider()?.trim();
    final response = await _client
        .post(
          uri,
          headers: {
            'accept': 'application/json',
            'content-type': 'application/json',
            if (authToken != null && authToken.isNotEmpty)
              'authorization': 'Bearer $authToken',
          },
          body: jsonEncode(request.toGatewayJson()),
        )
        .timeout(_config.timeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw LaropayGatewayException(
        statusCode: response.statusCode,
        message: response.body,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Laropay response must be a JSON object');
    }

    return LaropayLinkModel.fromJson(decoded);
  }
}

class LaropayGatewayException implements Exception {
  const LaropayGatewayException({
    required this.statusCode,
    required this.message,
  });

  final int statusCode;
  final String message;

  @override
  String toString() => 'LaropayGatewayException($statusCode)';
}
