import 'dart:convert';

import 'package:vet45_sales_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import 'return_exchange_rpc_mapper.dart';

final class SupabaseReturnExchangeCommandGateway implements IReturnExchangeCommandGateway {
  SupabaseReturnExchangeCommandGateway({required IRpcClient rpcClient}) : _rpcClient = rpcClient;

  final IRpcClient _rpcClient;

  @override
  Future<ReturnExchangeDraftDto> start(
    StartReturnExchangeCommand command, {
    required ReturnExchangeReferenceDecision referenceDecision,
  }) {
    return _call(
      'start_return_exchange',
      ReturnExchangeRpcMapper.startParams(command, referenceDecision: referenceDecision),
      ReturnExchangeRpcMapper.draftFromJson,
    );
  }

  @override
  Future<ReturnExchangeDraftDto> update(
    UpdateReturnExchangeCommand command, {
    required ReturnExchangeReferenceDecision referenceDecision,
  }) {
    return _call(
      'update_return_exchange',
      ReturnExchangeRpcMapper.updateParams(command, referenceDecision: referenceDecision),
      ReturnExchangeRpcMapper.draftFromJson,
    );
  }

  @override
  Future<ReturnExchangeResultDto> cancel(CancelReturnExchangeCommand command) {
    return _call(
      'cancel_return_exchange',
      ReturnExchangeRpcMapper.cancelParams(command),
      ReturnExchangeRpcMapper.resultFromJson,
    );
  }

  @override
  Future<ReturnExchangeResultDto> confirm(
    ConfirmReturnExchangeCommand command, {
    required ReturnExchangeReferenceDecision referenceDecision,
  }) {
    return _call(
      'confirm_return_exchange',
      ReturnExchangeRpcMapper.confirmParams(command, referenceDecision: referenceDecision),
      ReturnExchangeRpcMapper.resultFromJson,
    );
  }

  @override
  Future<ReturnExchangeResultDto> complete(CompleteReturnExchangeCommand command) {
    return _call(
      'complete_return_exchange',
      ReturnExchangeRpcMapper.completeParams(command),
      ReturnExchangeRpcMapper.resultFromJson,
    );
  }

  Future<T> _call<T>(
    String procedure,
    Map<String, dynamic> params,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final json = await _rpcClient.call(procedure, params: params);
      return fromJson(json);
    } on RpcException catch (error) {
      throw _mapSalesRpcError(error);
    } on SalesContractException {
      rethrow;
    } on Object {
      throw _fallbackError();
    }
  }

  static SalesContractException _mapSalesRpcError(RpcException error) {
    try {
      final raw = error.message;
      final start = raw.indexOf('{');
      final end = raw.lastIndexOf('}');
      final jsonStr = (start != -1 && end != -1 && end > start)
          ? raw.substring(start, end + 1)
          : raw;
      final decoded = jsonDecode(jsonStr);
      if (decoded is Map) {
        final envelope = decoded.cast<String, dynamic>();
        final code = envelope['code'];
        final message = envelope['message'] as String?;
        if (code is String && _stableCodes.contains(code)) {
          final details = envelope['details'];
          return SalesContractException(
            code,
            message: message,
            details: details is Map ? details.cast<String, Object?>() : const {},
          );
        }
        if (message != null && message.isNotEmpty) {
          return SalesContractException(
            code is String ? code : 'DEPENDENCY_UNAVAILABLE',
            message: message,
          );
        }
      }
    } on Object {
      return _fallbackError(error);
    }
    return _fallbackError(error);
  }

  static SalesContractException _fallbackError([RpcException? error]) => SalesContractException(
    'DEPENDENCY_UNAVAILABLE',
    message: error != null && error.message.isNotEmpty
        ? error.message
        : 'Sales return/exchange operation failed.',
    details: error == null
        ? const <String, Object?>{}
        : <String, Object?>{'rpcMessage': error.message},
  );

  static const _stableCodes = <String>{
    'NOT_FOUND',
    'PERMISSION_DENIED',
    'DATA_SCOPE_DENIED',
    'RETURN_EXCHANGE_BLOCKED',
    'RETURN_QUANTITY_EXCEEDED',
    'STALE_VERSION',
    'IDEMPOTENCY_CONFLICT',
    'IMPACT_PENDING',
    'DEPENDENCY_UNAVAILABLE',
  };
}
