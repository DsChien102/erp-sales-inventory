import 'package:vet45_shared_application/application.dart';

import '../contracts/i_iam_module.dart';
import '../dto/platform_user_detail_dto.dart';
import '../dto/platform_user_membership_dto.dart';
import '../dto/platform_user_status.dart';
import '../dto/platform_user_summary_dto.dart';
import '../dto/tenant_onboarding_result_dto.dart';
import '../platform/create_tenant_onboarding/create_tenant_onboarding_command.dart';
import '../platform/get_platform_user/get_platform_user_query.dart';
import '../platform/request_platform_password_reset/request_platform_password_reset_command.dart';
import '../platform/restore_platform_user/restore_platform_user_command.dart';
import '../platform/search_platform_users/search_platform_users_query.dart';
import '../platform/send_activation_invitation/send_activation_invitation_command.dart';
import '../platform/suspend_platform_user/suspend_platform_user_command.dart';
import 'fake_iam_scenario.dart';

/// In-memory IAM module for Admin FE/widget tests (TH-01 S15).
final class FakeIamModule implements IIamModule {
  FakeIamModule({this.scenario = FakeIamScenario.usersSearchOk}) {
    _seedUsers();
  }

  final FakeIamScenario scenario;

  late List<PlatformUserDetailDto> _users;
  final Map<String, TenantOnboardingResultDto> _onboardingByKey = {};

  int activationInviteCount = 0;
  int passwordResetCount = 0;

  void _seedUsers() {
    _users = [
      PlatformUserDetailDto(
        userId: 'lan-le',
        fullName: 'Lê Thị Lan',
        email: 'lan@gmail.com',
        status: PlatformUserStatus.active,
        emailVerified: true,
        createdAt: DateTime(2026, 7, 12, 7),
        lastLoginAt: DateTime(2026, 7, 13, 9, 18),
        memberships: const [
          PlatformUserMembershipDto(
            tenantId: 'mau-hien',
            tenantName: 'Mậu Hiên',
            roleLabel: 'Chủ cửa hàng',
            isOwner: true,
          ),
          PlatformUserMembershipDto(
            tenantId: 'asc-commerce',
            tenantName: 'ASC Commerce',
            roleLabel: 'Chủ cửa hàng',
            isOwner: true,
          ),
        ],
      ),
      PlatformUserDetailDto(
        userId: 'hoa-tran',
        fullName: 'Trần Thị Hoa',
        email: 'hoa@gmail.com',
        status: PlatformUserStatus.pendingActivation,
        emailVerified: false,
        createdAt: DateTime(2026, 7, 12, 15),
        memberships: const [
          PlatformUserMembershipDto(
            tenantId: 'mau-hien',
            tenantName: 'Mậu Hiên',
            roleLabel: 'Nhân viên',
            isOwner: false,
          ),
        ],
      ),
      PlatformUserDetailDto(
        userId: 'minh-nguyen',
        fullName: 'Nguyễn Văn Minh',
        email: 'minh@gmail.com',
        status: PlatformUserStatus.suspended,
        emailVerified: true,
        createdAt: DateTime(2026, 7, 12, 15, 5),
        lastLoginAt: DateTime(2026, 7, 13, 9, 30),
        memberships: const [
          PlatformUserMembershipDto(
            tenantId: 'mau-hien',
            tenantName: 'Mậu Hiên',
            roleLabel: 'Quản trị viên',
            isOwner: false,
          ),
        ],
      ),
      PlatformUserDetailDto(
        userId: 'ha-pham',
        fullName: 'Phạm Thu Hà',
        email: 'ha@gmail.com',
        status: PlatformUserStatus.active,
        emailVerified: true,
        createdAt: DateTime(2026, 7, 12, 16),
        lastLoginAt: DateTime(2026, 7, 13, 11, 20),
        memberships: const [],
      ),
    ];
  }

