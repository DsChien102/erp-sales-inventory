import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/einvoice_error_mapper.dart';
import 'issuance_rpc_mapper.dart';

final class SupabaseAutoIssuanceGateway implements IAutoIssuanceGateway {
  SupabaseAutoIssuanceGateway({required SupabaseSchemaRpcClient rpcClient})
    : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<AutoIssuanceResultDto> start(AutoIssuanceStartRequest request) async {
    try {
      final rows = await _rpcClient.callList(
        'start_auto_issuance',
        params: IssuanceRpcMapper.startAutoIssuanceParams(request),
      );
      if (rows.isEmpty) {
        throw RpcException('start_auto_issuance returned no rows');
      }
      return IssuanceRpcMapper.autoIssuanceResultFromRow(
        Map<String, dynamic>.from(rows.first),
      );
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }

  @override
  Future<AutoIssuanceResultDto> reevaluate(
    AutoIssuanceReevaluationRequest request,
  ) async {
    try {
      final rows = await _rpcClient.callList(
        'reevaluate_auto_issuance',
        params: IssuanceRpcMapper.reevaluateAutoIssuanceParams(request),
      );
      if (rows.isEmpty) {
        throw RpcException('reevaluate_auto_issuance returned no rows');
      }
      return IssuanceRpcMapper.autoIssuanceResultFromRow(
        Map<String, dynamic>.from(rows.first),
      );
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }

  @override
  Future<List<OpenAutoIssuanceProcessDto>> listOpenProcesses({
    required String tenantId,
    required String partnerId,
  }) async {
    try {
      final rows = await _rpcClient.callList(
        'list_open_auto_issuance_processes',
        params: IssuanceRpcMapper.listOpenAutoIssuanceProcessesParams(
          tenantId: tenantId,
          partnerId: partnerId,
        ),
      );
      return rows
          .map(
            (row) => IssuanceRpcMapper.openAutoIssuanceProcessFromRow(
              Map<String, dynamic>.from(row),
            ),
          )
          .toList(growable: false);
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }
}
