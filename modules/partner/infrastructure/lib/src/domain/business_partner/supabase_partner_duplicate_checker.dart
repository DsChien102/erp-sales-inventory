import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/partner_error_mapper.dart';
import 'partner_rpc_mapper.dart';

final class SupabasePartnerDuplicateChecker implements IPartnerDuplicateChecker {
  SupabasePartnerDuplicateChecker({
    required SupabaseSchemaRpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<List<PartnerDuplicateMatch>> findMatches({
    required TenantId tenantId,
    PhoneNumber? phone,
    EmailAddress? email,
    TaxCode? taxCode,
    BusinessPartnerId? excludePartnerId,
  }) async {
    try {
      final rows = await _rpcClient.callList(
        'check_duplicate',
        params: PartnerRpcMapper.checkDuplicateParams(
          tenantId: tenantId.value,
          phone: phone,
          email: email,
          taxCode: taxCode,
        ),
      );

      final matches = rows
          .map(
            (row) => PartnerDuplicateMatch(
              field: PartnerRpcMapper.duplicateFieldFromRpc(
                row['duplicate_field'] as String,
              ),
              businessPartnerId: BusinessPartnerId(
                row['business_partner_id'] as String,
              ),
              displayName: row['display_name'] as String,
              matchedValue: row['matched_value'] as String,
            ),
          )
          .toList(growable: false);

      if (excludePartnerId == null) {
        return matches;
      }

      return matches
          .where((match) => match.businessPartnerId != excludePartnerId)
          .toList(growable: false);
    } on RpcException catch (error) {
      throw mapPartnerRpcError(error);
    }
  }
}
