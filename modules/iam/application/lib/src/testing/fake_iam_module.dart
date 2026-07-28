import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../authentication/sign_in/sign_in_command.dart';
import '../authentication/sign_out/sign_out_command.dart';
import '../contracts/i_iam_module.dart';
import '../dto/platform_audit_log_detail_dto.dart';
import '../dto/platform_audit_log_status.dart';
import '../dto/platform_audit_log_summary_dto.dart';
import '../dto/platform_tenant_detail_dto.dart';
import '../dto/platform_tenant_member_dto.dart';
import '../dto/platform_tenant_summary_dto.dart';
import '../dto/platform_user_detail_dto.dart';
import '../dto/platform_user_membership_dto.dart';
import '../dto/platform_user_status.dart';
import '../dto/platform_user_summary_dto.dart';
import '../dto/tenant_onboarding_result_dto.dart';
import '../platform/create_tenant_onboarding/create_tenant_onboarding_command.dart';
import '../platform/get_platform_audit_log/get_platform_audit_log_query.dart';
import '../platform/get_platform_tenant/get_platform_tenant_query.dart';
import '../platform/get_platform_user/get_platform_user_query.dart';
import '../platform/list_platform_tenant_members/list_platform_tenant_members_query.dart';
import '../platform/request_platform_password_reset/request_platform_password_reset_command.dart';
import '../platform/restore_platform_tenant/restore_platform_tenant_command.dart';
import '../platform/restore_platform_user/restore_platform_user_command.dart';
import '../platform/search_platform_audit_logs/search_platform_audit_logs_query.dart';
import '../platform/search_platform_tenants/search_platform_tenants_query.dart';
import '../platform/search_platform_users/search_platform_users_query.dart';
import '../platform/send_activation_invitation/send_activation_invitation_command.dart';
import '../platform/suspend_platform_tenant/suspend_platform_tenant_command.dart';
import '../platform/suspend_platform_user/suspend_platform_user_command.dart';
import '../platform/transfer_platform_tenant_ownership/transfer_platform_tenant_ownership_command.dart';
import 'fake_iam_scenario.dart';

/// In-memory IAM module for Admin FE/widget tests (TH-01 S15/S16 + auth).
final class FakeIamModule implements IIamModule {
  FakeIamModule({
    this.scenario = FakeIamScenario.usersSearchOk,
    this.onSignedIn,
    this.onSignedOut,
  }) {
    _seedUsers();
    _seedTenants();
    _seedAuditLogs();
  }

  final FakeIamScenario scenario;

  /// Optional hook so tests can update [ICurrentUser] / session after SignIn.
  final void Function(String email)? onSignedIn;

  /// Optional hook so tests can clear session after SignOut.
  final void Function()? onSignedOut;

  late List<PlatformUserDetailDto> _users;
  late List<PlatformTenantDetailDto> _tenants;
  late List<PlatformAuditLogDetailDto> _auditLogs;
  final Map<String, TenantOnboardingResultDto> _onboardingByKey = {};
  final Set<String> _ownershipTransferKeys = {};

