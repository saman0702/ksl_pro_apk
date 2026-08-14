import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/config.dart';

class ApiClient {
  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    if (kDebugMode) {
      debugPrint('[Katian Pro API] baseUrl = ${AppConfig.baseUrl}');
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (o) => debugPrint('[Katian Pro API] $o'),
        ),
      );
    }

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: _accessKey);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            final refreshed = await _tryRefresh();
            if (refreshed) {
              final opts = error.requestOptions;
              opts.headers['Authorization'] =
                  'Bearer ${await _storage.read(key: _accessKey)}';
              final clone = await _dio.fetch(opts);
              return handler.resolve(clone);
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  static const _accessKey = 'katian_pro_access_token';
  static const _refreshKey = 'katian_pro_refresh_token';
  static const _sessionPasswordKey = 'katian_pro_session_password';
  final _storage = const FlutterSecureStorage();

  late final Dio _dio;

  Dio get dio => _dio;

  Future<void> saveTokens(String access, String refresh) async {
    await _storage.write(key: _accessKey, value: access);
    await _storage.write(key: _refreshKey, value: refresh);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
    await clearSessionPassword();
  }

  Future<void> saveSessionPassword(String password) async {
    await _storage.write(key: _sessionPasswordKey, value: password);
  }

  Future<String?> readSessionPassword() async {
    return _storage.read(key: _sessionPasswordKey);
  }

  Future<void> clearSessionPassword() async {
    await _storage.delete(key: _sessionPasswordKey);
  }

  Future<bool> hasToken() async {
    final t = await _storage.read(key: _accessKey);
    return t != null && t.isNotEmpty;
  }

  Future<bool> _tryRefresh() async {
    final refresh = await _storage.read(key: _refreshKey);
    if (refresh == null) return false;
    try {
      final res = await Dio(
        BaseOptions(baseUrl: AppConfig.baseUrl),
      ).post('/auth/token/refresh/', data: {'refresh': refresh});
      final access = res.data['access'] as String?;
      if (access == null) return false;
      await _storage.write(key: _accessKey, value: access);
      return true;
    } catch (_) {
      await clearTokens();
      return false;
    }
  }

  String extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] != null) {
      return data['error'].toString();
    }
    if (data is Map && data['detail'] != null) {
      return data['detail'].toString();
    }
    if (e.response?.statusCode == 500) {
      return 'Erreur serveur lors du traitement. Réessayez ou contactez le support.';
    }
    if (e.response?.statusCode == 400) {
      return 'Données invalides. Vérifiez le formulaire.';
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Serveur injoignable (${AppConfig.baseUrl}).';
      case DioExceptionType.connectionError:
        return 'Connexion refusée. Vérifiez que le backend est démarré.';
      default:
        return e.message ?? 'Erreur réseau';
    }
  }
}
