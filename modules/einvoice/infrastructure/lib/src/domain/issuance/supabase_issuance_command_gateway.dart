import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/einvoice_error_mapper.dart';
import 'issuance_rpc_mapper.dart';

final class SupabaseIssuanceCommandGateway implements IIssuanceCommandGateway {
  SupabaseIssuanceCommandGateway({required SupabaseSchemaRpcClient rpcClient})
    : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<IssueInvoiceResultDto> issueInvoice(
    IssueInvoiceStartRequest request,
  ) async {
    try {
      final rows = await _rpcClient.callList(
        'issue_invoice',
        params: IssuanceRpcMapper.issueInvoiceParams(request),
      );
      if (rows.isEmpty) {
        throw RpcException('issue_invoice returned no rows');
      }
      return IssuanceRpcMapper.issueInvoiceResultFromRow(
        Map<String, dynamic>.from(rows.first),
      );
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }

  @override
  Future<IssueInvoiceResultDto> retryIssuance(
    RetryIssuanceStartRequest request,
  ) async {
    try {
      final rows = await _rpcClient.callList(
        'retry_issuance',
        params: IssuanceRpcMapper.retryIssuanceParams(request),
      );
      if (rows.isEmpty) {
        throw RpcException('retry_issuance returned no rows');
      }
      return IssuanceRpcMapper.issueInvoiceResultFromRow(
        Map<String, dynamic>.from(rows.first),
      );
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }
}
