import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_application/testing.dart';
import 'package:vet45_iam_presentation/presentation.dart';
import 'package:vet45_iam_presentation/testing.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

void main() {
  final clock = DateTime(2026, 7, 31, 10);

  TenantAuditLogsCubit buildCubit(IIamModule module) {
    return TenantAuditLogsCubit(
      iamModule: module,
      executionContext: FakeExecutionContext(tenantId: 'org-001'),
      clockLocal: () => clock,
    );
  }

  test('search sends UTC end-exclusive range', () async {
    final module = RecordingIamModule(
      FakeIamModule(scenario: FakeIamScenario.tenantAuditSearchOk),
    );
    final cubit = buildCubit(module);
    await cubit.search();
    final query = module.queriesOf<SearchTenantAuditLogsQuery>().single;
    expect(query.fromUtc.isUtc, isTrue);
    expect(query.toUtc.isUtc, isTrue);
    expect(
      query.fromUtc,
      TenantAuditLogsCubit.toUtcStartOfLocalDay(
        cubit.state.filters.fromLocal,
      ),
    );
    expect(
      query.toUtc,
      TenantAuditLogsCubit.toUtcEndExclusiveOfLocalDay(
        cubit.state.filters.toLocal,
      ),
    );
    expect(cubit.state.items, isNotEmpty);
    await cubit.close();
  });

  test('loadNextPage passes opaque cursor without decoding', () async {
    final module = RecordingIamModule(
      FakeIamModule(scenario: FakeIamScenario.tenantAuditSearchOk),
    );
    final cubit = buildCubit(module);
    await cubit.search();
    expect(cubit.state.nextCursor, 'opaque-next-cursor');
    await cubit.loadNextPage();
    final queries = module.queriesOf<SearchTenantAuditLogsQuery>().toList();
    expect(queries, hasLength(2));
    expect(queries.last.cursor, 'opaque-next-cursor');
    await cubit.close();
  });

  test('tenantAuditEmpty yields empty list', () async {
    final cubit = buildCubit(
      FakeIamModule(scenario: FakeIamScenario.tenantAuditEmpty),
    );
    await cubit.search();
    expect(cubit.state.items, isEmpty);
    expect(cubit.state.status, IamLoadStatus.success);
    await cubit.close();
  });

  test('tenantAuditForbidden maps permission denied', () async {
    final cubit = buildCubit(
      FakeIamModule(scenario: FakeIamScenario.tenantAuditForbidden),
    );
    await cubit.search();
    expect(cubit.state.failure?.code, IamBlockedCodes.permissionDenied);
    await cubit.close();
  });

  test('tenantAuditProviderError maps system error', () async {
    final cubit = buildCubit(
      FakeIamModule(scenario: FakeIamScenario.tenantAuditProviderError),
    );
    await cubit.search();
    expect(cubit.state.failure?.code, IamBlockedCodes.systemError);
    await cubit.close();
  });

  test('loadDetail ok and actor unavailable', () async {
    final ok = buildCubit(
      FakeIamModule(scenario: FakeIamScenario.tenantAuditDetailOk),
    );
    await ok.loadDetail('AUD-T-001');
    expect(ok.state.selectedDetail?.actorUnavailable, isFalse);
    await ok.close();

    final unavailable = buildCubit(
      FakeIamModule(scenario: FakeIamScenario.tenantAuditActorUnavailable),
    );
    await unavailable.loadDetail('AUD-T-001');
    expect(unavailable.state.selectedDetail?.actorUnavailable, isTrue);
    await unavailable.close();
  });

  test('cross-tenant detail is generic not found', () async {
    final cubit = buildCubit(
      FakeIamModule(scenario: FakeIamScenario.tenantAuditCrossTenant),
    );
    await cubit.loadDetail('AUD-T-999');
    expect(cubit.state.detailFailure?.code, IamBlockedCodes.resourceNotFound);
    expect(cubit.state.selectedDetail, isNull);
    await cubit.close();
  });
}
