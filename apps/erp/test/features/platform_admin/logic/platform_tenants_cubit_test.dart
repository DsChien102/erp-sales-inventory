import 'package:erp/core/iam/iam_load_status.dart';
import 'package:erp/core/session/models/tenant_context.dart';
import 'package:erp/features/platform_admin/logic/platform_tenants_cubit.dart';
import 'package:erp/features/platform_admin/logic/platform_tenants_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_platform_tenant_repository.dart';

void main() {
  late FakePlatformTenantRepository repository;
  late PlatformTenantsCubit cubit;

  setUp(() {
    repository = FakePlatformTenantRepository();
    cubit = PlatformTenantsCubit(
      tenants: repository,
      searchDebounce: const Duration(milliseconds: 10),
    );
  });

  tearDown(() => cubit.close());

  test('load fills the list', () async {
    await cubit.load();

    expect(cubit.state.status, IamLoadStatus.success);
    expect(cubit.state.items.map((t) => t.tenantId), ['t-1', 't-2']);
    expect(repository.searches.single, {'query': '', 'status': null, 'cursor': null});
  });

  test('an empty list without filters is empty and not filtered', () async {
    repository.tenants = [];

    await cubit.load();

    expect(cubit.state.status, IamLoadStatus.empty);
    expect(cubit.state.isFiltered, isFalse);
  });

  test('chips send the lifecycle status and Tất cả sends none', () async {
    await cubit.load();

    cubit.setFilter(PlatformTenantFilter.suspended);
    await Future<void>.delayed(Duration.zero);
    expect(repository.searches.last['status'], 'suspended');
    expect(cubit.state.items.map((t) => t.tenantId), ['t-2']);

    cubit.setFilter(PlatformTenantFilter.all);
    await Future<void>.delayed(Duration.zero);
    expect(repository.searches.last['status'], isNull);
  });

  test('search is debounced into one request', () async {
    await cubit.load();
    final before = repository.searches.length;

    cubit
      ..setQuery('t')
      ..setQuery('t-')
      ..setQuery('t-2');
    await Future<void>.delayed(const Duration(milliseconds: 60));

    expect(repository.searches.length, before + 1);
    expect(repository.searches.last['query'], 't-2');
    expect(cubit.state.items.single.tenantId, 't-2');
  });

  test('a search with no match is empty and filtered', () async {
    await cubit.load();

    cubit.setQuery('khong-co');
    await Future<void>.delayed(const Duration(milliseconds: 60));

    expect(cubit.state.status, IamLoadStatus.empty);
    expect(cubit.state.isFiltered, isTrue);

    cubit.clearFilters();
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.status, IamLoadStatus.success);
    expect(cubit.state.query, isEmpty);
  });

  test('loadMore appends the next page by cursor', () async {
    repository
      ..tenants = [for (var i = 1; i <= 5; i++) summary('t-$i')]
      ..pageSize = 2;
    await cubit.load();
    expect(cubit.state.items, hasLength(2));
    expect(cubit.state.hasMore, isTrue);

    await cubit.loadMore();
    await cubit.loadMore();

    expect(cubit.state.items.map((t) => t.tenantId), ['t-1', 't-2', 't-3', 't-4', 't-5']);
    expect(cubit.state.hasMore, isFalse);
    expect(repository.searches.map((s) => s['cursor']), [null, '2', '4']);
  });

  test('a server permission error is unauthorized', () async {
    repository.searchError = serverError('PLATFORM_PERMISSION_DENIED');

    await cubit.load();

    expect(cubit.state.status, IamLoadStatus.unauthorized);
  });

  test('another error is a retryable failure', () async {
    repository.searchError = serverError('SYSTEM_ERROR');

    await cubit.load();

    expect(cubit.state.status, IamLoadStatus.failure);
    expect(cubit.state.failure, isNotNull);

    repository.searchError = null;
    await cubit.load();
    expect(cubit.state.status, IamLoadStatus.success);
  });

  test('closed tenants keep their status', () async {
    repository.tenants = [summary('t-9', status: TenantStatus.closed)];

    await cubit.load();

    expect(cubit.state.items.single.status, TenantStatus.closed);
  });
}
