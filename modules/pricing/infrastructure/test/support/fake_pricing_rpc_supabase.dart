import 'dart:async';

import 'package:supabase/supabase.dart';

typedef PricingRpcHandler =
    Future<dynamic> Function(Map<String, dynamic>? params);

final class FakePricingRpcSupabase implements SupabaseClient {
  final Map<String, PricingRpcHandler> _handlers = {};
  final List<({String functionName, Map<String, dynamic>? params})> calls = [];

  void registerHandler(String functionName, PricingRpcHandler handler) {
    _handlers[functionName] = handler;
  }

  @override
  GoTrueClient get auth => _FakeGoTrueClient();

  @override
  SupabaseQuerySchema schema(String schema) {
    if (schema != 'pricing') {
      throw UnsupportedError('Only pricing schema is supported.');
    }
    return _FakePricingQuerySchema(this);
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

final class _FakePricingQuerySchema implements SupabaseQuerySchema {
  _FakePricingQuerySchema(this.client);

  final FakePricingRpcSupabase client;

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

  final FakePricingRpcSupabase client;
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
