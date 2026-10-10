import 'package:erp/core/iam/iam_load_status.dart';
import 'package:erp/core/iam/idempotency_key_factory.dart';
import 'package:erp/core/session/models/tenant_context.dart';
import 'package:erp/features/platform_admin/logic/platform_tenant_detail_cubit.dart';
import 'package:erp/features/platform_admin/logic/platform_tenant_detail_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_platform_tenant_repository.dart';

/// Khoá tăng dần để thấy khi nào được sinh mới.
final class _CountingKeys implements IdempotencyKeyFactory {
  int count = 0;

  @override
  String next(String intent) => '$intent#${++count}';
}

void main() {
  late FakePlatformTenantRepository repository;
  late _CountingKeys keys;
  late PlatformTenantDetailCubit cubit;

  setUp(() {
    repository = FakePlatformTenantRepository();
    keys = _CountingKeys();
    cubit = PlatformTenantDetailCubit(tenantId: 't-1', tenants: repository, keyFactory: keys);
  });

  tearDown(() => cubit.close());

  test('load fetches detail and members', () async {
    await cubit.load();

    expect(cubit.state.status, IamLoadStatus.success);
    expect(cubit.state.detail?.name, 'Mậu Hiền');
    expect(cubit.state.members, hasLength(3));
  });

  test('load failure keeps no detail', () async {
    repository.getError = serverError('SYSTEM_ERROR');

    await cubit.load();

    expect(cubit.state.status, IamLoadStatus.failure);
    expect(cubit.state.detail, isNull);
  });

  test('suspend sends the trimmed reason, version and key, then reloads', () async {
    await cubit.load();
    cubit.beginAction(PlatformTenantAction.suspend);
    repository.tenantDetail = detail('t-1', status: TenantStatus.suspended, version: 5);

    final ok = await cubit.suspend(reason: '  Vi phạm  ');

    expect(ok, isTrue);
    final call = repository.calls.single;
    expect(call.name, 'suspend');
    expect(call.args['reason'], 'Vi phạm');
    expect(call.args['expectedVersion'], 4);
    expect(call.args['key'], 'suspend-platform-tenant-t-1#1');
    expect(cubit.state.successMessage, 'Đã tạm ngừng tổ chức thành công.');
    expect(cubit.state.detail?.status, TenantStatus.suspended);
    expect(cubit.state.isSubmitting, isFalse);
  });

  test('a blank reason is rejected before any request', () async {
    await cubit.load();

    final ok = await cubit.suspend(reason: '   ');

    expect(ok, isFalse);
    expect(repository.calls, isEmpty);
    expect(cubit.state.failure?.message, 'Vui lòng nhập lý do.');
  });

  test('restore has no reason and reports success', () async {
    repository.tenantDetail = detail('t-1', status: TenantStatus.suspended);
    await cubit.load();

    final ok = await cubit.restore();

    expect(ok, isTrue);
    expect(repository.calls.single.name, 'restore');
    expect(repository.calls.single.args.containsKey('reason'), isFalse);
    expect(cubit.state.successMessage, 'Đã khôi phục tổ chức thành công.');
  });

  test('close sends the reason', () async {
    await cubit.load();

    final ok = await cubit.closeOrganization(reason: 'Ngừng kinh doanh');

    expect(ok, isTrue);
    expect(repository.calls.single.name, 'close');
    expect(repository.calls.single.args['reason'], 'Ngừng kinh doanh');
    expect(cubit.state.successMessage, 'Đã đóng tổ chức.');
  });

  test('the key is reused when the same sheet is confirmed again after an error', () async {
    await cubit.load();
    cubit.beginAction(PlatformTenantAction.suspend);
    repository.mutationError = serverError('SYSTEM_ERROR');

    expect(await cubit.suspend(reason: 'a'), isFalse);
    repository.mutationError = null;
    expect(await cubit.suspend(reason: 'a'), isTrue);

    expect(repository.calls.map((c) => c.args['key']).toSet(), {'suspend-platform-tenant-t-1#1'});
  });

  test('opening the sheet again creates a new key', () async {
    await cubit.load();
    cubit.beginAction(PlatformTenantAction.suspend);
    await cubit.suspend(reason: 'a');
    cubit.beginAction(PlatformTenantAction.suspend);
    await cubit.suspend(reason: 'b');

    expect(repository.calls.map((c) => c.args['key']), [
      'suspend-platform-tenant-t-1#1',
      'suspend-platform-tenant-t-1#2',
    ]);
  });

  test('STATE_CHANGED shows the reload message and refreshes the version', () async {
    await cubit.load();
    cubit.beginAction(PlatformTenantAction.suspend);
    repository
      ..mutationError = serverError('STATE_CHANGED')
      ..tenantDetail = detail('t-1', version: 9);

    final ok = await cubit.suspend(reason: 'a');

    expect(ok, isFalse);
    expect(
      cubit.state.failure?.message,
      'Dữ liệu đã thay đổi. Vui lòng tải lại rồi xác nhận lại.',
    );
    expect(cubit.state.detail?.version, 9);
    expect(cubit.state.isSubmitting, isFalse);
  });

  test('closed tenant cannot be restored: the server error is shown', () async {
    repository.tenantDetail = detail('t-1', status: TenantStatus.closed);
    await cubit.load();
    repository.mutationError = serverError('TENANT_STATE_INVALID');

    final ok = await cubit.restore();

    expect(ok, isFalse);
    expect(cubit.state.failure?.code, 'TENANT_STATE_INVALID');
    expect(cubit.state.successMessage, isNull);
  });

  test('a reload failure after success is still a success', () async {
    await cubit.load();
    cubit.beginAction(PlatformTenantAction.suspend);
    repository.getError = serverError('SYSTEM_ERROR');

    final ok = await cubit.suspend(reason: 'a');

    expect(ok, isTrue);
    expect(cubit.state.successMessage, isNotNull);
    expect(cubit.state.failure, isNull);
  });
}
