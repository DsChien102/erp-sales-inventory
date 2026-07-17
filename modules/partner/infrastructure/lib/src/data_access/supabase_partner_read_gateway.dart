import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../errors/partner_error_mapper.dart';
import 'partner_read_rpc_mapper.dart';

final class SupabasePartnerReadGateway
    implements IPartnerReadGateway, IPartnerHistoryReadGateway {
  SupabasePartnerReadGateway({required SupabaseSchemaRpcClient rpcClient})
    : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<PartnerSearchResultDto> searchPartners(
    SearchPartnersQuery query,
  ) async {
    try {
      final result = await _callFirstRow(
        'search_partners',
        params: PartnerReadRpcMapper.searchParams(query),
      );
      return PartnerReadRpcMapper.mapSearchResult(result);
    } on RpcException catch (error) {
      throw mapPartnerRpcError(error);
    }
  }

  @override
  Future<PartnerDetailDto> getPartnerDetail(GetPartnerDetailQuery query) async {
    try {
      final result = await _rpcClient.callMap(
        'get_partner_detail',
        params: PartnerReadRpcMapper.detailParams(query),
      );
      return PartnerReadRpcMapper.mapDetailResult(result);
    } on RpcException catch (error) {
      throw mapPartnerRpcError(error);
    }
  }

  @override
  Future<DeleteEligibilityDto> checkDeleteEligibility(
    CheckDeleteEligibilityQuery query,
  ) async {
    try {
      final result = await _callFirstRow(
        'check_delete_eligibility',
        params: PartnerReadRpcMapper.deleteEligibilityParams(query),
      );
      return PartnerReadRpcMapper.mapDeleteEligibility(result);
    } on RpcException catch (error) {
      throw mapPartnerRpcError(error);
    }
  }

  @override
  Future<PartnerHistoryResultDto> getPartnerHistory(
    GetPartnerHistoryQuery query,
  ) async {
    try {
      final result = await _callFirstRow(
        'get_partner_history',
        params: PartnerReadRpcMapper.historyParams(query),
      );
      return PartnerReadRpcMapper.mapHistoryResult(result);
    } on RpcException catch (error) {
      throw mapPartnerRpcError(error);
    }
  }

  @override
  Future<PartnerActionLogResultDto> getPartnerActionLogs(
    GetPartnerActionLogsQuery query,
  ) async {
    try {
      final result = await _callFirstRow(
        'get_partner_action_logs',
        params: PartnerReadRpcMapper.actionLogsParams(query),
      );
      return PartnerReadRpcMapper.mapActionLogsResult(result);
    } on RpcException catch (error) {
      throw mapPartnerRpcError(error);
    }
  }

  /// Read RPCs that `returns table (...)` come back from PostgREST as a JSON array.
  Future<Map<String, dynamic>> _callFirstRow(
    String functionName, {
    Map<String, dynamic>? params,
  }) async {
    final rows = await _rpcClient.callList(functionName, params: params);
    if (rows.isEmpty) {
      return <String, dynamic>{};
    }
    return rows.first;
  }
}

final class SupabasePartnerDuplicateChecker implements IPartnerDuplicateChecker {
  SupabasePartnerDuplicateChecker({required SupabaseSchemaRpcClient rpcClient})
    : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<List<PartnerDuplicateMatchDto>> checkDuplicates(
    CheckDuplicatePartnersQuery query,
  ) async {
    try {
      final rows = await _rpcClient.callList(
        'check_duplicate',
        params: PartnerReadRpcMapper.duplicateParams(query),
      );
      return PartnerReadRpcMapper.mapDuplicateMatches(rows);
    } on RpcException catch (error) {
      throw mapPartnerRpcError(error);
    }
  }
}

final class SupabasePartnerHistoryWriteGateway
    implements IPartnerHistoryWriteGateway {
  SupabasePartnerHistoryWriteGateway({
    required SupabaseSchemaRpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<void> upsertPartnerHistory(RecordPartnerHistoryCommand command) async {
    try {
      await _rpcClient.callScalar<void>(
        'upsert_partner_history',
        params: PartnerReadRpcMapper.recordHistoryParams(command),
      );
    } on RpcException catch (error) {
      throw mapPartnerRpcError(error);
    }
  }
}
