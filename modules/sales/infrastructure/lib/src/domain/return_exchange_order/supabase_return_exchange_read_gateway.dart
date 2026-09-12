import 'dart:convert';

import 'package:vet45_sales_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import 'return_exchange_rpc_mapper.dart';

final class SupabaseReturnExchangeReadGateway implements IReturnExchangeReadGateway {
  SupabaseReturnExchangeReadGateway({required IRpcClient rpcClient}) : _rpcClient = rpcClient;

  final IRpcClient _rpcClient;

  @override
  Future<ReturnExchangePrecheckDto> precheck(PrecheckReturnExchangeQuery query) {
    return _call(
      'precheck_return_exchange',
      ReturnExchangeRpcMapper.precheckParams(query),
      ReturnExchangeRpcMapper.precheckFromJson,
    );
  }

  @override
  Future<ReturnableOrderLinesDto> getReturnableLines(GetReturnableOrderLinesQuery query) {
    return _call(
      'get_returnable_order_lines',
      ReturnExchangeRpcMapper.getReturnableParams(query),
      ReturnExchangeRpcMapper.returnableFromJson,
    );
  }

  @override
  Future<ReturnExchangeFormPolicyDto> getFormPolicy(
    GetReturnExchangeFormPolicyQuery query,
  ) {
    return _call(
      'get_return_exchange_form_policy',
      ReturnExchangeRpcMapper.formPolicyParams(query),
      ReturnExchangeRpcMapper.formPolicyFromJson,
    );
  }

  @override
  Future<ReturnExchangeDetailDto> getDetail(GetReturnExchangeDetailQuery query) {
    return _call(
      'get_return_exchange_detail',
      ReturnExchangeRpcMapper.detailParams(query),
      ReturnExchangeRpcMapper.detailFromJson,
    );
  }

  @override
  Future<ReturnExchangeContext> getContext({
    required String tenantId,
    required String actorId,
    required String returnExchangeId,
  }) {
    return _call(
      '_get_return_exchange_context',
      ReturnExchangeRpcMapper.contextParams(
        tenantId: tenantId,
        actorId: actorId,
        returnExchangeId: returnExchangeId,
      ),
      ReturnExchangeRpcMapper.contextFromJson,
    );
  }

  @override
  Future<ReturnExchangeValuationDto> evaluate(
    EvaluateReturnPricingImpactQuery query, {
    required ReturnExchangeReferenceDecision referenceDecision,
  }) {
    return _call(
      'evaluate_return_exchange_valuation',
      ReturnExchangeRpcMapper.evaluateParams(
        query,
        referenceDecision: referenceDecision,
      ),
      ReturnExchangeRpcMapper.valuationFromJson,
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
    } on Object catch (error) {
      throw SalesContractException(
        'DEPENDENCY_UNAVAILABLE',
        message: 'Return/exchange read mapper failed: $error',
        details: <String, Object?>{'readMessage': error.toString()},
      );
    }
  }

  static SalesContractException _mapSalesRpcError(RpcException error) {
    try {
      final decoded = jsonDecode(error.message);
      if (decoded is Map) {
        final envelope = decoded.cast<String, dynamic>();
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
    } on Object {
      return _fallbackError;
    }
    return _fallbackError;
  }

  static const _fallbackError = SalesContractException(
    'DEPENDENCY_UNAVAILABLE',
    message: 'Sales return/exchange read failed.',
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
