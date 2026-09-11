import 'package:admin/features/users/presentation/bloc/platform_users_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_iam_application/testing.dart';
import 'package:admin/features/iam/presentation.dart';
import 'package:admin/features/iam/testing.dart';
import 'package:vet45_shared_application/application.dart';

void main() {
  test('load does not fan-out GetPlatformUserQuery (no N+1)', () async {
    final module = RecordingIamModule(
      FakeIamModule(scenario: FakeIamScenario.usersSearchOk),
    );
    final cubit = PlatformUsersCubit(iamModule: module);
    await cubit.load();
    expect(module.queriesOf<SearchPlatformUsersQuery>(), hasLength(1));
    expect(module.queriesOf<GetPlatformUserQuery>(), isEmpty);
    expect(cubit.state.users, isNotEmpty);
    expect(cubit.state.status, IamLoadStatus.success);
    await cubit.close();
  });

  test('loadNextPage passes opaque cursor and appends/dedupes', () async {
    final module = RecordingIamModule(
      FakeIamModule(scenario: FakeIamScenario.usersSearchOk),
    );
    final cubit = PlatformUsersCubit(iamModule: module);
    // Force small pages via wrapping — Fake uses limit from query (default 20).
    // Seed enough users already (4). Use limit via custom module.
    await cubit.close();

    final paged = RecordingIamModule(_LimitedSearchModule(limit: 2));
    final pagedCubit = PlatformUsersCubit(iamModule: paged);
    await pagedCubit.load();
    expect(pagedCubit.state.users, hasLength(2));
    expect(pagedCubit.state.nextCursor, isNotNull);

    final firstCursor = pagedCubit.state.nextCursor;
    await pagedCubit.loadNextPage();
    final queries = paged.queriesOf<SearchPlatformUsersQuery>().toList();
    expect(queries, hasLength(2));
    expect(queries.last.cursor, firstCursor);
    expect(pagedCubit.state.users.length, greaterThan(2));
    final ids = pagedCubit.state.users.map((u) => u.userId).toList();
    expect(ids.toSet().length, ids.length);
    await pagedCubit.close();
  });

  test('setStatusFilter sends status to SearchPlatformUsersQuery', () async {
    final module = RecordingIamModule(FakeIamModule());
    final cubit = PlatformUsersCubit(iamModule: module);
    await cubit.setStatusFilter(PlatformUserStatus.suspended);
    final query = module.queriesOf<SearchPlatformUsersQuery>().last;
    expect(query.status, PlatformUserStatus.suspended);
    await cubit.close();
  });

  test('forbidden maps to unauthorized', () async {
    final cubit = PlatformUsersCubit(
      iamModule: FakeIamModule(scenario: FakeIamScenario.userForbidden403),
    );
    await cubit.load();
    expect(cubit.state.status, IamLoadStatus.unauthorized);
    expect(
      cubit.state.failure?.code,
      IamBlockedCodes.platformPermissionDenied,
    );
    await cubit.close();
  });
}

final class _LimitedSearchModule implements IIamModule {
  _LimitedSearchModule({required this.limit});

  final int limit;
  final FakeIamModule _delegate = FakeIamModule(
    scenario: FakeIamScenario.usersSearchOk,
  );

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    return _delegate.executeCommandAsync(command);
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    if (query is SearchPlatformUsersQuery) {
      final search = query as SearchPlatformUsersQuery;
      final page = await _delegate
          .executeQueryAsync<CursorPageDto<PlatformUserSummaryDto>>(
            SearchPlatformUsersQuery(
              query: search.query,
              status: search.status,
              cursor: search.cursor,
              limit: limit,
            ),
          );
      return page as TResult;
    }
    return _delegate.executeQueryAsync(query);
  }
}
