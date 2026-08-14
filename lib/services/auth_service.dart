import 'package:dio/dio.dart';

import '../models/models.dart';
import 'api_client.dart';

class AuthService {
  AuthService(this._api);

  final ApiClient _api;

  Future<KatianUser> login(String identifier, String password) async {
    final trimmed = identifier.trim();
    final res = await _api.dio.post('/auth/login/', data: {
      if (trimmed.contains('@')) 'email': trimmed else 'identifier': trimmed,
      'password': password,
    });
    final data = res.data as Map<String, dynamic>;
    await _api.saveTokens(
      data['access'] as String,
      data['refresh'] as String,
    );
    return KatianUser.fromJson(data);
  }

  Future<OtpVerifyResult> verifyIdentifier(String identifier) async {
    final res = await _api.dio.post('/auth/verify/', data: {
      'identifier': identifier.trim(),
    });
    final data = res.data as Map<String, dynamic>;
    return OtpVerifyResult(
      message: data['message'] as String? ?? 'Code envoyé',
      identifier: data['identifier'] as String? ?? identifier.trim(),
      channel: data['channel'] as String? ?? 'sms',
      destinationMasked: data['destination_masked'] as String?,
    );
  }

  Future<KatianUser> loginWithOtp({
    required String identifier,
    required String code,
  }) async {
    final res = await _api.dio.post('/auth/login/otp/', data: {
      'identifier': identifier.trim(),
      'code': code.trim(),
    });
    final data = res.data as Map<String, dynamic>;
    await _api.saveTokens(
      data['access'] as String,
      data['refresh'] as String,
    );
    return KatianUser.fromJson(data);
  }

  Future<KatianUser> profile() async {
    final res = await _api.dio.get('/auth/profile/');
    return KatianUser.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> logout() async {
    try {
      await _api.dio.post('/auth/logout/');
    } catch (_) {}
    await _api.clearSessionPassword();
    await _api.clearTokens();
  }

  Future<void> saveSessionPassword(String password) =>
      _api.saveSessionPassword(password);

  Future<String?> readSessionPassword() => _api.readSessionPassword();

  Future<void> clearSessionPassword() => _api.clearSessionPassword();

  Future<bool> isLoggedIn() => _api.hasToken();

  Future<ForgotPasswordResult> requestPasswordReset(String identifier) async {
    final res = await _api.dio.post('/auth/forgot-password/', data: {
      'identifier': identifier.trim(),
    });
    final data = res.data as Map<String, dynamic>;
    return ForgotPasswordResult(
      message: data['message'] as String? ?? 'Code envoyé',
      identifier: data['identifier'] as String? ?? identifier.trim(),
      channel: data['channel'] as String? ?? 'sms',
      destinationMasked: data['destination_masked'] as String?,
    );
  }

  Future<void> resetPassword({
    required String identifier,
    required String code,
    required String password,
  }) async {
    await _api.dio.post('/auth/reset-password/', data: {
      'identifier': identifier.trim(),
      'code': code.trim(),
      'password': password,
    });
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await _api.dio.post('/auth/change-password/', data: {
      'old_password': oldPassword,
      'new_password': newPassword,
    });
  }
}

class DashboardService {
  DashboardService(this._api);

  final ApiClient _api;

  Future<DashboardStats> fetchStats({Map<String, dynamic>? queryParams}) async {
    final res = await _api.dio.get(
      '/dashboard/stats/',
      queryParameters: queryParams?.isNotEmpty == true ? queryParams : null,
    );
    return DashboardStats.fromJson(
      Map<String, dynamic>.from(res.data as Map<String, dynamic>),
    );
  }
}

class FinanceService {
  FinanceService(this._api);

  final ApiClient _api;

  Future<RelayFinanceSummary> fetchTpSummary({
    Map<String, dynamic>? queryParams,
  }) async {
    final res = await _api.dio.get(
      '/finances/tp/',
      queryParameters: queryParams?.isNotEmpty == true ? queryParams : null,
    );
    return RelayFinanceSummary.fromJson(
      Map<String, dynamic>.from(res.data as Map<String, dynamic>),
    );
  }
}

String messageFromDioError(DioException e, ApiClient api) {
  return api.extractError(e);
}
