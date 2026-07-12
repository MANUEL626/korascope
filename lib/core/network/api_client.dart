import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class ApiClient {
  final http.Client _client;
  String? secretKey;
  void Function()? onUnauthorized;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  Uri _uri(String path) =>
      Uri.parse('${AppConfig.apiBaseUrl}${AppConfig.apiPrefix}$path');

  Map<String, String> _headers({bool protected = true}) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (protected && secretKey != null) {
      headers['X-Secret-Key'] = secretKey!;
    }
    return headers;
  }

  Future<dynamic> get(String path, {bool protected = true}) async {
    final response = await _client
        .get(_uri(path), headers: _headers(protected: protected))
        .timeout(const Duration(seconds: 20));
    return _decode(response, path: path, protected: protected);
  }

  Future<dynamic> post(
    String path, {
    Object? body,
    bool protected = true,
  }) async {
    final response = await _client
        .post(
          _uri(path),
          headers: _headers(protected: protected),
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));
    return _decode(response, path: path, protected: protected);
  }

  Future<dynamic> postExternal(
    String url, {
    required Object body,
    Duration timeout = const Duration(minutes: 3),
  }) async {
    final response = await _client
        .post(
          Uri.parse(url),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(timeout);
    return _decode(response, handleUnauthorized: false);
  }

  Future<dynamic> put(String path, {required Object body}) async {
    final response = await _client
        .put(_uri(path), headers: _headers(), body: jsonEncode(body))
        .timeout(const Duration(seconds: 20));
    return _decode(response, path: path);
  }

  Future<void> delete(String path) async {
    final response = await _client
        .delete(_uri(path), headers: _headers())
        .timeout(const Duration(seconds: 20));
    _decode(response, path: path);
  }

  Future<String> uploadImage({
    required Uint8List bytes,
    required String filename,
  }) async {
    final request = http.MultipartRequest('POST', _uri('/uploads'));
    if (secretKey != null) request.headers['X-Secret-Key'] = secretKey!;
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: filename),
    );
    final streamed = await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamed);
    final data = _decode(response, path: '/uploads') as Map<String, dynamic>;
    return _normalizeUrl(data['url'] as String);
  }

  String _normalizeUrl(String value) {
    if (value.startsWith('http://localhost:8080')) {
      return value.replaceFirst('http://localhost:8080', AppConfig.apiBaseUrl);
    }
    return value;
  }

  dynamic _decode(
    http.Response response, {
    bool handleUnauthorized = true,
    String? path,
    bool protected = true,
  }) {
    dynamic data;
    if (response.body.isNotEmpty) {
      try {
        data = jsonDecode(utf8.decode(response.bodyBytes));
      } on FormatException {
        data = null;
      }
    }
    if (response.statusCode >= 200 && response.statusCode < 300) return data;
    if (handleUnauthorized && response.statusCode == 401) {
      onUnauthorized?.call();
    }
    if (handleUnauthorized &&
        protected &&
        response.statusCode == 404 &&
        path == '/utilisateurs/me') {
      onUnauthorized?.call();
    }
    final message = data is Map<String, dynamic>
        ? data['message']?.toString()
        : null;
    throw ApiException(
      response.statusCode,
      message ?? 'Une erreur réseau est survenue (${response.statusCode}).',
    );
  }

  void close() => _client.close();
}
