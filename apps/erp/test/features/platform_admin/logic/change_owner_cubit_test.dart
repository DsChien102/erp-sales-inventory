import 'package:erp/core/iam/iam_load_status.dart';
import 'package:erp/features/platform_admin/logic/change_owner_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_platform_tenant_repository.dart';

void main() {
  late FakePlatformTenantRepository repository;
  late ChangeOwnerCubit cubit;

  setUp(() {
    repository = FakePlatformTenantRepository();
    cubit = ChangeOwnerCubit(tenantId: 't-1', tenants: repository);
  });

  tearDown(() => cubit.close());

  test('candidates are the active members except the current owner', () async {
    await cubit.load();

    expect(cubit.state.status, IamLoadStatus.success);
    expect(cubit.state.currentOwner?.userId, 'owner-1');
    expect(cubit.state.candidates.map((m) => m.userId), ['user-2', 'user-3']);
  });

  test('search matches name or email', () async {
    await cubit.load();

    cubit.setQuery('minh');
    expect(cubit.state.filteredCandidates.map((m) => m.userId), ['user-3']);

    cubit.setQuery('USER-2@');
    expect(cubit.state.filteredCandidates.map((m) => m.userId), ['user-2']);

    cubit.setQuery('khong');
    expect(cubit.state.filteredCandidates, isEmpty);
  });

  test('toggle selects and unselects one member', () async {
    await cubit.load();

    cubit.toggle('user-2');
    expect(cubit.state.selected?.userId, 'user-2');

    cubit.toggle('user-3');
    expect(cubit.state.selected?.userId, 'user-3');

    cubit.toggle('user-3');
    expect(cubit.state.selected, isNull);
  });

  test('the current owner cannot be selected', () async {
    await cubit.load();

    cubit.toggle('owner-1');

    expect(cubit.state.selected, isNull);
  });

  test('no other active member is the empty state', () async {
    repository.tenantMembers = [member('owner-1', isOwner: true)];

    await cubit.load();

    expect(cubit.state.status, IamLoadStatus.empty);
    expect(cubit.state.candidates, isEmpty);
  });

  test('confirm transfers to the selection with the loaded version', () async {
    await cubit.load();
    cubit.toggle('user-2');

    final ok = await cubit.confirm();

    expect(ok, isTrue);
    expect(cubit.state.completed, isTrue);
    final call = repository.calls.single;
    expect(call.name, 'transfer');
    expect(call.args['newOwnerUserId'], 'user-2');
    expect(call.args['expectedVersion'], 4);
    expect((call.args['key'] as String).startsWith('transfer-owner-platform-tenant-t-1-'), isTrue);
  });

  test('confirm without a selection does nothing', () async {
    await cubit.load();

    expect(await cubit.confirm(), isFalse);
    expect(repository.calls, isEmpty);
  });

  test('retry for the same target reuses the key; another target gets a new one', () async {
    await cubit.load();
    cubit.toggle('user-2');
    repository.mutationError = serverError('SYSTEM_ERROR');
    await cubit.confirm();
    await cubit.confirm();
    cubit.toggle('user-3');
    await cubit.confirm();

    final used = repository.calls.map((c) => c.args['key']).toList();
    expect(used[0], used[1]);
    expect(used[2], isNot(used[0]));
  });

  test('OWNER_TARGET_INVALID shows the member message and keeps the page open', () async {
    await cubit.load();
    cubit.toggle('user-2');
    repository.mutationError = serverError('OWNER_TARGET_INVALID');

    final ok = await cubit.confirm();

    expect(ok, isFalse);
    expect(cubit.state.completed, isFalse);
    expect(cubit.state.failure?.message, 'Không thể chọn thành viên này.');
    expect(cubit.state.selected?.userId, 'user-2');
  });

  test('OWNER_TARGET_ALREADY_OWNER says the member owns another organization', () async {
    await cubit.load();
    cubit.toggle('user-2');
    repository.mutationError = serverError('OWNER_TARGET_ALREADY_OWNER');

    final ok = await cubit.confirm();

    expect(ok, isFalse);
    expect(cubit.state.completed, isFalse);
    expect(
      cubit.state.failure?.message,
      'Người này đã là chủ sở hữu của một tổ chức khác.',
    );
    expect(cubit.state.selected?.userId, 'user-2');
  });

  test('STATE_CHANGED shows the reload message', () async {
    await cubit.load();
    cubit.toggle('user-2');
    repository.mutationError = serverError('STATE_CHANGED');

    await cubit.confirm();

    expect(
      cubit.state.failure?.message,
      'Dữ liệu đã thay đổi. Vui lòng tải lại rồi xác nhận lại.',
    );
  });

  test('a selection that left the organization is dropped on reload', () async {
    await cubit.load();
    cubit.toggle('user-2');
    repository.tenantMembers = [member('owner-1', isOwner: true), member('user-3')];

    await cubit.load();

    expect(cubit.state.selected, isNull);
  });
}
