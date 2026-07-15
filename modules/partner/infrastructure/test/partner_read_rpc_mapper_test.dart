import 'package:test/test.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_infrastructure/src/data_access/partner_read_rpc_mapper.dart';

void main() {
  test('search mapper forwards updated-within-days preset', () {
    final params = PartnerReadRpcMapper.searchParams(
      SearchPartnersQuery(tenantId: 't-1', updatedWithinDays: 30),
    );

    expect(params['p_updated_within_days'], 30);
  });

  test('search mapper sends both role filter to RPC', () {
    final params = PartnerReadRpcMapper.searchParams(
      SearchPartnersQuery(tenantId: 't-1', requireBothRoles: true),
    );

    expect(params['p_role'], 'both');
  });

  test('search mapper sends any role filter when roleless rows are excluded', () {
    final params = PartnerReadRpcMapper.searchParams(
      SearchPartnersQuery(tenantId: 't-1', requireAnyRole: true),
    );

    expect(params['p_role'], 'any');
  });

  test('search mapper keeps role filter unset by default', () {
    final params = PartnerReadRpcMapper.searchParams(
      SearchPartnersQuery(tenantId: 't-1'),
    );

    expect(params['p_role'], isNull);
  });
}
