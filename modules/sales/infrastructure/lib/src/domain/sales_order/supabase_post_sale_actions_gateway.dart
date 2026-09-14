import 'dart:convert';

import 'package:vet45_sales_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import 'post_sale_actions_rpc_mapper.dart';

final class SupabasePostSaleActionsGateway implements IPostSaleActionsGateway {
  SupabasePostSaleActionsGateway({required IRpcClient rpcClient}) : _rpcClient = rpcClient;

  final IRpcClient _rpcClient;

  @override
  Future<AvailablePostSaleActionsDto> getAvailableActions(
    GetAvailablePostSaleActionsQuery query,
  ) {
    return _call(
      'get_available_post_sale_actions',
      PostSaleActionsRpcMapper.availableActionsParams(query),
      PostSaleActionsRpcMapper.availableActionsFromJson,
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
      throw const SalesContractException(
        'DEPENDENCY_UNAVAILABLE',
        message: 'Sales post-sale actions read failed.',
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
      return const SalesContractException(
        'DEPENDENCY_UNAVAILABLE',
        message: 'Sales post-sale actions read failed.',
      );
    }
    return const SalesContractException(
      'DEPENDENCY_UNAVAILABLE',
      message: 'Sales post-sale actions read failed.',
    );
  }

  static const _stableCodes = <String>{
    'NOT_FOUND',
    'PERMISSION_DENIED',
    'PROJECTION_PENDING',
    'DATA_SCOPE_DENIED',
    'DEPENDENCY_UNAVAILABLE',
    'STALE_VERSION',
  };
}
