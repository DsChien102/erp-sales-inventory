import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_application/testing.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_partner_presentation/presentation.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

void main() {
  test('fetchPartners loads mixed types from fake module', () async {
    final cubit = PartnerListCubit(
      partnerModule: FakePartnerModule(scenario: FakePartnerScenario.searchMixedTypes),
      executionContext: FakeExecutionContext(tenantId: 'tenant-1'),
    );

    await cubit.fetchPartners();

    final state = cubit.state;
    expect(state, isA<PartnerListLoaded>());
    expect((state as PartnerListLoaded).items, hasLength(2));
    expect(state.total, 2);
    await cubit.close();
  });

  test('searchByKeyword refreshes with query', () async {
    final cubit = PartnerListCubit(
      partnerModule: FakePartnerModule(scenario: FakePartnerScenario.searchEmpty),
      executionContext: FakeExecutionContext(tenantId: 'tenant-1'),
    );

    cubit.searchByKeyword('Minh');
    await cubit.stream.firstWhere((state) => state is PartnerListLoaded);

    expect((cubit.state as PartnerListLoaded).query, 'Minh');
    await cubit.close();
  });

  test('contact keyword search surfaces the linked organization', () async {
    final cubit = PartnerListCubit(
      partnerModule: FakePartnerModule(
        scenario: FakePartnerScenario.searchByContact,
      ),
      executionContext: FakeExecutionContext(tenantId: 'tenant-1'),
    );

    cubit.searchByKeyword('Trần Thị B');
    await cubit.stream.firstWhere((state) => state is PartnerListLoaded);

    final state = cubit.state as PartnerListLoaded;
    expect(state.query, 'Trần Thị B');
    expect(state.items, hasLength(1));
    expect(state.items.single.partnerId, 'p-org-contact-match');
    expect(state.items.single.partnerType, PartnerType.organization);
    await cubit.close();
  });

  test('seven-day filter is forwarded to search query', () async {
    final module = _RecordingPartnerModule();
    final cubit = PartnerListCubit(
      partnerModule: module,
      executionContext: FakeExecutionContext(tenantId: 'tenant-1'),
    );

    cubit.applyFilters(updatedTimeFilter: PartnerUpdatedTimeFilter.last7Days);
    await cubit.stream.firstWhere((state) => state is PartnerListLoaded);

    expect(module.lastSearch?.updatedWithinDays, 7);
    expect(cubit.state.updatedTimeFilter, PartnerUpdatedTimeFilter.last7Days);
    await cubit.close();
  });

  test('all statuses forwards null so active and inactive are included', () async {
    final module = _RecordingPartnerModule();
    final cubit = PartnerListCubit(
      partnerModule: module,
      executionContext: FakeExecutionContext(tenantId: 'tenant-1'),
    );

    await cubit.fetchPartners();

    expect(module.lastSearch?.status, isNull);
    await cubit.close();
  });

  test('main list requires at least one transactional role', () async {
    final module = _RecordingPartnerModule();
    final cubit = PartnerListCubit(
      partnerModule: module,
      executionContext: FakeExecutionContext(tenantId: 'tenant-1'),
    );

    await cubit.fetchPartners();

    expect(module.lastSearch?.requireAnyRole, isTrue);
    await cubit.close();
  });

  test('keyword search keeps all-status filter', () async {
    final module = _RecordingPartnerModule();
    final cubit = PartnerListCubit(
      partnerModule: module,
      executionContext: FakeExecutionContext(tenantId: 'tenant-1'),
    );

    cubit.searchByKeyword('Minh');
    await cubit.stream.firstWhere((state) => state is PartnerListLoaded);

    expect(module.lastSearch?.query, 'Minh');
    expect(module.lastSearch?.status, isNull);
    await cubit.close();
  });

  test('both-role filter is forwarded to backend without local filtering', () async {
    final module = _RecordingPartnerModule(
      result: PartnerSearchResultDto(
        items: List.generate(
          20,
          (index) => PartnerListItemDto(
            partnerId: 'p-both-$index',
            partnerType: PartnerType.organization,
            status: PartnerStatus.active,
            displayName: 'Both roles $index',
            roles: const [PartnerRoleType.customer, PartnerRoleType.supplier],
          ),
        ),
        total: 25,
        page: 1,
        limit: 20,
      ),
    );
    final cubit = PartnerListCubit(
      partnerModule: module,
      executionContext: FakeExecutionContext(tenantId: 'tenant-1'),
    );

    cubit.applyFilters(roleFilter: PartnerRoleFilter.both);
    await cubit.stream.firstWhere((state) => state is PartnerListLoaded);

    expect(module.lastSearch?.requireBothRoles, isTrue);
    expect((cubit.state as PartnerListLoaded).total, 25);
    expect((cubit.state as PartnerListLoaded).hasReachedMax, isFalse);
    await cubit.close();
  });

  test('ignores a search response that completes after the cubit is closed', () async {
    final module = _DelayedPartnerModule();
    final cubit = PartnerListCubit(
      partnerModule: module,
      executionContext: FakeExecutionContext(tenantId: 'tenant-1'),
    );

    final fetch = cubit.fetchPartners();
    await module.queryStarted.future;
    await cubit.close();
    module.complete(
      const PartnerSearchResultDto(
        items: [],
        total: 0,
        page: 1,
        limit: 20,
      ),
    );

    await expectLater(fetch, completes);
  });
}

final class _DelayedPartnerModule implements IPartnerModule {
  final queryStarted = Completer<void>();
  final _result = Completer<PartnerSearchResultDto>();

  void complete(PartnerSearchResultDto result) => _result.complete(result);

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    throw UnsupportedError('commands are not used in this test');
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    if (query is SearchPartnersQuery) {
      if (!queryStarted.isCompleted) queryStarted.complete();
      return await _result.future as TResult;
    }
    throw UnsupportedError('query ${query.runtimeType} is not supported');
  }
}

final class _RecordingPartnerModule implements IPartnerModule {
  _RecordingPartnerModule({
    this.result = const PartnerSearchResultDto(
      items: [],
      total: 0,
      page: 1,
      limit: 20,
    ),
  });

  final PartnerSearchResultDto result;
  SearchPartnersQuery? lastSearch;

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    throw UnsupportedError('commands are not used in this test');
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    if (query is SearchPartnersQuery) {
      lastSearch = query as SearchPartnersQuery;
      return result as TResult;
    }
    throw UnsupportedError('query ${query.runtimeType} is not supported');
  }
}
