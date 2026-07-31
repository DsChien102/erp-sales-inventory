import 'dart:async';

import 'package:supabase/supabase.dart';

typedef IamRpcHandler = Future<dynamic> Function(Map<String, dynamic>? params);

/// Schema-limited Supabase fake for IAM RPC adapter tests (no network/auth).
final class FakeIamRpcSupabase implements SupabaseClient {
  final Map<String, IamRpcHandler> _handlers = {};
  final List<({String functionName, Map<String, dynamic>? params})> calls = [];

  void registerHandler(String functionName, IamRpcHandler handler) {
    _handlers[functionName] = handler;
  }

  @override
  GoTrueClient get auth => _FakeGoTrueClient();

  @override
  SupabaseQuerySchema schema(String schema) {
    if (schema != 'iam') {
      throw UnsupportedError('Only iam schema is supported.');
    }
    return _FakeIamQuerySchema(this);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

final class _FakeGoTrueClient implements GoTrueClient {
  @override
  User? get currentUser => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

final class _FakeIamQuerySchema implements SupabaseQuerySchema {
  _FakeIamQuerySchema(this.client);

  final FakeIamRpcSupabase client;

  @override
  PostgrestFilterBuilder<T> rpc<T>(
    String fn, {
    Map<String, dynamic>? params,
    bool get = false,
  }) => _FakePostgrestRpc<T>(client, fn, params);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

final class _FakePostgrestRpc<T> implements PostgrestFilterBuilder<T> {
  _FakePostgrestRpc(this.client, this.functionName, this.params);

  final FakeIamRpcSupabase client;
  final String functionName;
  final Map<String, dynamic>? params;

  @override
  Stream<T> asStream() => throw UnsupportedError('stream not supported');

  @override
  Future<R> then<R>(
    FutureOr<R> Function(T value) onValue, {
    Function? onError,
  }) => _execute().then(onValue, onError: onError);

  Future<T> _execute() async {
    client.calls.add((functionName: functionName, params: params));
    final handler = client._handlers[functionName];
    if (handler == null) {
      return <String, dynamic>{} as T;
    }
    return await handler(params) as T;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
