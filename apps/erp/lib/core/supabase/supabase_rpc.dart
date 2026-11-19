import 'package:supabase/supabase.dart';
import 'package:c45_shared_application/application.dart';

import '../errors/app_exception.dart';

/// Một chỗ gọi RPC cho mọi repository: `schema(x).rpc(fn)`, đổi lỗi sang
/// [AppException], và phát tín hiệu tổ chức bị tạm ngừng như client cũ.
class SupabaseRpc {
  SupabaseRpc(this._client);

  final SupabaseClient _client;

  /// Gọi RPC; mọi lỗi thành [AppException].
  /// [params] `null` nghĩa là gọi RPC không gửi object tham số
  /// (`get_tenant_context` khi chưa có tenant).
  Future<dynamic> call(
    String schema,
    String fn, {
    Map<String, dynamic>? params = const {},
  }) async {
    try {
      if (schema == 'public') {
        return await _client.rpc(fn, params: params);
      }
      return await _client.schema(schema).rpc(fn, params: params);
    } catch (error, stackTrace) {
      TenantAccessRevokedSignal.notifyFromError(error);
      throw AppException.from(error, stackTrace);
    }
  }

  /// RPC `returns table` / `setof` → danh sách dòng (null → rỗng, 1 object → [object]).
  Future<List<Map<String, dynamic>>> rows(
    String schema,
    String fn, {
    Map<String, dynamic>? params = const {},
  }) async {
    final result = await call(schema, fn, params: params);
    if (result == null) return const [];
    if (result is List) {
      return result
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
    }
    if (result is Map) {
      return [Map<String, dynamic>.from(result)];
    }
    return const [];
  }

  /// Dòng đầu; không có dòng → [AppException] `NOT_FOUND`.
  Future<Map<String, dynamic>> firstRow(
    String schema,
    String fn, {
    Map<String, dynamic>? params = const {},
  }) async {
    final list = await rows(schema, fn, params: params);
    if (list.isEmpty) {
      throw const AppException(AppErrorCode.notFound);
    }
    return list.first;
  }
}
