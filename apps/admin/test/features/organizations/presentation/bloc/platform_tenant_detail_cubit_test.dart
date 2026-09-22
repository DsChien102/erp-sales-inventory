import 'package:admin/features/iam/presentation/organizations/models/organization_ui_model.dart';
import 'package:admin/features/iam/presentation/shared/idempotency_key_factory.dart';
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

  test('reinviteProvisioningOwner sends empty names and canonical email', () async {
    final module = _RecordingTenantDetailModule(version: 3);
    final keys = _FixedKeyFactory(['key-a', 'key-b']);
    final cubit = PlatformTenantDetailCubit(
      iamModule: module,
      tenantId: 'tenant-prov',
      keyFactory: keys,
    );

    await cubit.load();
    final ok = await cubit.reinviteProvisioningOwner(email: ' Owner@Example.com ');

    expect(ok, isTrue);
    final cmd = module.lastReinviteCommand;
    expect(cmd, isNotNull);
    expect(cmd!.tenantId, 'tenant-prov');
    expect(cmd.idempotencyKey, 'key-a');
    expect(cmd.owner.email, 'owner@example.com');
    expect(cmd.owner.firstName, '');
    expect(cmd.owner.lastName, '');
    expect(cubit.state.organization!.ownerInvitationEmail, 'owner@example.com');
  });

  test('reinvite retries reuse key until email changes or success', () async {
    final module = _RecordingTenantDetailModule(version: 1, failNextReinvite: true);
    final keys = _FixedKeyFactory(['key-1', 'key-2']);
    final cubit = PlatformTenantDetailCubit(
      iamModule: module,
      tenantId: 'tenant-prov',
      keyFactory: keys,
    );

    await cubit.load();
    expect(await cubit.reinviteProvisioningOwner(email: 'owner@example.com'), isFalse);
    expect(module.lastReinviteCommand?.idempotencyKey, 'key-1');

    module.failNextReinvite = false;
    expect(await cubit.reinviteProvisioningOwner(email: 'owner@example.com'), isTrue);
    expect(module.lastReinviteCommand?.idempotencyKey, 'key-1');

    expect(await cubit.reinviteProvisioningOwner(email: 'new@example.com'), isTrue);
    expect(module.lastReinviteCommand?.idempotencyKey, 'key-2');
    expect(module.lastReinviteCommand?.owner.email, 'new@example.com');
  });
}

final class _FixedKeyFactory implements IdempotencyKeyFactory {
  _FixedKeyFactory(this._keys);

  final List<String> _keys;
  var _index = 0;

  @override
  String next(String intent) {
    if (_index >= _keys.length) {
      throw StateError('No more keys for $intent');
    }
    return _keys[_index++];
  }
}

final class _RecordingTenantDetailModule implements IIamModule {
  _RecordingTenantDetailModule({
    required this.version,
    this.failNextReinvite = false,
  });

  final int version;
  bool failNextReinvite;
  TransferPlatformTenantOwnershipCommand? lastTransferCommand;
  ReinviteProvisioningOwnerCommand? lastReinviteCommand;
  String? invitationEmail = 'owner@example.com';
  String? invitationGivenName = 'Lan';
  String? invitationFamilyName = 'Le';

  @override
  Future<TResult> executeCommandAsync<TResult>(
    ICommand<TResult> command,
  ) async {
    if (command is TransferPlatformTenantOwnershipCommand) {
      lastTransferCommand = command as TransferPlatformTenantOwnershipCommand;
      return null as TResult;
    }
    if (command is ReinviteProvisioningOwnerCommand) {
      final reinvite = command as ReinviteProvisioningOwnerCommand;
      lastReinviteCommand = reinvite;
      if (failNextReinvite) {
        failNextReinvite = false;
        throw const ApplicationException('reinvite failed');
      }
      invitationEmail = reinvite.owner.email;
      if (invitationEmail != 'owner@example.com') {
        invitationGivenName = null;
        invitationFamilyName = null;
      }
      return TenantOnboardingResultDto(
            tenantId: reinvite.tenantId,
            ownerMembershipId: null,
            ownerUserId: null,
            tenantStatus: 'provisioning',
            correlationId: 'corr-1',
            isNewUser: true,
            activationIssued: true,
          )
          as TResult;
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
            status: tenantQuery.tenantId == 'tenant-prov'
                ? TenantLifecycleStatus.provisioning
                : TenantLifecycleStatus.active,
            createdAt: DateTime.parse('2026-01-01T00:00:00Z'),
            version: version,
            ownerInvitationEmail: invitationEmail,
            ownerInvitationState: 'pending',
            ownerInvitationGivenName: invitationGivenName,
            ownerInvitationFamilyName: invitationFamilyName,
            members: tenantQuery.tenantId == 'tenant-prov'
                ? const []
                : const [
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
