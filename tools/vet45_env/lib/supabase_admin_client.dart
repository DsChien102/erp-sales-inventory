import 'dart:convert';
import 'dart:io';

/// Thin HTTP surface for Supabase Auth Admin + PostgREST (injectable in tests).
abstract interface class SupabaseAdminHttp {
  Future<SupabaseAdminHttpResponse> send({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    String? body,
  });

  /// Release underlying resources (e.g. keep-alive sockets) so CLI can exit.
  void close();
}

final class SupabaseAdminHttpResponse {
  const SupabaseAdminHttpResponse({
    required this.statusCode,
    required this.body,
  });

  final int statusCode;
  final String body;

  Map<String, dynamic>? get jsonObject {
    if (body.trim().isEmpty) return null;
    final decoded = jsonDecode(body);
    return decoded is Map<String, dynamic> ? decoded : null;
  }

  List<dynamic>? get jsonList {
    if (body.trim().isEmpty) return null;
    final decoded = jsonDecode(body);
    return decoded is List<dynamic> ? decoded : null;
  }
}

/// Real [HttpClient]-backed implementation.
final class DartSupabaseAdminHttp implements SupabaseAdminHttp {
  DartSupabaseAdminHttp({HttpClient? client})
      : _ownsClient = client == null,
        _client = client ?? HttpClient();

  final HttpClient _client;
  final bool _ownsClient;

  @override
  Future<SupabaseAdminHttpResponse> send({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    String? body,
  }) async {
    final request = await _client.openUrl(method, uri);
    headers.forEach(request.headers.set);
    // Avoid keep-alive linger that blocks Dart process exit in CLI.
    request.headers.set(HttpHeaders.connectionHeader, 'close');
    if (body != null) {
      final bytes = utf8.encode(body);
      request.contentLength = bytes.length;
      request.add(bytes);
    }
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    return SupabaseAdminHttpResponse(
      statusCode: response.statusCode,
      body: responseBody,
    );
  }

  @override
  void close() {
    if (_ownsClient) {
      _client.close(force: true);
    }
  }
}

/// Auth Admin + Rest helpers for platform admin bootstrap.
final class SupabaseAdminClient {
  SupabaseAdminClient({
    required this.baseUrl,
    required this.serviceRoleKey,
    SupabaseAdminHttp? http,
  })  : _ownsHttp = http == null,
        _http = http ?? DartSupabaseAdminHttp();

  final String baseUrl;
  final String serviceRoleKey;
  final SupabaseAdminHttp _http;
  final bool _ownsHttp;

  /// Closes owned HTTP client so keep-alive sockets do not block process exit.
  void close() {
    if (_ownsHttp) {
      _http.close();
    }
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final root = baseUrl.replaceAll(RegExp(r'/$'), '');
    final uri = Uri.parse('$root$path');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(queryParameters: query);
  }

  Map<String, String> get _authHeaders => {
    'apikey': serviceRoleKey,
    'Authorization': 'Bearer $serviceRoleKey',
    'Content-Type': 'application/json',
  };

  Map<String, String> get _restHeaders => {
    ..._authHeaders,
    'Accept-Profile': 'iam',
    'Content-Profile': 'iam',
  };

  /// Creates a confirmed user. Returns null user id if email already exists.
  Future<({String? userId, bool created})> createUser({
    required String email,
    required String password,
  }) async {
    final response = await _http.send(
      method: 'POST',
      uri: _uri('/auth/v1/admin/users'),
      headers: _authHeaders,
      body: jsonEncode({
        'email': email,
        'password': password,
        'email_confirm': true,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final id = response.jsonObject?['id'] as String?;
      if (id == null || id.isEmpty) {
        throw StateError('Auth Admin createUser: missing id in response');
      }
      return (userId: id, created: true);
    }

    if (_isEmailExists(response)) {
      return (userId: null, created: false);
    }

    throw StateError(
      'Auth Admin createUser failed (${response.statusCode}): ${response.body}',
    );
  }

  Future<String?> findUserIdByEmail(String email) async {
    final normalized = email.trim().toLowerCase();
    final response = await _http.send(
      method: 'GET',
      uri: _uri('/auth/v1/admin/users', {'page': '1', 'per_page': '200'}),
      headers: _authHeaders,
    );

    if (response.statusCode != 200) {
      throw StateError(
        'Auth Admin listUsers failed (${response.statusCode}): ${response.body}',
      );
    }

    final users = response.jsonObject?['users'] as List<dynamic>? ??
        response.jsonList ??
        const [];
    for (final raw in users) {
      if (raw is! Map<String, dynamic>) continue;
      final userEmail = (raw['email'] as String?)?.trim().toLowerCase() ?? '';
      if (userEmail == normalized) {
        return raw['id'] as String?;
      }
    }
    return null;
  }

  Future<bool> grantPlatformAdmin(String userId) async {
    final response = await _http.send(
      method: 'POST',
      uri: _uri('/rest/v1/platform_admins'),
      headers: {
        ..._restHeaders,
        'Prefer': 'resolution=merge-duplicates,return=representation',
      },
      body: jsonEncode({'user_id': userId}),
    );

    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 409) {
      return true;
    }

    throw StateError(
      'Grant platform_admins failed (${response.statusCode}): ${response.body}',
    );
  }

  Future<List<Map<String, dynamic>>> listPlatformAdmins() async {
    final response = await _http.send(
      method: 'GET',
      uri: _uri('/rest/v1/platform_admins', {
        'select': 'user_id,created_at',
        'order': 'created_at.asc',
      }),
      headers: _restHeaders,
    );

    if (response.statusCode != 200) {
      throw StateError(
        'List platform_admins failed (${response.statusCode}): ${response.body}',
      );
    }

    final list = response.jsonList ?? const [];
    return list.whereType<Map<String, dynamic>>().toList();
  }

  bool _isEmailExists(SupabaseAdminHttpResponse response) {
    final body = response.body.toLowerCase();
    if (response.statusCode == 422 || response.statusCode == 400) {
      return body.contains('already') ||
          body.contains('email_exists') ||
          body.contains('user_already_exists') ||
          body.contains('duplicate');
    }
    return false;
  }
}
