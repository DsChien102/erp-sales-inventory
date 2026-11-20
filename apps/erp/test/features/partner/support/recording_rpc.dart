import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';

class _UnusedClient extends Fake implements SupabaseClient {}

/// Một lời gọi RPC đã ghi.
final class RpcCall {
  const RpcCall(this.schema, this.fn, this.params);

  final String schema;
  final String fn;
  final Map<String, dynamic>? params;
}

/// `SupabaseRpc` ghi lại lời gọi, trả kết quả / ném lỗi do test đưa vào.
/// Lỗi ném ra được đổi sang [AppException] như `SupabaseRpc.call` thật.
final class RecordingRpc extends SupabaseRpc {
  RecordingRpc({this.respond}) : super(_UnusedClient());

  final dynamic Function(String fn, Map<String, dynamic>? params)? respond;
  final calls = <RpcCall>[];

  List<String> get fns => [for (final c in calls) c.fn];

  @override
  Future<dynamic> call(
    String schema,
    String fn, {
    Map<String, dynamic>? params = const {},
  }) async {
    calls.add(RpcCall(schema, fn, params));
    try {
      return respond?.call(fn, params);
    } catch (error, stackTrace) {
      throw AppException.from(error, stackTrace);
    }
  }
}
