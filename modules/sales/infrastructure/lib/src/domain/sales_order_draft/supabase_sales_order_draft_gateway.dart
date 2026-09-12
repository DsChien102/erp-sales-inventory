import 'dart:convert';

import 'package:vet45_sales_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import 'sales_order_draft_rpc_mapper.dart';

final class SupabaseSalesOrderDraftGateway implements ISalesOrderDraftGateway {
  SupabaseSalesOrderDraftGateway({required IRpcClient rpcClient}) : _rpcClient = rpcClient;

  final IRpcClient _rpcClient;

  @override
  Future<SalesOrderDraftDto> save(SaveSalesOrderDraftCommand command) async {
    try {
      final json = await _rpcClient.call(
        'save_sales_order_draft',
        params: SalesOrderDraftRpcMapper.saveParams(command),
      );
      return SalesOrderDraftRpcMapper.draftFromJson(json);
    } on RpcException catch (error) {
      throw _mapSalesRpcError(error);
    } on SalesContractException {
      rethrow;
    } on Object {
      throw _fallbackError;
    }
  }

  @override
  Future<SalesOrderDraftDto> update(UpdateSalesOrderDraftCommand command) async {
    try {
      final json = await _rpcClient.call(
        'update_sales_order_draft',
        params: SalesOrderDraftRpcMapper.updateParams(command),
      );
      return SalesOrderDraftRpcMapper.draftFromJson(json);
    } on RpcException catch (error) {
      throw _mapSalesRpcError(error);
    } on SalesContractException {
      rethrow;
    } on Object {
      throw _fallbackError;
    }
  }

  @override
  Future<SalesOrderDraftDto> cancel(CancelSalesOrderDraftCommand command) async {
    try {
      final json = await _rpcClient.call(
        'cancel_sales_order_draft',
        params: SalesOrderDraftRpcMapper.cancelParams(command),
      );
      return SalesOrderDraftRpcMapper.draftFromJson(json);
    } on RpcException catch (error) {
      throw _mapSalesRpcError(error);
    } on SalesContractException {
      rethrow;
    } on Object {
      throw _fallbackError;
    }
  }

  @override
  Future<SalesOrderDraftForRestoreDto> getForRestore(
    GetSalesOrderDraftForRestoreQuery query,
  ) async {
    try {
      final json = await _rpcClient.call(
        'get_sales_order_draft_for_restore',
        params: SalesOrderDraftRpcMapper.restoreParams(query),
      );
      return SalesOrderDraftRpcMapper.restoreFromJson(json);
    } on RpcException catch (error) {
      throw _mapSalesRpcError(error);
    } on SalesContractException {
      rethrow;
    } on Object {
      throw _fallbackError;
    }
  }

  @override
  Future<PagedSalesOrderDraftListDto> list(ListSalesOrderDraftsQuery query) async {
    try {
      final json = await _rpcClient.call(
        'list_sales_order_drafts',
        params: SalesOrderDraftRpcMapper.listParams(query),
      );
      return SalesOrderDraftRpcMapper.pageFromJson(json);
    } on RpcException catch (error) {
      throw _mapSalesRpcError(error);
    } on SalesContractException {
      rethrow;
    } on Object {
      throw _fallbackError;
    }
  }

  static SalesContractException _mapSalesRpcError(RpcException error) {
    final envelope = _extractEnvelope(error.message);
    if (envelope != null) {
      final code = envelope['code'];
      if (code is String && _stableCodes.contains(code)) {
        final details = envelope['details'];
        return SalesContractException(
          code,
          message: envelope['message'] as String?,
          details: details is Map ? details.cast<String, Object?>() : const {},
        );
      }
    }
    return _fallbackError;
  }

  /// Unwraps direct JSON envelopes and nested PostgREST `message` JSON payloads.
  static Map<String, dynamic>? _extractEnvelope(String raw) {
    Object? current = raw;
    for (var depth = 0; depth < 3; depth++) {
      if (current is String) {
        final trimmed = current.trim();
        if (trimmed.isEmpty) return null;
        try {
          current = jsonDecode(trimmed);
        } on Object {
          return null;
        }
      }
      if (current is Map) {
        final envelope = current.cast<String, dynamic>();
        final code = envelope['code'];
        if (code is String && _stableCodes.contains(code)) {
          return envelope;
        }
        final nested = envelope['message'];
        if (nested is String) {
          current = nested;
          continue;
        }
        return null;
      }
      return null;
    }
    return null;
  }

  static const _fallbackError = SalesContractException(
    'CONTEXT_INVALID',
    message: 'Sales draft operation failed.',
  );

  static const _stableCodes = <String>{
    'PERMISSION_DENIED',
    'DATA_SCOPE_DENIED',
    'CONTEXT_INVALID',
    'REFERENCE_UNAVAILABLE',
    'STALE_DATA',
    'IDEMPOTENCY_CONFLICT',
  };
}
