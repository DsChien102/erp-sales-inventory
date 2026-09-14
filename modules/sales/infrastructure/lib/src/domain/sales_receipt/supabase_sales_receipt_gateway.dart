import 'dart:convert';

import 'package:vet45_sales_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import 'sales_receipt_rpc_mapper.dart';

final class SupabaseSalesReceiptGateway implements ISalesReceiptGateway {
  SupabaseSalesReceiptGateway({required IRpcClient rpcClient}) : _rpcClient = rpcClient;

  final IRpcClient _rpcClient;

  @override
  Future<SalesReceiptDto> generate(GenerateSalesReceiptCommand command) {
    return _call('generate_sales_receipt', SalesReceiptRpcMapper.generateParams(command));
  }

  @override
  Future<SalesReceiptDto> recordPrinted(RecordSalesReceiptPrintedCommand command) {
    return _call(
      'record_sales_receipt_activity',
      SalesReceiptRpcMapper.printedParams(command),
    );
  }

  @override
  Future<SalesReceiptDto> recordShared(RecordSalesReceiptSharedCommand command) {
    return _call(
      'record_sales_receipt_activity',
      SalesReceiptRpcMapper.sharedParams(command),
    );
  }

  @override
  Future<SalesReceiptDto> archive(ArchiveSalesReceiptCommand command) {
    return _call(
      'record_sales_receipt_activity',
      SalesReceiptRpcMapper.archiveParams(command),
    );
  }

  @override
  Future<SalesReceiptDto> getReceipt(GetSalesReceiptQuery query) {
    return _call('get_sales_receipt', SalesReceiptRpcMapper.getReceiptParams(query));
  }

  Future<SalesReceiptDto> _call(String procedure, Map<String, dynamic> params) async {
    try {
      final json = await _rpcClient.call(procedure, params: params);
      return SalesReceiptRpcMapper.salesReceiptFromJson(json);
    } on RpcException catch (error) {
      throw _mapSalesRpcError(error);
    } on SalesContractException {
      rethrow;
    } on FormatException {
      throw const SalesContractException(
        'DEPENDENCY_UNAVAILABLE',
        message: 'Sales receipt operation failed.',
      );
    } on Object {
      throw const SalesContractException(
        'DEPENDENCY_UNAVAILABLE',
        message: 'Sales receipt operation failed.',
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
        message: 'Sales receipt operation failed.',
      );
    }
    return const SalesContractException(
      'DEPENDENCY_UNAVAILABLE',
      message: 'Sales receipt operation failed.',
    );
  }

  static const _stableCodes = <String>{
    'NOT_FOUND',
    'PERMISSION_DENIED',
    'PROJECTION_PENDING',
    'DATA_SCOPE_DENIED',
    'STALE_VERSION',
    'IDEMPOTENCY_CONFLICT',
    'DEPENDENCY_UNAVAILABLE',
    'CONTEXT_INVALID',
  };
}