  void _requirePlatformView() {
    if (scenario == FakeIamScenario.userForbidden403) {
      throw ApplicationException('PLATFORM_PERMISSION_DENIED');
    }
  }

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    return switch (command) {
      SendActivationInvitationCommand c =>
        _handleActivationInvite<TResult>(c),
      RequestPlatformPasswordResetCommand c =>
        _handlePasswordReset<TResult>(c),
      SuspendPlatformUserCommand c => _handleSuspend<TResult>(c),
      RestorePlatformUserCommand c => _handleRestore<TResult>(c),
      CreateTenantOnboardingCommand c => _handleOnboarding<TResult>(c),
      _ => throw UnsupportedError(
        'FakeIamModule: unsupported command ${command.runtimeType}',
      ),
    };
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) {
    return switch (query) {
      SearchPlatformUsersQuery q => _handleSearch<TResult>(q),
      GetPlatformUserQuery q => _handleGetDetail<TResult>(q),
      _ => throw UnsupportedError(
        'FakeIamModule: unsupported query ${query.runtimeType}',
      ),
    };
  }

  Future<TResult> _handleSearch<TResult>(SearchPlatformUsersQuery query) {
    _requirePlatformView();
    Iterable<PlatformUserDetailDto> filtered = _users;
    if (query.status != null) {
      filtered = filtered.where((u) => u.status == query.status);
    }
    final q = query.query?.trim().toLowerCase();
    if (q != null && q.isNotEmpty) {
      filtered = filtered.where(
        (u) =>
            u.fullName.toLowerCase().contains(q) ||
            u.email.toLowerCase().contains(q),
      );
    }
    final summaries = filtered
        .map(
          (u) => PlatformUserSummaryDto(
            userId: u.userId,
            fullName: u.fullName,
            email: u.email,
            status: u.status,
            createdAt: u.createdAt,
          ),
        )
        .toList();
    return Future.value(summaries as TResult);
  }

  Future<TResult> _handleGetDetail<TResult>(GetPlatformUserQuery query) {
    _requirePlatformView();
    final index = _users.indexWhere((u) => u.userId == query.userId);
    if (index == -1) {
      throw ValidationException('Platform user not found: ${query.userId}');
    }
    return Future.value(_users[index] as TResult);
  }

  Future<TResult> _handleActivationInvite<TResult>(
    SendActivationInvitationCommand command,
  ) {
    _requirePlatformView();
    final index = _users.indexWhere((u) => u.userId == command.userId);
    if (index == -1) {
      throw ApplicationException('STATE_CHANGED');
    }
    if (_users[index].status != PlatformUserStatus.pendingActivation &&
        scenario == FakeIamScenario.activationResendOk) {
      throw ApplicationException('STATE_CHANGED');
    }
    activationInviteCount++;
    return Future.value(null as TResult);
  }

  Future<TResult> _handlePasswordReset<TResult>(
    RequestPlatformPasswordResetCommand command,
  ) {
    _requirePlatformView();
    if (!_users.any((u) => u.userId == command.userId)) {
      throw ApplicationException('STATE_CHANGED');
    }
    passwordResetCount++;
    return Future.value(null as TResult);
  }

  Future<TResult> _handleSuspend<TResult>(SuspendPlatformUserCommand command) {
    _requirePlatformView();
    if (command.reason.trim().isEmpty) {
      throw ValidationException('Suspend reason is required');
    }
    final index = _users.indexWhere((u) => u.userId == command.userId);
    if (index == -1) {
      throw ApplicationException('STATE_CHANGED');
    }
    final user = _users[index];
    _users[index] = PlatformUserDetailDto(
      userId: user.userId,
      fullName: user.fullName,
      email: user.email,
      status: PlatformUserStatus.suspended,
      emailVerified: user.emailVerified,
      createdAt: user.createdAt,
      lastLoginAt: user.lastLoginAt,
      memberships: user.memberships,
    );
    return Future.value(null as TResult);
  }

  Future<TResult> _handleRestore<TResult>(RestorePlatformUserCommand command) {
    _requirePlatformView();
    final index = _users.indexWhere((u) => u.userId == command.userId);
    if (index == -1) {
      throw ApplicationException('STATE_CHANGED');
    }
    final user = _users[index];
    if (user.status != PlatformUserStatus.suspended &&
        scenario == FakeIamScenario.restoreOk) {
      throw ApplicationException('STATE_CHANGED');
    }
    _users[index] = PlatformUserDetailDto(
      userId: user.userId,
      fullName: user.fullName,
      email: user.email,
      status: PlatformUserStatus.active,
      emailVerified: user.emailVerified,
      createdAt: user.createdAt,
      lastLoginAt: user.lastLoginAt,
      memberships: user.memberships,
    );
    return Future.value(null as TResult);
  }

  Future<TResult> _handleOnboarding<TResult>(
    CreateTenantOnboardingCommand command,
  ) {
    _requirePlatformView();
    if (scenario == FakeIamScenario.onboardingValidationError) {
      throw ValidationException('Organization name is required');
    }
    if (command.organizationName.trim().isEmpty) {
      throw ValidationException('Organization name is required');
    }
    if (command.idempotencyKey.trim().isEmpty) {
      throw ValidationException('Idempotency key is required');
    }

    final existing = _onboardingByKey[command.idempotencyKey];
    if (existing != null) {
      return Future.value(existing as TResult);
    }

    final isNewUserScenario =
        scenario == FakeIamScenario.onboardingNewUserOk ||
        (scenario != FakeIamScenario.onboardingExistingUserOk &&
            command.owner.isNewUser);

    final result = isNewUserScenario
        ? TenantOnboardingResultDto(
            tenantId: 'tenant-new-1',
            ownerMembershipId: 'mem-new-1',
            ownerUserId: 'user-new-1',
            tenantStatus: 'provisioning',
            correlationId: command.correlationId ?? 'corr-new-1',
            isNewUser: true,
          )
        : TenantOnboardingResultDto(
            tenantId: 'tenant-exist-1',
            ownerMembershipId: 'mem-exist-1',
            ownerUserId: command.owner.existingUserId ?? 'lan-le',
            tenantStatus: 'provisioning',
            correlationId: command.correlationId ?? 'corr-exist-1',
            isNewUser: false,
          );

    if (scenario == FakeIamScenario.onboardingRetryIdempotent ||
        scenario == FakeIamScenario.onboardingExistingUserOk ||
        scenario == FakeIamScenario.onboardingNewUserOk ||
        scenario == FakeIamScenario.usersSearchOk ||
        scenario == FakeIamScenario.userDetailOk) {
      _onboardingByKey[command.idempotencyKey] = result;
    }

    return Future.value(result as TResult);
  }
}