  int activationInviteCount = 0;
  int passwordResetCount = 0;
  int signInCount = 0;
  int signOutCount = 0;
  String? lastSignedInEmail;

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
            tenantId: 'org-001',
            tenantName: 'Mậu Hiên',
            roleLabel: 'Chủ cửa hàng',
            isOwner: true,
          ),
          PlatformUserMembershipDto(
            tenantId: 'org-002',
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
            tenantId: 'org-001',
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
            tenantId: 'org-001',
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

  void _seedTenants() {
    _tenants = [
      PlatformTenantDetailDto(
        tenantId: 'org-001',
        name: 'Mậu Hiên',
        code: 'TEN-000142',
        status: TenantLifecycleStatus.active,
        createdAt: DateTime(2026, 7, 10, 10),
        ownerUserId: 'lan-le',
        ownerName: 'Lê Thị Lan',
        ownerEmail: 'lan@gmail.com',
        activatedAt: DateTime(2026, 7, 12, 16, 45),
        members: const [
          PlatformTenantMemberDto(
            userId: 'lan-le',
            fullName: 'Lê Thị Lan',
            email: 'lan@gmail.com',
            roleLabel: 'Chủ cửa hàng',
            isOwner: true,
          ),
          PlatformTenantMemberDto(
            userId: 'hoa-tran',
            fullName: 'Trần Thị Hoa',
            email: 'hoa@gmail.com',
            roleLabel: 'Nhân viên',
            isOwner: false,
          ),
          PlatformTenantMemberDto(
            userId: 'minh-nguyen',
            fullName: 'Nguyễn Văn Minh',
            email: 'minh@gmail.com',
            roleLabel: 'Quản trị viên',
            isOwner: false,
          ),
        ],
      ),
      PlatformTenantDetailDto(
        tenantId: 'org-002',
        name: 'ASC Commerce',
        code: 'TEN-000138',
        status: TenantLifecycleStatus.provisioning,
        createdAt: DateTime(2026, 7, 13, 8, 20),
        ownerUserId: 'lan-le',
        ownerName: 'Lê Thị Lan',
        ownerEmail: 'lan@gmail.com',
        members: const [
          PlatformTenantMemberDto(
            userId: 'lan-le',
            fullName: 'Lê Thị Lan',
            email: 'lan@gmail.com',
            roleLabel: 'Chủ cửa hàng',
            isOwner: true,
          ),
        ],
      ),
      PlatformTenantDetailDto(
        tenantId: 'org-003',
        name: 'VietVet Trading',
        code: 'TEN-000095',
        status: TenantLifecycleStatus.suspended,
        createdAt: DateTime(2026, 7, 1, 10),
        ownerUserId: 'lan-le',
        ownerName: 'Lê Thị Lan',
        ownerEmail: 'lan@gmail.com',
        suspendedAt: DateTime(2026, 7, 13, 7, 30),
        suspendedBy: 'Tùng Nguyễn',
        suspendReason: 'Rà soát rủi ro truy cập',
        members: const [
          PlatformTenantMemberDto(
            userId: 'lan-le',
            fullName: 'Lê Thị Lan',
            email: 'lan@gmail.com',
            roleLabel: 'Chủ cửa hàng',
            isOwner: true,
          ),
        ],
      ),
      PlatformTenantDetailDto(
        tenantId: 'org-004',
        name: 'Hải Phòng Vet',
        code: 'TEN-000041',
        status: TenantLifecycleStatus.closed,
        createdAt: DateTime(2026, 5, 1, 9),
        ownerUserId: 'lan-le',
        ownerName: 'Lê Thị Lan',
        ownerEmail: 'lan@gmail.com',
        closedAt: DateTime(2026, 6, 30, 18),
        closedBy: 'Nhân viên vận hành nền tảng',
        closeReason: 'Kết thúc hợp đồng dịch vụ',
        members: const [
          PlatformTenantMemberDto(
            userId: 'lan-le',
            fullName: 'Lê Thị Lan',
            email: 'lan@gmail.com',
            roleLabel: 'Chủ cửa hàng',
            isOwner: true,
          ),
        ],
      ),
    ];
  }

  void _seedAuditLogs() {
    _auditLogs = [
      PlatformAuditLogDetailDto(
        id: 'AUD-000982',
        title: 'Đã tạm ngừng tổ chức',
        actionCode: 'platform.tenant.suspend',
        status: PlatformAuditLogStatus.success,
        statusLabel: 'Thành công',
        actorName: 'Tùng Nguyễn',
        actorRole: 'Nhân viên vận hành nền tảng',
        targetOrgName: 'VietVet Trading',
        targetOrgCode: 'TEN-000095',
        timestamp: DateTime(2026, 7, 13, 7, 30),
        sourceApp: 'Ứng dụng quản trị nền tảng',
        correlationId: 'COR-7F29A1',
        beforeState: 'Đang hoạt động',
        afterState: 'Đã tạm ngừng',
      ),
      PlatformAuditLogDetailDto(
        id: 'AUD-000981',
        title: 'Từ chối thao tác không đủ quyền',
        actionCode: 'platform.access.denied',
        status: PlatformAuditLogStatus.blocked,
        statusLabel: 'Bị chặn',
        actorName: 'Nguyễn Minh',
        actorRole: 'Quản trị viên tổ chức',
        targetOrgName: 'Mậu Hiên',
        targetOrgCode: 'TEN-000142',
        timestamp: DateTime(2026, 7, 13, 7, 18),
        sourceApp: 'Ứng dụng quản trị nền tảng',
        correlationId: 'COR-7F29A0',
        beforeState: 'Yêu cầu xóa dữ liệu',
        afterState: 'Yêu cầu bị từ chối',
      ),
      PlatformAuditLogDetailDto(
        id: 'AUD-000980',
        title: 'Khởi tạo tổ chức chưa hoàn tất',
        actionCode: 'platform.tenant.onboard',
        status: PlatformAuditLogStatus.error,
        statusLabel: 'Lỗi',
        actorName: 'Quản trị hệ thống',
        actorRole: 'Hệ thống tự động',
        targetOrgName: 'VET45 Hà Nội',
        targetOrgCode: 'TEN-000152',
        timestamp: DateTime(2026, 7, 13, 6, 52),
        sourceApp: 'Ứng dụng quản trị nền tảng',
        correlationId: 'COR-7F299F',
        beforeState: 'Khởi tạo cơ sở dữ liệu',
        afterState: 'Lỗi kết nối RPC',
      ),
      PlatformAuditLogDetailDto(
        id: 'AUD-000979',
        title: 'Làm mới chính sách quyền',
        actionCode: 'platform.policy.refresh',
        status: PlatformAuditLogStatus.success,
        statusLabel: 'Thành công',
        actorName: 'Tiến trình hệ thống',
        actorRole: 'Hệ thống tự động',
        targetOrgName: 'Nền tảng VET45',
        targetOrgCode: 'SYS-000001',
        timestamp: DateTime(2026, 7, 13, 6, 30),
        sourceApp: 'Dịch vụ nền tảng',
        correlationId: 'COR-7F299E',
        beforeState: 'Phiên bản v11',
        afterState: 'Phiên bản v12',
      ),
    ];
  }

  void _requirePlatformView() {
    if (scenario == FakeIamScenario.userForbidden403 ||
        scenario == FakeIamScenario.tenantForbidden403 ||
        scenario == FakeIamScenario.auditForbidden403) {
      throw ApplicationException('PLATFORM_PERMISSION_DENIED');
    }
  }

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    return switch (command) {
      SignInCommand c => _handleSignIn<TResult>(c),
      SignOutCommand _ => _handleSignOut<TResult>(),
      SendActivationInvitationCommand c =>
        _handleActivationInvite<TResult>(c),
      RequestPlatformPasswordResetCommand c =>
        _handlePasswordReset<TResult>(c),
      SuspendPlatformUserCommand c => _handleSuspendUser<TResult>(c),
      RestorePlatformUserCommand c => _handleRestoreUser<TResult>(c),
      CreateTenantOnboardingCommand c => _handleOnboarding<TResult>(c),
      SuspendPlatformTenantCommand c => _handleSuspendTenant<TResult>(c),
      RestorePlatformTenantCommand c => _handleRestoreTenant<TResult>(c),
      TransferPlatformTenantOwnershipCommand c =>
        _handleTransferOwnership<TResult>(c),
      _ => throw UnsupportedError(
        'FakeIamModule: unsupported command ${command.runtimeType}',
      ),
    };
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) {
    return switch (query) {
      SearchPlatformUsersQuery q => _handleSearchUsers<TResult>(q),
      GetPlatformUserQuery q => _handleGetUserDetail<TResult>(q),
      SearchPlatformTenantsQuery q => _handleSearchTenants<TResult>(q),
      GetPlatformTenantQuery q => _handleGetTenantDetail<TResult>(q),
      ListPlatformTenantMembersQuery q => _handleListMembers<TResult>(q),
      SearchPlatformAuditLogsQuery q => _handleSearchAudit<TResult>(q),
      GetPlatformAuditLogQuery q => _handleGetAuditDetail<TResult>(q),
      _ => throw UnsupportedError(
        'FakeIamModule: unsupported query ${query.runtimeType}',
      ),
    };
  }

  Future<TResult> _handleSignIn<TResult>(SignInCommand command) {
    if (scenario == FakeIamScenario.authInvalid) {
      throw ApplicationException('Invalid login credentials');
    }
    signInCount++;
    lastSignedInEmail = command.email;
    onSignedIn?.call(command.email);
    return Future.value(null as TResult);
  }

  Future<TResult> _handleSignOut<TResult>() {
    signOutCount++;
    onSignedOut?.call();
    return Future.value(null as TResult);
  }

  Future<TResult> _handleSearchUsers<TResult>(SearchPlatformUsersQuery query) {
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

  Future<TResult> _handleGetUserDetail<TResult>(GetPlatformUserQuery query) {
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

  Future<TResult> _handleSuspendUser<TResult>(
    SuspendPlatformUserCommand command,
  ) {
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

  Future<TResult> _handleRestoreUser<TResult>(
    RestorePlatformUserCommand command,
  ) {
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

  Future<TResult> _handleSearchTenants<TResult>(
    SearchPlatformTenantsQuery query,
  ) {
    _requirePlatformView();
    Iterable<PlatformTenantDetailDto> filtered = _tenants;
    if (query.status != null) {
      filtered = filtered.where((t) => t.status == query.status);
    }
    final q = query.query?.trim().toLowerCase();
    if (q != null && q.isNotEmpty) {
      filtered = filtered.where(
        (t) =>
            t.name.toLowerCase().contains(q) ||
            t.code.toLowerCase().contains(q),
      );
    }
    final summaries = filtered
        .map(
          (t) => PlatformTenantSummaryDto(
            tenantId: t.tenantId,
            name: t.name,
            code: t.code,
            status: t.status,
            createdAt: t.createdAt,
            ownerName: t.ownerName,
            ownerEmail: t.ownerEmail,
            memberCount: t.members.length,
          ),
        )
        .toList();
    return Future.value(summaries as TResult);
  }

  Future<TResult> _handleGetTenantDetail<TResult>(
    GetPlatformTenantQuery query,
  ) {
    _requirePlatformView();
    final index = _tenants.indexWhere((t) => t.tenantId == query.tenantId);
    if (index == -1) {
      throw ValidationException('Platform tenant not found: ${query.tenantId}');
    }
    return Future.value(_tenants[index] as TResult);
  }

  Future<TResult> _handleListMembers<TResult>(
    ListPlatformTenantMembersQuery query,
  ) {
    _requirePlatformView();
    final index = _tenants.indexWhere((t) => t.tenantId == query.tenantId);
    if (index == -1) {
      throw ValidationException('Platform tenant not found: ${query.tenantId}');
    }
    return Future.value(_tenants[index].members as TResult);
  }

  Future<TResult> _handleSuspendTenant<TResult>(
    SuspendPlatformTenantCommand command,
  ) {
    _requirePlatformView();
    if (command.reason.trim().isEmpty) {
      throw ValidationException('Suspend reason is required');
    }
    final index = _tenants.indexWhere((t) => t.tenantId == command.tenantId);
    if (index == -1) {
      throw ApplicationException('STATE_CHANGED');
    }
    final tenant = _tenants[index];
    if (tenant.status == TenantLifecycleStatus.closed ||
        scenario == FakeIamScenario.tenantClosedReject) {
      throw ApplicationException('STATE_CHANGED');
    }
    _tenants[index] = PlatformTenantDetailDto(
      tenantId: tenant.tenantId,
      name: tenant.name,
      code: tenant.code,
      status: TenantLifecycleStatus.suspended,
      createdAt: tenant.createdAt,
      ownerUserId: tenant.ownerUserId,
      ownerName: tenant.ownerName,
      ownerEmail: tenant.ownerEmail,
      ownerRoleLabel: tenant.ownerRoleLabel,
      activatedAt: tenant.activatedAt,
      suspendedAt: DateTime.now(),
      suspendReason: command.reason,
      members: tenant.members,
    );
    return Future.value(null as TResult);
  }

  Future<TResult> _handleRestoreTenant<TResult>(
    RestorePlatformTenantCommand command,
  ) {
    _requirePlatformView();
    final index = _tenants.indexWhere((t) => t.tenantId == command.tenantId);
    if (index == -1) {
      throw ApplicationException('STATE_CHANGED');
    }
    final tenant = _tenants[index];
    if (tenant.status == TenantLifecycleStatus.closed ||
        scenario == FakeIamScenario.tenantClosedReject) {
      throw ApplicationException('STATE_CHANGED');
    }
    if (tenant.status != TenantLifecycleStatus.suspended &&
        scenario == FakeIamScenario.tenantRestoreOk) {
      throw ApplicationException('STATE_CHANGED');
    }
    _tenants[index] = PlatformTenantDetailDto(
      tenantId: tenant.tenantId,
      name: tenant.name,
      code: tenant.code,
      status: TenantLifecycleStatus.active,
      createdAt: tenant.createdAt,
      ownerUserId: tenant.ownerUserId,
      ownerName: tenant.ownerName,
      ownerEmail: tenant.ownerEmail,
      ownerRoleLabel: tenant.ownerRoleLabel,
      activatedAt: tenant.activatedAt ?? DateTime.now(),
      members: tenant.members,
    );
    return Future.value(null as TResult);
  }

  Future<TResult> _handleTransferOwnership<TResult>(
    TransferPlatformTenantOwnershipCommand command,
  ) {
    _requirePlatformView();
    if (_ownershipTransferKeys.contains(command.idempotencyKey)) {
      return Future.value(null as TResult);
    }
    final index = _tenants.indexWhere((t) => t.tenantId == command.tenantId);
    if (index == -1) {
      throw ApplicationException('STATE_CHANGED');
    }
    final tenant = _tenants[index];
    if (tenant.status == TenantLifecycleStatus.closed) {
      throw ApplicationException('STATE_CHANGED');
    }
    final memberIndex = tenant.members.indexWhere(
      (m) => m.userId == command.newOwnerUserId,
    );
    if (memberIndex == -1 ||
        scenario == FakeIamScenario.ownershipInvalidTarget) {
      throw ValidationException('Invalid ownership transfer target');
    }
    final newOwner = tenant.members[memberIndex];
    final updatedMembers = tenant.members
        .map(
          (m) => PlatformTenantMemberDto(
            userId: m.userId,
            fullName: m.fullName,
            email: m.email,
            roleLabel: m.roleLabel,
            isOwner: m.userId == command.newOwnerUserId,
          ),
        )
        .toList();
    _tenants[index] = PlatformTenantDetailDto(
      tenantId: tenant.tenantId,
      name: tenant.name,
      code: tenant.code,
      status: tenant.status,
      createdAt: tenant.createdAt,
      ownerUserId: newOwner.userId,
      ownerName: newOwner.fullName,
      ownerEmail: newOwner.email,
      ownerRoleLabel: newOwner.roleLabel,
      activatedAt: tenant.activatedAt,
      suspendedAt: tenant.suspendedAt,
      suspendedBy: tenant.suspendedBy,
      suspendReason: tenant.suspendReason,
      closedAt: tenant.closedAt,
      closedBy: tenant.closedBy,
      closeReason: tenant.closeReason,
      members: updatedMembers,
    );
    _ownershipTransferKeys.add(command.idempotencyKey);
    return Future.value(null as TResult);
  }

  Future<TResult> _handleSearchAudit<TResult>(
    SearchPlatformAuditLogsQuery query,
  ) {
    _requirePlatformView();
    Iterable<PlatformAuditLogDetailDto> filtered = _auditLogs;
    if (query.status != null) {
      filtered = filtered.where((a) => a.status == query.status);
    }
    final q = query.query?.trim().toLowerCase();
    if (q != null && q.isNotEmpty) {
      filtered = filtered.where(
        (a) =>
            a.title.toLowerCase().contains(q) ||
            a.actionCode.toLowerCase().contains(q) ||
            a.actorName.toLowerCase().contains(q) ||
            a.targetOrgName.toLowerCase().contains(q),
      );
    }
    final summaries = filtered
        .map(
          (a) => PlatformAuditLogSummaryDto(
            id: a.id,
            title: a.title,
            actionCode: a.actionCode,
            status: a.status,
            actorName: a.actorName,
            actorRole: a.actorRole,
            targetOrgName: a.targetOrgName,
            targetOrgCode: a.targetOrgCode,
            timestamp: a.timestamp,
            sourceApp: a.sourceApp,
          ),
        )
        .toList();
    return Future.value(summaries as TResult);
  }

  Future<TResult> _handleGetAuditDetail<TResult>(
    GetPlatformAuditLogQuery query,
  ) {
    _requirePlatformView();
    final index = _auditLogs.indexWhere((a) => a.id == query.auditLogId);
    if (index == -1) {
      throw ValidationException('Audit log not found: ${query.auditLogId}');
    }
    return Future.value(_auditLogs[index] as TResult);
  }
}
