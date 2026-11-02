import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/partner/data/models/partner_action_log.dart';
import 'package:erp/features/partner/data/models/partner_enums.dart';
import 'package:erp/features/partner/data/models/partner_inputs.dart';
import 'package:erp/features/partner/data/partner_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';

import '../support/recording_rpc.dart';

void main() {
  test('fromJson maps snake_case logs and empty snapshots to null', () {
    final page = PartnerActionLogPage.fromJson({
      'items': [
        {
          'action_log_id': 'al-1',
          'action_type': 'add_contact',
          'actor_user_id': '8acac7ec-0000-4000-8000-000000000001',
          'reason': null,
          'before_state': <String, dynamic>{},
          'after_state': <String, dynamic>{},
          'created_at': '2026-07-16T18:26:00',
        },
      ],
      'total': 1,
      'page': 1,
      'limit': 20,
    });

    expect(page.items, hasLength(1));
    expect(page.items.single.actionType, PartnerActionType.addContact);
    expect(page.items.single.beforeState, isNull);
    expect(page.items.single.afterState, isNull);
    expect(page.total, 1);
    expect(page.page, 1);
    expect(page.limit, 20);
  });

  test('missing total, page, and limit fall back to the item list', () {
    final page = PartnerActionLogPage.fromJson({
      'items': [
        {
          'action_log_id': 'al-1',
          'action_type': 'create',
          'actor_user_id': 'user-1',
          'created_at': '2026-07-14T23:26:00',
        },
      ],
    });

    expect(page.total, 1);
    expect(page.page, 1);
    expect(page.limit, 1);
    expect(page.items.single.actionType, PartnerActionType.create);
  });

  group('PartnerRepository (4-A)', () {
    PartnerRepository repo(RecordingRpc rpc) => PartnerRepository(
      rpc: rpc,
      tenantId: () async => 't-1',
      actorId: () async => 'u-1',
    );

    const okRow = [
      {'partner_id': 'p-1', 'expected_version': 3},
    ];

    test(
      'H4: deactivate gọi đúng 1 RPC (deactivate_partner), không gọi get_partner_detail',
      () async {
        final rpc = RecordingRpc(respond: (_, _) => okRow);
        await repo(rpc).deactivate('p-1', expectedVersion: 2);
        expect(rpc.fns, ['deactivate_partner']);
      },
    );

    test(
      'H4: reactivate / softDelete / update / transform cũng không gọi get_partner_detail',
      () async {
        final rpc = RecordingRpc(respond: (_, _) => okRow);
        final r = repo(rpc);
        await r.reactivate('p-1', expectedVersion: 2);
        await r.softDelete('p-1', expectedVersion: 2);
        await r.update(
          partnerId: 'p-1',
          expectedVersion: 2,
          roles: const [PartnerRoleType.customer],
          personProfile: const PersonProfileInput(fullName: 'A', phone: '0901234567'),
        );
        await r.transformToOrganization(
          partnerId: 'p-1',
          expectedVersion: 2,
          organizationProfile: const OrganizationProfileInput(
            organizationType: OrganizationType.company,
            organizationName: 'Cty',
            phone: '0281234567',
          ),
        );
        expect(rpc.fns, [
          'reactivate_partner',
          'soft_delete_partner',
          'update_partner',
          'transform_to_organization',
        ]);
      },
    );

    test(
      'H5: search không gọi RPC nào khác ngoài search_partners (không get_session_context)',
      () async {
        final rpc = RecordingRpc(respond: (_, _) => [<String, dynamic>{}]);
        await repo(rpc).search();
        expect(rpc.fns, ['search_partners']);
      },
    );

    test('H6: STATE_CHANGED → code STATE_CHANGED', () async {
      final rpc = RecordingRpc(
        respond: (_, _) => throw PostgrestException(message: 'STATE_CHANGED: version mismatch'),
      );
      await expectLater(
        repo(rpc).deactivate('p-1', expectedVersion: 1),
        throwsA(isA<AppException>().having((e) => e.code, 'code', 'STATE_CHANGED')),
      );
    });

    test('H6: permission denied → NO_PERMISSION', () async {
      final rpc = RecordingRpc(
        respond: (_, _) => throw PostgrestException(message: 'permission denied: partner.update'),
      );
      await expectLater(
        repo(rpc).deactivate('p-1', expectedVersion: 1),
        throwsA(isA<AppException>().having((e) => e.code, 'code', AppErrorCode.noPermission)),
      );
    });

    test('H6: DUPLICATE_WARNING giữ JSON ở serverMessage', () async {
      final rpc = RecordingRpc(
        respond: (_, _) =>
            throw PostgrestException(message: 'DUPLICATE_WARNING: [{"field":"phone"}]'),
      );
      await expectLater(
        repo(rpc).create(
          partnerType: PartnerType.person,
          roles: const [PartnerRoleType.customer],
          personProfile: const PersonProfileInput(fullName: 'A', phone: '0901234567'),
        ),
        throwsA(
          isA<AppException>()
              .having((e) => e.code, 'code', 'DUPLICATE_WARNING')
              .having((e) => e.serverMessage, 'serverMessage', contains('"field":"phone"')),
        ),
      );
    });

    test('H3: create với SĐT sai ném VALIDATION_ERROR và không gọi RPC', () async {
      final rpc = RecordingRpc(respond: (_, _) => okRow);
      await expectLater(
        repo(rpc).create(
          partnerType: PartnerType.person,
          roles: const [PartnerRoleType.customer],
          personProfile: const PersonProfileInput(fullName: 'A', phone: '123'),
        ),
        throwsA(isA<AppException>().having((e) => e.code, 'code', AppErrorCode.validation)),
      );
      expect(rpc.calls, isEmpty);
    });

    test('H3: update với roles rỗng và transform với tên rỗng không gọi RPC', () async {
      final rpc = RecordingRpc(respond: (_, _) => okRow);
      await expectLater(
        repo(rpc).update(
          partnerId: 'p-1',
          expectedVersion: 1,
          roles: const [],
          personProfile: const PersonProfileInput(fullName: 'A', phone: '0901234567'),
        ),
        throwsA(isA<AppException>()),
      );
      await expectLater(
        repo(rpc).transformToOrganization(
          partnerId: 'p-1',
          expectedVersion: 1,
          organizationProfile: const OrganizationProfileInput(
            organizationType: OrganizationType.company,
            organizationName: ' ',
            phone: '0281234567',
          ),
        ),
        throwsA(isA<AppException>()),
      );
      expect(rpc.calls, isEmpty);
    });

    test('get_partner_detail trả rỗng → NOT_FOUND', () async {
      final rpc = RecordingRpc(respond: (_, _) => <String, dynamic>{});
      await expectLater(
        repo(rpc).getDetail('p-1'),
        throwsA(isA<AppException>().having((e) => e.code, 'code', AppErrorCode.notFound)),
      );
    });

    test('RPC table không trả dòng → NOT_FOUND (create/update/status)', () async {
      final rpc = RecordingRpc(respond: (_, _) => <Object>[]);
      await expectLater(
        repo(rpc).deactivate('p-1', expectedVersion: 1),
        throwsA(isA<AppException>().having((e) => e.code, 'code', AppErrorCode.notFound)),
      );
    });
  });
}
