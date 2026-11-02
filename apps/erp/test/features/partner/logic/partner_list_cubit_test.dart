import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:erp/features/partner/data/models/partner_models.dart';
import '../support/fake_partner_repository.dart';
import 'package:erp/features/partner/presentation.dart';
import '../support/scripted_partner_repository.dart';

void main() {
  test('fetchPartners loads mixed types from fake repository', () async {
    final cubit = PartnerListCubit(
      repository: FakePartnerRepository(scenario: FakePartnerScenario.searchMixedTypes),
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
      repository: FakePartnerRepository(scenario: FakePartnerScenario.searchEmpty),
    );

    cubit.searchByKeyword('Minh');
    await cubit.stream.firstWhere((state) => state is PartnerListLoaded);

    expect((cubit.state as PartnerListLoaded).query, 'Minh');
    await cubit.close();
  });

  test('contact keyword search surfaces the linked organization', () async {
    final cubit = PartnerListCubit(
      repository: FakePartnerRepository(
        scenario: FakePartnerScenario.searchByContact,
      ),
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
      repository: module.repository,
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
      repository: module.repository,
    );

    await cubit.fetchPartners();

    expect(module.lastSearch?.status, isNull);
    await cubit.close();
  });

  test('main list requires at least one transactional role', () async {
    final module = _RecordingPartnerModule();
    final cubit = PartnerListCubit(
      repository: module.repository,
    );

    await cubit.fetchPartners();

    expect(module.lastSearch?.requireAnyRole, isTrue);
    await cubit.close();
  });

  test('keyword search keeps all-status filter', () async {
    final module = _RecordingPartnerModule();
    final cubit = PartnerListCubit(
      repository: module.repository,
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
      repository: module.repository,
    );

    cubit.applyFilters(roleFilter: PartnerRoleFilter.both);
    await cubit.stream.firstWhere((state) => state is PartnerListLoaded);

    expect(module.lastSearch?.requireBothRoles, isTrue);
    expect((cubit.state as PartnerListLoaded).total, 25);
    expect((cubit.state as PartnerListLoaded).hasReachedMax, isFalse);
    await cubit.close();
  });

  group('sort option is forwarded as p_sort (behavior parity 4-B B1)', () {
    const expected = {
      PartnerSortOption.updatedAtDesc: 'updated_at_desc',
      PartnerSortOption.updatedAtAsc: 'updated_at_asc',
      PartnerSortOption.nameAsc: 'display_name_asc',
      PartnerSortOption.nameDesc: 'display_name_desc',
    };
    for (final entry in expected.entries) {
      test('${entry.key.name} -> ${entry.value}', () async {
        final module = _RecordingPartnerModule();
        final cubit = PartnerListCubit(repository: module.repository);

        cubit.applyFilters(sortOption: entry.key);
        await cubit.stream.firstWhere((state) => state is PartnerListLoaded);

        expect(module.lastSearch?.sort, entry.value);
        await cubit.close();
      });
    }
  });

  test('ignores a search response that completes after the cubit is closed', () async {
    final queryStarted = Completer<void>();
    final result = Completer<PartnerSearchResultDto>();
    final cubit = PartnerListCubit(
      repository: ScriptedPartnerRepository(
        onCall: (_, _) {
          if (!queryStarted.isCompleted) queryStarted.complete();
          return result.future;
        },
      ),
    );

    final fetch = cubit.fetchPartners();
    await queryStarted.future;
    await cubit.close();
    result.complete(
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

/// Repository ghi lại lần tìm cuối; [result] là kết quả trả về.
final class _RecordingPartnerModule {
  _RecordingPartnerModule({
    this.result = const PartnerSearchResultDto(
      items: [],
      total: 0,
      page: 1,
      limit: 20,
    ),
  }) {
    repository = ScriptedPartnerRepository(onCall: (_, _) => result);
  }

  final PartnerSearchResultDto result;
  late final ScriptedPartnerRepository repository;

  /// Đối số lần gọi `search` cuối.
  _SearchArgs? get lastSearch =>
      repository.invocations.isEmpty ? null : _SearchArgs(repository.invocations.last.args);
}

final class _SearchArgs {
  const _SearchArgs(this.args);

  final Map<String, Object?> args;

  int? get updatedWithinDays => args['updatedWithinDays'] as int?;
  PartnerStatus? get status => args['status'] as PartnerStatus?;
  bool get requireAnyRole => args['requireAnyRole'] as bool;
  bool get requireBothRoles => args['requireBothRoles'] as bool;
  String? get query => args['query'] as String?;
  String? get sort => args['sort'] as String?;
}
