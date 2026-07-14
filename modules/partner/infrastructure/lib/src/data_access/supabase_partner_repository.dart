import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import 'partner_aggregate_mapper.dart';
import 'supabase_partner_read_gateway.dart';

final class SupabasePartnerRepository implements IPartnerRepository {
  SupabasePartnerRepository({required SupabasePartnerReadGateway readGateway})
    : _readGateway = readGateway;

  final SupabasePartnerReadGateway _readGateway;

  @override
  Future<Partner?> findById({
    required TenantId tenantId,
    required PartnerId partnerId,
  }) async {
    try {
      final detail = await _readGateway.getPartnerDetail(
        GetPartnerDetailQuery(
          tenantId: tenantId.value,
          partnerId: partnerId.value,
        ),
      );
      return PartnerAggregateMapper.fromDetail(
        detail: detail,
        tenantId: tenantId,
      );
    } on PartnerBlockedException catch (error) {
      if (error.code == PartnerBlockedCodes.notFound) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<void> add(Partner partner) {
    throw UnsupportedError('Use CreatePartnerCommand via IPartnerCommandGateway');
  }

  @override
  Future<void> save(Partner partner, {required int expectedVersion}) {
    throw UnsupportedError(
      'Use mutation commands via IPartnerCommandGateway',
    );
  }
}
