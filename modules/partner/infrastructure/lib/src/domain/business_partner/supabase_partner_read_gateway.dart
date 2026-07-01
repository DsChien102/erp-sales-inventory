import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/partner_error_mapper.dart';
import 'partner_detail_mapper.dart';
import 'partner_list_mapper.dart';
import 'partner_rpc_mapper.dart';

final class SupabasePartnerReadGateway implements IPartnerReadGateway {
  SupabasePartnerReadGateway({
    required SupabaseSchemaRpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<PartnerSearchResultDto> search({
    required String tenantId,
    required PartnerSearchCriteria criteria,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final phoneKeyword = _phoneKeyword(criteria.keyword);
      final rows = await _rpcClient.callList(
        'search_partners',
        params: <String, dynamic>{
          'p_tenant_id': tenantId,
          'p_keyword': criteria.keyword,
          'p_keyword_phone_normalized': phoneKeyword,
          'p_statuses': criteria.statuses.map((status) => status.name).toList(growable: false),
          'p_role_filter': criteria.roleFilter?.name,
          'p_entity_types': criteria.expandedEntityTypes
              ?.map(PartnerRpcMapper.entityTypeToRpc)
              .toList(growable: false),
          'p_limit': limit,
          'p_offset': offset,
        },
      );

      if (rows.isEmpty) {
        return const PartnerSearchResultDto(items: [], totalCount: 0);
      }

      final totalCount = (rows.first['total_count'] as num?)?.toInt() ?? rows.length;
      final items = rows.map(PartnerListMapper.fromRow).toList(growable: false);

      return PartnerSearchResultDto(
        items: items,
        totalCount: totalCount,
      );
    } on RpcException catch (error) {
      throw mapPartnerRpcError(error);
    }
  }

  @override
  Future<PartnerDetailDto?> getDetail({
    required String tenantId,
    required String partnerId,
  }) async {
    try {
      final rows = await _rpcClient.callList(
        'get_partner_detail',
        params: <String, dynamic>{
          'p_tenant_id': tenantId,
          'p_partner_id': partnerId,
        },
      );

      if (rows.isEmpty) {
        return null;
      }

      return PartnerDetailMapper.fromRow(rows.first);
    } on RpcException catch (error) {
      throw mapPartnerRpcError(error);
    }
  }

  static String? _phoneKeyword(String? keyword) {
    if (keyword == null) {
      return null;
    }
    final digits = keyword.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 8) {
      return null;
    }
    return SearchKeywordNormalizer.normalizePhoneKeyword(keyword);
  }
}
