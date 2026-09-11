import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_iam_application/testing.dart';
import 'package:admin/features/iam/presentation.dart';
import 'package:admin/features/iam/presentation/testing/recording_iam_module.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

void main() {
  test(
    'Cubit resolves complete localized labels but keeps raw event-code text and structured filters independent',
    () async {
      final recording = RecordingIamModule(
        FakeIamModule(scenario: FakeIamScenario.tenantAuditSearchOk),
      );
      final cubit = TenantAuditLogsCubit(
        iamModule: recording,
        executionContext: FakeExecutionContext(tenantId: 'tenant-1'),
        initialFilter: TenantAuditFilter(
          fromLocal: DateTime(2026, 8, 1),
          toLocal: DateTime(2026, 8, 20),
          query: '  Tạm ngừng thành viên  ',
        ),
      );
      addTearDown(cubit.close);

      await cubit.search();

      var query = recording.queriesOf<SearchTenantAuditLogsQuery>().last;
      expect(query.query, isNull);
      expect(query.eventCodes, contains(IamAuditEvents.membershipDeactivated));

      await cubit.applyFilter(
        cubit.state.filters.copyWith(
          query: 'iam.membership.deactivated',
          eventCodes: const [IamAuditEvents.membershipDeactivated],
        ),
      );

      query = recording.queriesOf<SearchTenantAuditLogsQuery>().last;
      expect(query.query, 'iam.membership.deactivated');
      expect(query.eventCodes, [IamAuditEvents.membershipDeactivated]);
    },
  );

  test('Cubit intersects localized labels with structured event-code filters', () async {
    final recording = RecordingIamModule(
      FakeIamModule(scenario: FakeIamScenario.tenantAuditSearchOk),
    );
    final cubit = TenantAuditLogsCubit(
      iamModule: recording,
      executionContext: FakeExecutionContext(tenantId: 'tenant-1'),
      initialFilter: TenantAuditFilter(
        fromLocal: DateTime(2026, 8, 1),
        toLocal: DateTime(2026, 8, 20),
        query: 'Kích hoạt tổ chức',
        eventCodes: const [
          IamAuditEvents.tenantActivated,
          IamAuditEvents.tenantProfileUpdated,
        ],
      ),
    );
    addTearDown(cubit.close);

    await cubit.search();

    var query = recording.queriesOf<SearchTenantAuditLogsQuery>().last;
    expect(query.query, isNull);
    expect(query.eventCodes, [IamAuditEvents.tenantActivated]);

    await cubit.applyFilter(
      cubit.state.filters.copyWith(
        query: 'Kích hoạt tổ chức',
        eventCodes: const [IamAuditEvents.tenantProfileUpdated],
      ),
    );

    query = recording.queriesOf<SearchTenantAuditLogsQuery>().last;
    expect(query.query, isNull);
    expect(query.eventCodes, isEmpty);
  });
}
