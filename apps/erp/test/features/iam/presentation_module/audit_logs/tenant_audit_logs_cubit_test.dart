import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/iam/iam_codes.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';
import '../../support/fake_iam_backend.dart';
import 'package:erp/features/iam/data/audit_log_repository.dart';
import 'package:erp/features/iam/presentation/audit_logs/bloc/tenant_audit_filter.dart';
import 'package:erp/features/iam/presentation/audit_logs/bloc/tenant_audit_logs_cubit.dart';
import 'package:erp/features/iam/presentation/audit_logs/views/audit_log_detail_page.dart';
import 'package:erp/features/iam/presentation/shared/iam_load_status.dart';
import 'package:erp/features/iam/data/models/tenant_audit_log.dart' as audit;
import 'package:supabase/supabase.dart';

void main() {
  final clock = DateTime(2026, 7, 31, 10);

  TenantAuditLogsCubit buildCubit(FakeIamBackend module) {
    return TenantAuditLogsCubit(
      auditLogs: FakeAuditLogRepository(module),
      clockLocal: () => clock,
    );
  }

  test('search sends UTC end-exclusive range and populates totalCount', () async {
    final module = FakeIamBackend(scenario: FakeIamScenario.tenantAuditSearchOk);
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
    expect(cubit.state.totalCount, greaterThan(0));
    await cubit.close();
  });

  test('applyFilter forwards structured category, eventCodes, and subjectType', () async {
    final module = FakeIamBackend(scenario: FakeIamScenario.tenantAuditSearchOk);
    final cubit = buildCubit(module);
    await cubit.applyFilter(
      TenantAuditFilter(
        fromLocal: DateTime(2026, 7, 1),
        toLocal: DateTime(2026, 7, 31),
        result: audit.TenantAuditLogResult.success,
        eventCategory: audit.TenantAuditEventCategory.member,
        subjectType: 'membership',
        eventCodes: const ['iam.membership.deactivated'],
      ),
    );

    final query = module.queriesOf<SearchTenantAuditLogsQuery>().single;
    expect(query.query, isNull);
    expect(query.result, 'success');
    expect(query.eventCategory, 'member');
    expect(query.subjectType, 'membership');
    expect(query.eventCodes, ['iam.membership.deactivated']);
    await cubit.close();
  });

  test('loadNextPage passes opaque cursor without decoding', () async {
    final module = FakeIamBackend(scenario: FakeIamScenario.tenantAuditSearchOk);
    final cubit = buildCubit(module);
    await cubit.search();
    expect(cubit.state.nextCursor, 'opaque-next-cursor');
    await cubit.loadNextPage();
    final queries = module.queriesOf<SearchTenantAuditLogsQuery>().toList();
    expect(queries, hasLength(2));
    expect(queries.last.cursor, 'opaque-next-cursor');
    await cubit.close();
  });

  test('tenantAuditEmpty yields empty list and zero totalCount', () async {
    final cubit = buildCubit(
      FakeIamBackend(scenario: FakeIamScenario.tenantAuditEmpty),
    );
    await cubit.search();
    expect(cubit.state.items, isEmpty);
    expect(cubit.state.totalCount, 0);
    expect(cubit.state.status, IamLoadStatus.success);
    await cubit.close();
  });

  test('tenantAuditForbidden maps permission denied', () async {
    final cubit = buildCubit(
      FakeIamBackend(scenario: FakeIamScenario.tenantAuditForbidden),
    );
    await cubit.search();
    expect(cubit.state.failure?.code, IamBlockedCodes.permissionDenied);
    await cubit.close();
  });

  test('tenantAuditProviderError maps system error', () async {
    final cubit = buildCubit(
      FakeIamBackend(scenario: FakeIamScenario.tenantAuditProviderError),
    );
    await cubit.search();
    expect(cubit.state.failure?.code, IamBlockedCodes.systemError);
    await cubit.close();
  });

  test('loadDetail ok and actor unavailable', () async {
    final ok = buildCubit(
      FakeIamBackend(scenario: FakeIamScenario.tenantAuditDetailOk),
    );
    await ok.loadDetail('AUD-T-001');
    expect(ok.state.selectedDetail?.actorUnavailable, isFalse);
    await ok.close();

    final unavailable = buildCubit(
      FakeIamBackend(scenario: FakeIamScenario.tenantAuditActorUnavailable),
    );
    await unavailable.loadDetail('AUD-T-001');
    expect(unavailable.state.selectedDetail?.actorUnavailable, isTrue);
    await unavailable.close();
  });

  test('cross-tenant detail is generic not found', () async {
    final cubit = buildCubit(
      FakeIamBackend(scenario: FakeIamScenario.tenantAuditCrossTenant),
    );
    await cubit.loadDetail('AUD-T-999');
    expect(cubit.state.detailFailure?.code, IamBlockedCodes.resourceNotFound);
    expect(cubit.state.selectedDetail, isNull);
    await cubit.close();
  });

  test('h24 searches exactly the last 24 hours, kept across load more', () async {
    final module = FakeIamBackend(scenario: FakeIamScenario.tenantAuditSearchOk);
    final cubit = TenantAuditLogsCubit(
      auditLogs: FakeAuditLogRepository(module),
      // 2026-11-25 00:10 VN == 2026-11-24 17:10 UTC
      clockLocal: () => DateTime.utc(2026, 11, 24, 17, 10),
    );
    addTearDown(cubit.close);

    await cubit.applyRangeAndResult(TenantAuditRange.h24, null);
    await cubit.loadNextPage();

    final queries = module.queriesOf<SearchTenantAuditLogsQuery>().toList();
    expect(queries, hasLength(2));
    final expectedFrom = DateTime.utc(2026, 11, 23, 17, 10);
    final expectedTo = DateTime.utc(2026, 11, 24, 17, 10);
    expect(queries[0].fromUtc, expectedFrom);
    expect(queries[0].toUtc, expectedTo);
    expect(queries[1].fromUtc, expectedFrom);
    expect(queries[1].toUtc, expectedTo);
  });

  test('d7 follows Vietnam days on a UTC device', () async {
    final module = FakeIamBackend(scenario: FakeIamScenario.tenantAuditSearchOk);
    final cubit = TenantAuditLogsCubit(
      auditLogs: FakeAuditLogRepository(module),
      // 2026-11-24T18:00Z == 2026-11-25 01:00 VN
      clockLocal: () => DateTime.utc(2026, 11, 24, 18),
    );
    addTearDown(cubit.close);

    await cubit.applyRangeAndResult(TenantAuditRange.d7, null);
    final query = module.queriesOf<SearchTenantAuditLogsQuery>().single;
    // from = đầu ngày 19/11 VN (2026-11-18T17:00Z), to = hết ngày 25/11 VN (2026-11-25T17:00Z)
    expect(query.fromUtc, DateTime.utc(2026, 11, 18, 17));
    expect(query.toUtc, DateTime.utc(2026, 11, 25, 17));
  });

  test('range makes the filter advanced', () {
    final base = TenantAuditFilter.forRange(
      TenantAuditRange.d30,
      nowIct: DateTime.utc(2026, 11, 25, 10),
    );
    expect(base.hasAdvancedFilters, isFalse);
    expect(base.copyWith(range: TenantAuditRange.d7).hasAdvancedFilters, isTrue);
    expect(base.copyWith(range: TenantAuditRange.h24).hasAdvancedFilters, isTrue);
  });

  test('stale search response is dropped', () async {
    final first = Completer<audit.TenantAuditLogPage>();
    final second = Completer<audit.TenantAuditLogPage>();
    var call = 0;
    final repo = _CustomSearchRepo((_) {
      call += 1;
      return call == 1 ? first.future : second.future;
    });
    final cubit = TenantAuditLogsCubit(
      auditLogs: repo,
      clockLocal: () => DateTime.utc(2026, 11, 25, 3),
    );
    addTearDown(cubit.close);

    final f1 = cubit.search();
    final f2 = cubit.applyRangeAndResult(TenantAuditRange.d7, null);

    second.complete(
      const audit.TenantAuditLogPage(items: [], totalCount: 1),
    );
    await f2;
    expect(cubit.state.totalCount, 1);

    first.complete(
      const audit.TenantAuditLogPage(items: [], totalCount: 99),
    );
    await f1;
    expect(cubit.state.totalCount, 1);
  });

  test('load more failure keeps items and status', () async {
    final module = FakeIamBackend(scenario: FakeIamScenario.tenantAuditSearchOk);
    final baseRepo = FakeAuditLogRepository(module);
    var failNext = false;
    final repo = _CustomSearchRepo((cursor) {
      if (failNext) {
        throw const AppException(
          IamBlockedCodes.permissionDenied,
          serverMessage: 'Không có quyền',
        );
      }
      return baseRepo.search(
        from: DateTime.utc(2026, 7, 1),
        to: DateTime.utc(2026, 8, 1),
        cursor: cursor,
      );
    });
    final cubit = TenantAuditLogsCubit(
      auditLogs: repo,
      clockLocal: () => clock,
    );
    addTearDown(cubit.close);

    await cubit.search();
    final initialCount = cubit.state.items.length;
    expect(initialCount, greaterThan(0));

    failNext = true;
    await cubit.loadNextPage();

    expect(cubit.state.status, IamLoadStatus.success);
    expect(cubit.state.items, hasLength(initialCount));
    expect(cubit.state.failure, isNull);
    expect(cubit.state.loadMoreFailure?.code, IamBlockedCodes.permissionDenied);
  });

  testWidgets('detail page requests once', (tester) async {
    final module = FakeIamBackend(scenario: FakeIamScenario.tenantAuditDetailOk);
    await tester.pumpWidget(
      MaterialApp(
        home: AuditLogDetailPage(
          auditLogId: 'AUD-T-001',
          auditLogs: FakeAuditLogRepository(module),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(module.queriesOf<GetTenantAuditLogQuery>(), hasLength(1));
  });
}

final class _CustomSearchRepo extends AuditLogRepository {
  _CustomSearchRepo(this._onSearch)
    : super(
        rpc: SupabaseRpc(
          SupabaseClient(
            'http://127.0.0.1',
            'anon',
            authOptions: const AuthClientOptions(autoRefreshToken: false),
          ),
        ),
        tenantId: () async => 'tenant-1',
      );

  final Future<audit.TenantAuditLogPage> Function(String? cursor) _onSearch;

  @override
  Future<audit.TenantAuditLogPage> search({
    required DateTime from,
    required DateTime to,
    String? query,
    String? result,
    String? eventCategory,
    String? subjectType,
    List<String>? eventCodes,
    String? cursor,
    int limit = 20,
  }) => _onSearch(cursor);
}
