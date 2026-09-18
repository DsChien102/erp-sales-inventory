import 'package:admin/features/iam/presentation/organizations/models/organization_ui_model.dart';
import 'package:admin/features/organizations/presentation/bloc/platform_tenant_detail_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_iam_application/testing.dart';
import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

void main() {
  test(
    'transferOwnership sends the loaded tenant version to the command',
    () async {
      final module = _RecordingTenantDetailModule(version: 7);
      final cubit = PlatformTenantDetailCubit(
        iamModule: module,
        tenantId: 'tenant-1',
      );

      await cubit.load();
      final ok = await cubit.transferOwnership(
        newOwnerUserId: 'user-staff',
        idempotencyKey: 'xfer-1',
      );

      expect(ok, isTrue);
      expect(module.lastTransferCommand?.expectedVersion, 7);
    },
  );

  test('close rejects empty reason without calling command', () async {
    final module = FakeIamModule(scenario: FakeIamScenario.tenantSuspendOk);
    final cubit = PlatformTenantDetailCubit(
      iamModule: module,
      tenantId: 'org-001',
    );

    await cubit.load();
    final ok = await cubit.closeOrganization(reason: '  ');

    expect(ok, isFalse);
    expect(cubit.state.errorMessage, 'Vui lòng nhập lý do đóng tổ chức.');
  });

  test('close succeeds for active tenant', () async {
    final module = FakeIamModule(scenario: FakeIamScenario.tenantSuspendOk);
    final cubit = PlatformTenantDetailCubit(
      iamModule: module,
      tenantId: 'org-001',
    );

    await cubit.load();
    final ok = await cubit.closeOrganization(reason: 'Hết hợp đồng');

    expect(ok, isTrue);
    expect(cubit.state.organization!.status, OrganizationStatus.closed);
  });
}

final class _RecordingTenantDetailModule implements IIamModule {
  _RecordingTenantDetailModule({required this.version});

  final int version;
  TransferPlatformTenantOwnershipCommand? lastTransferCommand;

  @override
  Future<TResult> executeCommandAsync<TResult>(
    ICommand<TResult> command,
  ) async {
    if (command is TransferPlatformTenantOwnershipCommand) {
      lastTransferCommand = command as TransferPlatformTenantOwnershipCommand;
      return null as TResult;
    }
    throw UnsupportedError('Unexpected command ${command.runtimeType}');
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    if (query is GetPlatformTenantQuery) {
      final tenantQuery = query as GetPlatformTenantQuery;
      return PlatformTenantDetailDto(
            tenantId: tenantQuery.tenantId,
            name: 'Tenant',
            code: 'TEN-1',
            status: TenantLifecycleStatus.active,
            createdAt: DateTime.parse('2026-01-01T00:00:00Z'),
            version: version,
            members: const [
              PlatformTenantMemberDto(
                userId: 'user-owner',
                fullName: 'Owner',
                email: 'owner@example.com',
                roleLabel: 'owner',
                isOwner: true,
              ),
              PlatformTenantMemberDto(
                userId: 'user-staff',
                fullName: 'Staff',
                email: 'staff@example.com',
                roleLabel: 'staff',
                isOwner: false,
              ),
            ],
          )
          as TResult;
    }
    throw UnsupportedError('Unexpected query ${query.runtimeType}');
  }
}
