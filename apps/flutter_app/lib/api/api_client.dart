import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';

class ApiClient {
  ApiClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = AppConfig.apiBaseUrl.endsWith('/')
        ? AppConfig.apiBaseUrl.substring(0, AppConfig.apiBaseUrl.length - 1)
        : AppConfig.apiBaseUrl;
    return Uri.parse('$base$path').replace(queryParameters: query);
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    required String? bearerToken,
  }) async {
    final resp = await _http.get(
      _uri(path),
      headers: _headers(bearerToken),
    );
    return _handleJson(resp);
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    required String? bearerToken,
    Object? body,
  }) async {
    final resp = await _http.post(
      _uri(path),
      headers: _headers(bearerToken),
      body: body == null ? null : jsonEncode(body),
    );
    return _handleJson(resp);
  }

  Map<String, String> _headers(String? bearerToken) {
    return {
      'content-type': 'application/json',
      if (bearerToken != null) 'authorization': 'Bearer $bearerToken',
    };
  }

  Map<String, dynamic> _handleJson(http.Response resp) {
    final decoded = resp.body.isEmpty ? null : jsonDecode(resp.body);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      if (decoded is Map<String, dynamic>) return decoded;
      return {'data': decoded};
    }
    throw ApiException(resp.statusCode, decoded ?? resp.body);
  }
}

class ApiException implements Exception {
  ApiException(this.statusCode, this.body);

  final int statusCode;
  final Object body;

  @override
  String toString() => 'ApiException($statusCode, $body)';
}

