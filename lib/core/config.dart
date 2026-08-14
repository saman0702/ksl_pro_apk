import 'package:flutter/foundation.dart';

import 'platform_helper_stub.dart'
    if (dart.library.io) 'platform_helper_io.dart' as platform;

class AppConfig {
  static const String localDevHost = '192.168.1.88';
  static const int localDevPort = 3002;

  static String get _apiOrigin {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) {
      return _originFromUrl(fromEnv);
    }

    const useLocalDev =
        // bool.fromEnvironment('USE_LOCAL_DEV', defaultValue: false);
        bool.fromEnvironment('USE_LOCAL_DEV', defaultValue: true);
    if (useLocalDev) {
      return _localOrigin();
    }

    return 'https://testapi.katianlogistique.com';
  }

  static String _localOrigin() {
    if (kIsWeb) {
      return 'http://127.0.0.1:$localDevPort';
    }
    final host = localDevHost.isNotEmpty
        ? localDevHost
        : platform.platformLocalHost();
    return 'http://$host:$localDevPort';
  }

  static String _originFromUrl(String fromEnv) {
    var uri = Uri.parse(fromEnv);
    if (uri.host == '0.0.0.0') {
      final local = Uri.parse(_localOrigin());
      uri = uri.replace(host: local.host, port: local.port);
    }
    final path = uri.path;
    if (path.endsWith('/api/katian-pro/v1')) {
      return uri.replace(path: path.replaceFirst('/api/katian-pro/v1', '')).toString();
    }
    return uri.replace(path: '').toString();
  }

  static String get baseUrl => '$_apiOrigin/api/katian-pro/v1';

  /// Mot de passe initial des comptes convoyeur créés par la gare.
  static const String defaultConvoyeurPassword = 'motdepasse123';

  static String? resolveMediaUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final raw = url.trim();
    try {
      final uri = Uri.parse(raw);
      if (!uri.hasScheme) {
        return resolveMediaUrl('$mediaOrigin$raw');
      }
      const localHosts = {'localhost', '127.0.0.1', '10.0.2.2'};
      final host = uri.host.toLowerCase();
      final isLocalHost = localHosts.contains(host) ||
          host.startsWith('192.168.') ||
          host.startsWith('10.');
      if (isLocalHost) {
        final api = Uri.parse(baseUrl);
        return uri
            .replace(
              scheme: api.scheme,
              host: api.host,
              port: api.hasPort ? api.port : uri.port,
            )
            .toString();
      }
      return raw;
    } catch (_) {
      return raw;
    }
  }

  static String get mediaOrigin {
    final api = Uri.parse(baseUrl);
    return '${api.scheme}://${api.host}${api.hasPort ? ':${api.port}' : ''}';
  }
}
