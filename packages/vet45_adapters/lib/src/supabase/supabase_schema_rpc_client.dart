import 'package:supabase/supabase.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import 'postgrest_error_parser.dart';

final class SupabaseSchemaRpcClient {
  SupabaseSchemaRpcClient({
    required SupabaseClient supabase,
    required PostgrestErrorMapperFn mapError,
    ILogger? logger,
    String schema = 'public',
  }) : _supabase = supabase,
       _mapError = mapError,
       _logger = logger,
       _schema = schema;

  final SupabaseClient _supabase;
  final PostgrestErrorMapperFn _mapError;
  final ILogger? _logger;
  final String _schema;

  Future<dynamic> _rpc(
    String functionName, {
    Map<String, dynamic>? params,
  }) {
    if (_schema == 'public') {
      return _supabase.rpc(functionName, params: params ?? <String, dynamic>{});
    }
    return _supabase
        .schema(_schema)
        .rpc(
          functionName,
          params: params ?? <String, dynamic>{},
        );
  }

  Future<Map<String, dynamic>> callMap(
    String functionName, {
    Map<String, dynamic>? params,
  }) async {
    final stopwatch = Stopwatch()..start();
    _logger?.fine('RPC start schema=$_schema fn=$functionName');

    try {
      final result = await _rpc(functionName, params: params);
      if (result == null) {
        _logger?.fine(
          'RPC success fn=$functionName elapsedMs=${stopwatch.elapsedMilliseconds}',
        );
        return <String, dynamic>{};
      }

      _logger?.fine(
        'RPC success fn=$functionName elapsedMs=${stopwatch.elapsedMilliseconds}',
      );
      return Map<String, dynamic>.from(result as Map);
    } catch (error, stackTrace) {
      _logger?.severe(
        'RPC failed fn=$functionName elapsedMs=${stopwatch.elapsedMilliseconds}',
        error,
        stackTrace,
      );
      throw _mapError(error, stackTrace);
    }
  }

  Future<List<Map<String, dynamic>>> callList(
    String functionName, {
    Map<String, dynamic>? params,
  }) async {
    final stopwatch = Stopwatch()..start();
    _logger?.fine('RPC list start schema=$_schema fn=$functionName');

    try {
      final result = await _rpc(functionName, params: params);
      if (result == null) {
        return const [];
      }

      if (result is List<dynamic>) {
        _logger?.fine(
          'RPC list success fn=$functionName rows=${result.length} '
          'elapsedMs=${stopwatch.elapsedMilliseconds}',
        );
        return result.map((item) => Map<String, dynamic>.from(item as Map)).toList();
      }

      if (result is Map<String, dynamic>) {
        return [result];
      }

      return const [];
    } catch (error, stackTrace) {
      _logger?.severe(
        'RPC list failed fn=$functionName elapsedMs=${stopwatch.elapsedMilliseconds}',
        error,
        stackTrace,
      );
      throw _mapError(error, stackTrace);
    }
  }

  Future<T?> callScalar<T>(
    String functionName, {
    Map<String, dynamic>? params,
  }) async {
    final stopwatch = Stopwatch()..start();
    _logger?.fine('RPC scalar start schema=$_schema fn=$functionName');

    try {
      final result = await _rpc(functionName, params: params);
      _logger?.fine(
        'RPC scalar success fn=$functionName elapsedMs=${stopwatch.elapsedMilliseconds}',
      );
      return result as T?;
    } catch (error, stackTrace) {
      _logger?.severe(
        'RPC scalar failed fn=$functionName elapsedMs=${stopwatch.elapsedMilliseconds}',
        error,
        stackTrace,
      );
      throw _mapError(error, stackTrace);
    }
  }
}
