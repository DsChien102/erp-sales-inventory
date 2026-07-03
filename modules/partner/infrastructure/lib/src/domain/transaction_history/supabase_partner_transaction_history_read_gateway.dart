import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/partner_error_mapper.dart';
import 'partner_transaction_history_mapper.dart';

final class SupabasePartnerTransactionHistoryReadGateway
    implements IPartnerTransactionHistoryReadGateway {
  SupabasePartnerTransactionHistoryReadGateway({
    required SupabaseSchemaRpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<PartnerTransactionHistoryResultDto> list({
    required String tenantId,
    required String partnerId,
    required PartnerTransactionHistoryCriteria criteria,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final rows = await _rpcClient.callList(
        'get_partner_transaction_history',
        params: <String, dynamic>{
          'p_tenant_id': tenantId,
          'p_partner_id': partnerId,
          'p_keyword': criteria.keyword,
          'p_transaction_types': criteria.transactionTypes?.toList(
            growable: false,
          ),
          'p_transaction_role': criteria.transactionRole?.name,
          'p_from': criteria.from?.toUtc().toIso8601String(),
          'p_to': criteria.to?.toUtc().toIso8601String(),
          'p_limit': limit,
          'p_offset': offset,
        },
      );

      if (rows.isEmpty) {
        return const PartnerTransactionHistoryResultDto(
          items: [],
          totalCount: 0,
        );
      }

      final totalCount =
          (rows.first['total_count'] as num?)?.toInt() ?? rows.length;
      final items = rows
          .map(PartnerTransactionHistoryMapper.fromRow)
          .toList(growable: false);

      return PartnerTransactionHistoryResultDto(
        items: items,
        totalCount: totalCount,
      );
    } on RpcException catch (error) {
      throw mapPartnerRpcError(error);
    }
  }
}
