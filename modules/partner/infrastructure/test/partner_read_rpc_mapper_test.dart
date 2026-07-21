import 'package:test/test.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
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

  test('action logs mapper forwards pagination params', () {
    final params = PartnerReadRpcMapper.actionLogsParams(
      GetPartnerActionLogsQuery(
        tenantId: 't-1',
        partnerId: 'p-1',
        page: 2,
        limit: 10,
      ),
    );

    expect(params['p_tenant_id'], 't-1');
    expect(params['p_partner_id'], 'p-1');
    expect(params['p_page'], 2);
    expect(params['p_limit'], 10);
  });

  test('action logs result mapper parses snake_case action_type', () {
    final result = PartnerReadRpcMapper.mapActionLogsResult({
      'items': [
        {
          'action_log_id': 'al-1',
          'action_type': 'add_contact',
          'actor_user_id': '8acac7ec-0000-4000-8000-000000000001',
          'reason': null,
          'created_at': '2026-07-16T11:26:00.000Z',
        },
      ],
      'page': 1,
      'limit': 20,
      'total': 1,
    });

    expect(result.items, hasLength(1));
    expect(result.items.first.actionType, PartnerActionType.addContact);
    expect(result.items.first.actorUserId, startsWith('8acac7ec'));
  });

  test('action logs result mapper parses snapshots and normalizes {} to null', () {
    final result = PartnerReadRpcMapper.mapActionLogsResult({
      'items': [
        {
          'action_log_id': 'al-1',
          'action_type': 'update',
          'actor_user_id': '8acac7ec-0000-4000-8000-000000000001',
          'reason': null,
          'before_state': {
            'display_name': 'A',
            'person_profile': {'phone': '111'},
          },
          'after_state': {
            'display_name': 'A',
            'person_profile': {'phone': '222'},
          },
          'created_at': '2026-07-16T11:26:00.000Z',
        },
        {
          'action_log_id': 'al-2',
          'action_type': 'create',
          'actor_user_id': '8acac7ec-0000-4000-8000-000000000001',
          'reason': null,
          'before_state': <String, dynamic>{},
          'after_state': null,
          'created_at': '2026-07-14T11:26:00.000Z',
        },
      ],
      'page': 1,
      'limit': 20,
      'total': 2,
    });

    final updated = result.items.first;
    expect(updated.beforeState?['display_name'], 'A');
    expect(
      (updated.afterState?['person_profile'] as Map?)?['phone'],
      '222',
    );

    final created = result.items.last;
    expect(created.beforeState, isNull);
    expect(created.afterState, isNull);
  });
}
