import 'dart:async';

import 'package:supabase/supabase.dart';

typedef PartnerRpcHandler = Future<dynamic> Function(Map<String, dynamic>? params);

/// Records partner-schema RPC calls and returns canned responses for integration tests.
final class FakePartnerRpcSupabase implements SupabaseClient {
  FakePartnerRpcSupabase({
    Map<String, PartnerRpcHandler>? handlers,
  }) : _handlers = handlers ?? <String, PartnerRpcHandler>{};

  final Map<String, PartnerRpcHandler> _handlers;
  final List<({String functionName, Map<String, dynamic>? params})> calls =
      [];

  void registerHandler(String functionName, PartnerRpcHandler handler) {
    _handlers[functionName] = handler;
  }

  @override
  GoTrueClient get auth => _FakeGoTrueClient();

  @override
  SupabaseQuerySchema schema(String schema) {
    if (schema != 'partner') {
      throw UnsupportedError('FakePartnerRpcSupabase only supports partner schema');
    }
    return _FakePartnerQuerySchema(this);
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

final class _FakePartnerQuerySchema implements SupabaseQuerySchema {
  _FakePartnerQuerySchema(this._client);

  final FakePartnerRpcSupabase _client;

  @override
  PostgrestFilterBuilder<T> rpc<T>(
    String fn, {
    Map<String, dynamic>? params,
    bool get = false,
  }) {
    return _FakePostgrestRpc<T>(_client, fn, params);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

final class _FakePostgrestRpc<T> implements PostgrestFilterBuilder<T> {
  _FakePostgrestRpc(this._client, this._functionName, this._params);

  final FakePartnerRpcSupabase _client;
  final String _functionName;
  final Map<String, dynamic>? _params;

  @override
  Stream<T> asStream() {
    throw UnsupportedError('stream not supported');
  }

  @override
  Future<R> then<R>(
    FutureOr<R> Function(T value) onValue, {
    Function? onError,
  }) {
    return _execute().then(onValue, onError: onError);
  }

  Future<T> _execute() async {
    _client.calls.add((functionName: _functionName, params: _params));
    final handler = _client._handlers[_functionName];
    if (handler == null) {
      return <dynamic>[] as T;
    }
    final result = await handler(_params);
    return result as T;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
