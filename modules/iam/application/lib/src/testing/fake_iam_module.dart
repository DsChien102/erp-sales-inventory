import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../authentication/sign_in/sign_in_command.dart';
import '../authentication/sign_out/sign_out_command.dart';
import '../authentication/get_current_session/get_current_session_query.dart';
import '../contracts/i_iam_module.dart';
import '../dto/accessible_tenant_dto.dart';
import '../dto/platform_audit_log_detail_dto.dart';
import '../dto/tenant_context_dto.dart';
import '../dto/platform_audit_log_status.dart';
import '../dto/platform_audit_log_summary_dto.dart';
import '../dto/platform_tenant_detail_dto.dart';
import '../dto/platform_tenant_member_dto.dart';
import '../dto/platform_tenant_summary_dto.dart';
import '../dto/platform_user_detail_dto.dart';
import '../dto/platform_user_membership_dto.dart';
import '../dto/platform_user_status.dart';
import '../dto/platform_user_summary_dto.dart';
import '../dto/session_dto.dart';
import '../dto/tenant_activation_result_dto.dart';
import '../dto/tenant_audit_log_detail_dto.dart';
import '../dto/tenant_audit_log_result.dart';
import '../dto/tenant_audit_log_search_page_dto.dart';
import '../dto/tenant_audit_log_summary_dto.dart';
import '../dto/tenant_dto.dart';
import '../dto/tenant_legal_profile_dto.dart';
import '../dto/tenant_member_detail_dto.dart';
import '../dto/tenant_onboarding_operation_dto.dart';
import '../dto/tenant_onboarding_result_dto.dart';
import '../dto/tenant_readiness_dto.dart';
import '../dto/upsert_legal_profile_result_dto.dart';
import '../dto/password_reset_request_result_dto.dart';
import '../dto/password_reset_verify_result_dto.dart';
import '../dto/password_reset_completion_result_dto.dart';
import '../dto/duplicate_tax_code_warning_dto.dart';
import '../dto/sign_out_result_dto.dart';
import '../shared/iam_blocked_codes.dart';
import '../shared/iam_blocked_exception.dart';
import '../shared/tenant_readiness_issue_codes.dart';
import '../identity/commands/complete_my_password_reset/complete_my_password_reset_command.dart';
import '../identity/commands/request_my_password_reset/request_my_password_reset_command.dart';
import '../identity/commands/resend_my_password_reset/resend_my_password_reset_command.dart';
import '../identity/commands/update_my_identity_profile/update_my_identity_profile_command.dart';
import '../identity/commands/verify_my_password_reset/verify_my_password_reset_command.dart';
import '../identity/queries/get_my_identity_profile/get_my_identity_profile_query.dart';
import '../identity/shared/my_identity_profile_dto.dart';
import '../tenant/activate_tenant/activate_tenant_command.dart';
import '../tenant/deactivate_membership/deactivate_membership_command.dart';
import '../tenant/get_tenant/get_tenant_query.dart';
import '../tenant/get_tenant_audit_log/get_tenant_audit_log_query.dart';
import '../tenant/get_tenant_member/get_tenant_member_query.dart';
import '../tenant/get_tenant_readiness/get_tenant_readiness_query.dart';
import '../tenant/reactivate_membership/reactivate_membership_command.dart';
import '../tenant/remove_membership/remove_membership_command.dart';
import '../tenant/search_tenant_audit_logs/search_tenant_audit_logs_query.dart';
import '../tenant/update_tenant_profile/update_tenant_profile_command.dart';
import '../tenant/upsert_legal_profile/upsert_legal_profile_command.dart';
import '../platform/create_tenant_onboarding/create_tenant_onboarding_command.dart';
import '../platform/get_tenant_onboarding_operation/get_tenant_onboarding_operation_query.dart';
import '../platform/retry_tenant_onboarding_operation/retry_tenant_onboarding_operation_command.dart';
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
import '../dto/cursor_page_dto.dart';
import '../dto/tenant_member_dto.dart';
import '../dto/assignable_role_option_dto.dart';
import '../invitation/accept_invitation/accept_invitation_command.dart';
import '../invitation/create_invitation/create_invitation_command.dart';
import '../invitation/decline_invitation/decline_invitation_command.dart';
import '../invitation/get_invitation/get_invitation_query.dart';
import '../invitation/inspect_invitation_token/inspect_invitation_token_query.dart';
import '../invitation/list_assignable_invitation_roles/list_assignable_invitation_roles_query.dart';
import '../invitation/list_invitations/list_invitations_query.dart';
import '../invitation/resend_invitation/resend_invitation_command.dart';
import '../invitation/revoke_invitation/revoke_invitation_command.dart';
import '../invitation/register_from_invitation/register_from_invitation_command.dart';
import '../invitation/shared/invitation_detail_dto.dart';
import '../invitation/shared/invitation_registration_result_dto.dart';
import '../invitation/shared/invitation_summary_dto.dart';
import '../invitation/shared/invitation_token_inspection_dto.dart';
import '../tenant/get_tenant_context/get_tenant_context_query.dart';
import '../tenant/list_accessible_tenants/list_accessible_tenants_query.dart';
import '../tenant/list_tenant_members/list_tenant_members_query.dart';
import '../tenant/switch_tenant_context/switch_tenant_context_command.dart';
import 'fake_iam_scenario.dart';

/// In-memory IAM module for Admin FE/widget tests (TH-01 S15/S16 + EP-05 + auth).
final class FakeIamModule implements IIamModule {
  FakeIamModule({
    this.scenario = FakeIamScenario.usersSearchOk,
    this.onSignedIn,
    this.onSignedOut,
  }) {
    _seedUsers();
    _seedTenants();
    _seedAuditLogs();
    _seedMemberships();
    _seedTenantProfiles();
    _seedInvitations();
    _seedMyProfile();
    _seedAccessibleTenants();
  }

  final FakeIamScenario scenario;

  /// Optional hook so tests can update [ICurrentUser] / session after SignIn.
  final void Function(String email)? onSignedIn;

  /// Optional hook so tests can clear session after SignOut.
  final void Function()? onSignedOut;

  late List<PlatformUserDetailDto> _users;
  late List<PlatformTenantDetailDto> _tenants;
  late List<PlatformAuditLogDetailDto> _auditLogs;
  late List<AccessibleTenantDto> _accessibleTenants;
  late List<TenantMemberDetailDto> _memberships;
  late List<TenantDto> _tenantProfiles;
  late List<InvitationDetailDto> _invitations;
  late List<TenantMemberDto> _memberSummaries;
  late TenantAuditLogDetailDto _tenantAuditDetail;
  late List<TenantAuditLogSummaryDto> _tenantAuditSummaries;
  late MyIdentityProfileDto _myProfile;
  String? _passwordResetOperationId;
  bool _passwordResetVerified = false;
  bool _isAuthenticated = false;
  String? _authenticatedEmail;
  final Map<String, TenantActivationResultDto> _activationByKey = {};
  final Map<String, TenantOnboardingResultDto> _onboardingByKey = {};
  final Map<String, InvitationDetailDto> _invitationByIdempotency = {};
  final Map<String, String> _invitationPayloadByKey = {};
  final Map<String, TenantMemberDetailDto> _acceptByKey = {};
  final Map<String, InvitationDetailDto> _declineByKey = {};
  final Set<String> _consumedInviteTokens = {};
  final Set<String> _ownershipTransferKeys = {};
  final Map<String, String> _lifecycleIdempotency = {};
  final Map<String, TenantOnboardingOperationDto> _onboardingOps = {};

  String? currentTenantId;
  String? lastSelectedTenantId;
  bool get isAuthenticated => _isAuthenticated;

  int activationInviteCount = 0;
  int passwordResetCount = 0;
  int signInCount = 0;
  int signOutCount = 0;
  int switchTenantCount = 0;
  String? lastSignedInEmail;
  bool? lastSignInRequireTenantContext;

  void establishAuthenticatedSessionForTesting(String email) {
    _isAuthenticated = true;
    _authenticatedEmail = email;
  }

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
        lastActivityAt: DateTime(2026, 7, 13, 9, 18),
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
        activatedAt: DateTime(2026, 7, 2, 9, 15),
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
      PlatformTenantDetailDto(
        tenantId: 'org-005',
        name: 'Legacy Setup Suspended',
        code: 'TEN-LEGACY',
        status: TenantLifecycleStatus.suspended,
        createdAt: DateTime(2026, 8, 1, 8),
        ownerUserId: 'lan-le',
        ownerName: 'Lê Thị Lan',
        ownerEmail: 'lan@gmail.com',
        suspendedAt: DateTime(2026, 8, 2, 10),
        suspendedBy: 'Tùng Nguyễn',
        suspendReason: 'Legacy never activated tenant',
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

  void _seedMemberships() {
    _memberships = [
      TenantMemberDetailDto(
        membershipId: 'mem-owner-1',
        tenantId: 'org-001',
        userId: 'lan-le',
        role: 'owner',
        isOwner: true,
        isSoleOwner: true,
        status: MembershipStatus.active,
        version: 1,
        joinedAt: DateTime(2026, 1, 1),
      ),
      TenantMemberDetailDto(
        membershipId: 'mem-staff-1',
        tenantId: 'org-001',
        userId: 'hoa-tran',
        role: 'staff',
        isOwner: false,
        isSoleOwner: false,
        status: MembershipStatus.active,
        version: 1,
        joinedAt: DateTime(2026, 2, 1),
      ),
      TenantMemberDetailDto(
        membershipId: 'mem-inactive-1',
        tenantId: 'org-001',
        userId: 'minh-nguyen',
        role: 'staff',
        isOwner: false,
        isSoleOwner: false,
        status: MembershipStatus.inactive,
        version: 2,
        joinedAt: DateTime(2026, 3, 1),
        statusChangedAt: DateTime(2026, 3, 15),
      ),
      TenantMemberDetailDto(
        membershipId: 'mem-removed-1',
        tenantId: 'org-001',
        userId: 'old-user',
        role: 'staff',
        isOwner: false,
        isSoleOwner: false,
        status: MembershipStatus.removed,
        version: 3,
        joinedAt: DateTime(2026, 1, 10),
        statusChangedAt: DateTime(2026, 4, 1),
        removedAt: DateTime(2026, 4, 1),
      ),
    ];
    _memberSummaries = [
      TenantMemberDto(
        membershipId: 'mem-owner-1',
        userId: 'lan-le',
        displayName: 'Lan Le',
        email: 'lan@gmail.com',
        roleId: 'role-owner',
        roleLabel: 'Chủ cửa hàng',
        isOwner: true,
        status: 'active',
        joinedAt: DateTime(2026, 1, 1),
        version: 1,
      ),
      TenantMemberDto(
        membershipId: 'mem-staff-1',
        userId: 'hoa-tran',
        displayName: 'Hoa Tran',
        email: 'hoa@example.com',
        roleId: 'role-staff',
        roleLabel: 'Nhân viên bán hàng',
        isOwner: false,
        status: 'active',
        joinedAt: DateTime(2026, 2, 1),
        version: 1,
      ),
      TenantMemberDto(
        membershipId: 'mem-inactive-1',
        userId: 'minh-nguyen',
        displayName: 'Minh Nguyen',
        email: 'minh@example.com',
        roleId: 'role-staff',
        roleLabel: 'Nhân viên bán hàng',
        isOwner: false,
        status: 'inactive',
        joinedAt: DateTime(2026, 3, 1),
        version: 2,
      ),
    ];
  }

  void _seedInvitations() {
    _invitations = [
      InvitationDetailDto(
        invitationId: 'inv-1',
        inviteeEmail: 'invitee@example.com',
        initialRoleId: 'role-staff',
        initialRoleLabel: 'Nhân viên bán hàng',
        status: 'pending',
        expiresAt: DateTime.utc(2026, 8, 5),
        deliveryStatus: 'sent',
        deliveryCorrelationId: 'corr-inv-1',
        version: 1,
        createdAt: DateTime.utc(2026, 7, 29),
        createdBy: 'lan-le',
        lastSentAt: DateTime.utc(2026, 7, 29),
      ),
      InvitationDetailDto(
        invitationId: 'inv-expired',
        inviteeEmail: 'old@example.com',
        initialRoleId: 'role-staff',
        initialRoleLabel: 'Nhân viên bán hàng',
        status: 'expired',
        expiresAt: DateTime.utc(2026, 7, 1),
        deliveryStatus: 'sent',
        deliveryCorrelationId: 'corr-inv-exp',
        version: 2,
        createdAt: DateTime.utc(2026, 6, 20),
        createdBy: 'lan-le',
        lastSentAt: DateTime.utc(2026, 6, 20),
      ),
    ];
  }

  void _seedTenantProfiles() {
    _tenantProfiles = [
      TenantDto(
        tenantId: 'org-001',
        displayName: 'Mậu Hiên',
        status: TenantLifecycleStatus.active,
        version: 1,
        businessTimezone: 'Asia/Ho_Chi_Minh',
        baseCurrencyCode: 'VND',
        createdAt: DateTime(2026, 7, 10, 10),
        updatedAt: DateTime(2026, 7, 12, 16),
        contactEmail: 'contact@mauhien.vn',
        contactPhone: '+84901234567',
        contactAddressText: '123 Nguyen Trai, Ha Noi',
        activatedAt: DateTime(2026, 7, 12, 16, 45),
        legalProfile: TenantLegalProfileDto(
          tenantId: 'org-001',
          legalEntityType: LegalEntityType.enterprise,
          legalName: 'Mậu Hiên Co., Ltd',
          taxCode: '0123456789',
          version: 1,
          createdAt: DateTime(2026, 7, 11),
          updatedAt: DateTime(2026, 7, 11),
        ),
      ),
      TenantDto(
        tenantId: 'org-002',
        displayName: 'ASC Commerce',
        status: TenantLifecycleStatus.provisioning,
        version: 1,
        businessTimezone: 'Asia/Ho_Chi_Minh',
        baseCurrencyCode: 'VND',
        createdAt: DateTime(2026, 7, 13, 8, 20),
        updatedAt: DateTime(2026, 7, 13, 8, 20),
      ),
    ];
    _tenantAuditSummaries = [
      TenantAuditLogSummaryDto(
        auditLogId: 'AUD-T-001',
        eventCode: 'iam.tenant.profile.updated',
        result: TenantAuditLogResult.success,
        occurredAt: DateTime.utc(2026, 7, 13, 8),
        source: 'tenant-app',
        trackingId: 'TRK-001',
        actorUserId: 'lan-le',
        actorDisplayName: 'Lê Thị Lan',
        subjectType: 'tenant',
        subjectId: 'org-001',
      ),
    ];
    _tenantAuditDetail = TenantAuditLogDetailDto(
      auditLogId: 'AUD-T-001',
      tenantId: 'org-001',
      eventCode: 'iam.tenant.profile.updated',
      result: TenantAuditLogResult.success,
      occurredAt: DateTime.utc(2026, 7, 13, 8),
      source: 'tenant-app',
      trackingId: 'TRK-001',
      actorUnavailable: false,
      beforeRedacted: false,
      afterRedacted: false,
      actorUserId: 'lan-le',
      actorDisplayName: 'Lê Thị Lan',
      subjectType: 'tenant',
      subjectId: 'org-001',
      beforeState: 'display_name: Old',
      afterState: 'display_name: New',
    );
  }

  void _requirePlatformView() {
    if (scenario == FakeIamScenario.userForbidden403 ||
        scenario == FakeIamScenario.tenantForbidden403 ||
        scenario == FakeIamScenario.auditForbidden403) {
      throw ApplicationException('PLATFORM_PERMISSION_DENIED');
    }
  }

  void _seedAccessibleTenants() {
    const minhPhat = AccessibleTenantDto(
      tenantId: 'org-001',
      name: 'Thú y Minh Phát',
      roleLabel: 'Chủ cửa hàng',
      status: TenantLifecycleStatus.active,
    );
    const minhTam = AccessibleTenantDto(
      tenantId: 'org-002',
      name: 'Phòng khám Minh Tâm',
      roleLabel: 'Kế toán',
      status: TenantLifecycleStatus.active,
    );
    const ascSuspended = AccessibleTenantDto(
      tenantId: 'org-003',
      name: 'ASC Commerce',
      roleLabel: 'Nhân viên bán hàng',
      status: TenantLifecycleStatus.suspended,
    );
    const provisioning = AccessibleTenantDto(
      tenantId: 'org-005',
      name: 'Vet45 Provisioning',
      roleLabel: 'Chủ cửa hàng',
      status: TenantLifecycleStatus.provisioning,
    );
    const closed = AccessibleTenantDto(
      tenantId: 'org-004',
      name: 'Closed Clinic',
      roleLabel: 'Nhân viên',
      status: TenantLifecycleStatus.closed,
    );

    final multi = <AccessibleTenantDto>[minhPhat, minhTam, ascSuspended];

    switch (scenario) {
      case FakeIamScenario.tenantsSingle:
        _accessibleTenants = [minhPhat];
        currentTenantId = 'org-001';
        lastSelectedTenantId = 'org-001';
        break;
      case FakeIamScenario.tenantsProvisioning:
        _accessibleTenants = [minhPhat, provisioning];
        currentTenantId = 'org-001';
        lastSelectedTenantId = 'org-001';
        break;
      case FakeIamScenario.tenantsSuspendedDisabled:
      case FakeIamScenario.switchSuspended:
        _accessibleTenants = multi;
        currentTenantId = 'org-001';
        lastSelectedTenantId = 'org-001';
        break;
      case FakeIamScenario.switchClosed:
        _accessibleTenants = [minhPhat, closed];
        currentTenantId = 'org-001';
        lastSelectedTenantId = 'org-001';
        break;
      case FakeIamScenario.bootstrapInvalid:
        _accessibleTenants = [minhPhat, minhTam];
        currentTenantId = null;
        lastSelectedTenantId = 'org-gone';
        break;
      case FakeIamScenario.contextNone:
        _accessibleTenants = [minhPhat, minhTam];
        currentTenantId = null;
        lastSelectedTenantId = null;
        break;
      case FakeIamScenario.contextInvalidated:
        _accessibleTenants = [minhPhat, minhTam];
        currentTenantId = 'org-001';
        lastSelectedTenantId = 'org-001';
        break;
      case FakeIamScenario.bootstrapValid:
      case FakeIamScenario.tenantsMulti:
      case FakeIamScenario.switchOk:
      case FakeIamScenario.switchDenied:
      case FakeIamScenario.switchSameTenant:
      case FakeIamScenario.switchSessionFailure:
      case FakeIamScenario.switchPreferenceFailure:
      case FakeIamScenario.contextPermissionsRefreshed:
        _accessibleTenants = multi;
        currentTenantId = 'org-001';
        lastSelectedTenantId = 'org-001';
        break;
      case FakeIamScenario.tenantsClosedDisabled:
        _accessibleTenants = [minhPhat, closed];
        currentTenantId = 'org-001';
        lastSelectedTenantId = 'org-001';
        break;
      case FakeIamScenario.tenantsExcludesInactiveMembership:
        // Inactive memberships are omitted from the accessible list.
        _accessibleTenants = [minhPhat];
        currentTenantId = 'org-001';
        lastSelectedTenantId = 'org-001';
        break;
      default:
        _accessibleTenants = multi;
        currentTenantId = 'org-001';
        lastSelectedTenantId = 'org-001';
        break;
    }
  }

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    return switch (command) {
      SignInCommand c => _handleSignIn<TResult>(c),
      SignOutCommand _ => _handleSignOut<TResult>(),
      SendActivationInvitationCommand c => _handleActivationInvite<TResult>(c),
      RequestPlatformPasswordResetCommand c => _handlePasswordReset<TResult>(c),
      SuspendPlatformUserCommand c => _handleSuspendUser<TResult>(c),
      RestorePlatformUserCommand c => _handleRestoreUser<TResult>(c),
      CreateTenantOnboardingCommand c => _handleOnboarding<TResult>(c),
      RetryTenantOnboardingOperationCommand c => _handleRetryOnboardingOperation<TResult>(c),
      SuspendPlatformTenantCommand c => _handleSuspendTenant<TResult>(c),
      RestorePlatformTenantCommand c => _handleRestoreTenant<TResult>(c),
      TransferPlatformTenantOwnershipCommand c => _handleTransferOwnership<TResult>(c),
      SwitchTenantContextCommand c => _handleSwitchTenantContext<TResult>(c),
      UpdateMyIdentityProfileCommand c => _handleUpdateMyProfile<TResult>(c),
      RequestMyPasswordResetCommand _ => _handleRequestMyPasswordReset<TResult>(),
      ResendMyPasswordResetCommand c => _handleResendMyPasswordReset<TResult>(c),
      VerifyMyPasswordResetCommand c => _handleVerifyMyPasswordReset<TResult>(c),
      CompleteMyPasswordResetCommand c => _handleCompleteMyPasswordReset<TResult>(c),
      DeactivateMembershipCommand c => _handleDeactivateMembership<TResult>(c),
      ReactivateMembershipCommand c => _handleReactivateMembership<TResult>(c),
      RemoveMembershipCommand c => _handleRemoveMembership<TResult>(c),
      UpdateTenantProfileCommand c => _handleUpdateTenantProfile<TResult>(c),
      UpsertLegalProfileCommand c => _handleUpsertLegalProfile<TResult>(c),
      ActivateTenantCommand c => _handleActivateTenant<TResult>(c),
      CreateInvitationCommand c => _handleCreateInvitation<TResult>(c),
      ResendInvitationCommand c => _handleResendInvitation<TResult>(c),
      RevokeInvitationCommand c => _handleRevokeInvitation<TResult>(c),
      AcceptInvitationCommand c => _handleAcceptInvitation<TResult>(c),
      DeclineInvitationCommand c => _handleDeclineInvitation<TResult>(c),
      RegisterFromInvitationCommand c => _handleRegisterFromInvitation<TResult>(c),
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
      GetTenantOnboardingOperationQuery q => _handleGetOnboardingOperation<TResult>(q),
      SearchPlatformTenantsQuery q => _handleSearchTenants<TResult>(q),
      GetPlatformTenantQuery q => _handleGetTenantDetail<TResult>(q),
      ListPlatformTenantMembersQuery q => _handleListMembers<TResult>(q),
      SearchPlatformAuditLogsQuery q => _handleSearchAudit<TResult>(q),
      GetPlatformAuditLogQuery q => _handleGetAuditDetail<TResult>(q),
      GetTenantMemberQuery q => _handleGetTenantMember<TResult>(q),
      GetTenantQuery q => _handleGetTenant<TResult>(q),
      GetTenantReadinessQuery q => _handleGetTenantReadiness<TResult>(q),
      SearchTenantAuditLogsQuery q => _handleSearchTenantAudit<TResult>(q),
      GetTenantAuditLogQuery q => _handleGetTenantAuditDetail<TResult>(q),
      GetMyIdentityProfileQuery _ => _handleGetMyProfile<TResult>(),
      GetCurrentSessionQuery _ => _handleGetCurrentSession<TResult>(),
      ListTenantMembersQuery q => _handleListTenantMembers<TResult>(q),
      ListInvitationsQuery q => _handleListInvitations<TResult>(q),
      GetInvitationQuery q => _handleGetInvitation<TResult>(q),
      ListAssignableInvitationRolesQuery q => _handleListAssignableInvitationRoles<TResult>(q),
      InspectInvitationTokenQuery q => _handleInspectInvitationToken<TResult>(q),
      ListAccessibleTenantsQuery _ => _handleListAccessibleTenants<TResult>(),
      GetTenantContextQuery q => _handleGetTenantContext<TResult>(q),
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
    lastSignInRequireTenantContext = command.requireTenantContext;
    _isAuthenticated = true;
    _authenticatedEmail = command.email;
    onSignedIn?.call(command.email);
    return Future.value(null as TResult);
  }

  Future<TResult> _handleSignOut<TResult>() {
    signOutCount++;
    _isAuthenticated = false;
    _authenticatedEmail = null;
    onSignedOut?.call();
    if (scenario == FakeIamScenario.signOutRemoteError) {
      return Future.value(
        const SignOutResultDto(
              localCleared: true,
              remoteSucceeded: false,
            )
            as TResult,
      );
    }
    if (scenario == FakeIamScenario.authSignOutOk || scenario == FakeIamScenario.signOutOk) {
      return Future.value(
        const SignOutResultDto(
              localCleared: true,
              remoteSucceeded: true,
            )
            as TResult,
      );
    }
    return Future.value(
      const SignOutResultDto(
            localCleared: true,
            remoteSucceeded: true,
          )
          as TResult,
    );
  }

  Future<TResult> _handleGetCurrentSession<TResult>() {
    if (scenario == FakeIamScenario.authSessionExpired) {
      _isAuthenticated = false;
      _authenticatedEmail = null;
      throw const IamBlockedException(IamBlockedCodes.sessionExpired);
    }
    if (scenario == FakeIamScenario.authSessionOk && !_isAuthenticated) {
      _isAuthenticated = true;
      _authenticatedEmail ??= 'admin@vet45.local';
    }
    if (!_isAuthenticated) {
      return Future.value(const SessionDto(isAuthenticated: false) as TResult);
    }
    return Future.value(
      SessionDto(
            isAuthenticated: true,
            userId: 'fake-user',
            email: _authenticatedEmail,
            tenantId: currentTenantId,
            role: 'owner',
            permissions: const ['tenant.read'],
          )
          as TResult,
    );
  }

  Future<TResult> _handleSearchUsers<TResult>(SearchPlatformUsersQuery query) {
    _requirePlatformView();
    _isAuthenticated = true;
    _authenticatedEmail ??= 'admin@vet45.local';
    Iterable<PlatformUserDetailDto> filtered = _users;
    if (query.status != null) {
      filtered = filtered.where((u) => u.status == query.status);
    }
    final q = query.query?.trim().toLowerCase();
    if (q != null && q.isNotEmpty) {
      filtered = filtered.where(
        (u) => u.fullName.toLowerCase().contains(q) || u.email.toLowerCase().contains(q),
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
    final limit = query.limit;
    final start = int.tryParse(query.cursor ?? '') ?? 0;
    final page = summaries.skip(start).take(limit).toList();
    final next = start + limit < summaries.length ? '${start + limit}' : null;
    return Future.value(
      CursorPageDto(items: page, nextCursor: next) as TResult,
    );
  }

  Future<TResult> _handleGetUserDetail<TResult>(GetPlatformUserQuery query) {
    _requirePlatformView();
    _isAuthenticated = true;
    _authenticatedEmail ??= 'admin@vet45.local';
    final index = _users.indexWhere((u) => u.userId == query.userId);
    if (index == -1) {
      throw const IamBlockedException(IamBlockedCodes.resourceNotFound);
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
    if (scenario == FakeIamScenario.stepUpRequired) {
      throw const IamBlockedException(IamBlockedCodes.stepUpAuthRequired);
    }
    if (command.reason.trim().isEmpty) {
      throw ValidationException('Suspend reason is required');
    }
    final fingerprint =
        'suspend-user|${command.userId}|${command.reason}|${command.expectedVersion}';
    final prior = _lifecycleIdempotency[command.idempotencyKey];
    if (prior != null) {
      if (prior != fingerprint) {
        throw const IamBlockedException(IamBlockedCodes.idempotencyConflict);
      }
      return Future.value(null as TResult);
    }
    if (scenario == FakeIamScenario.suspendIdempotencyConflict) {
      _lifecycleIdempotency[command.idempotencyKey] = 'other-payload';
      throw const IamBlockedException(IamBlockedCodes.idempotencyConflict);
    }
    final index = _users.indexWhere((u) => u.userId == command.userId);
    if (index == -1) {
      throw ApplicationException('STATE_CHANGED');
    }
    if (scenario == FakeIamScenario.suspendStaleVersion ||
        _users[index].version != command.expectedVersion) {
      if (scenario == FakeIamScenario.suspendStaleVersion) {
        throw const IamBlockedException(IamBlockedCodes.stateChanged);
      }
    }
    final user = _users[index];
    _users[index] = PlatformUserDetailDto(
      userId: user.userId,
      fullName: user.fullName,
      email: user.email,
      status: PlatformUserStatus.suspended,
      emailVerified: user.emailVerified,
      createdAt: user.createdAt,
      version: user.version + 1,
      lastLoginAt: user.lastLoginAt,
      memberships: user.memberships,
    );
    _lifecycleIdempotency[command.idempotencyKey] = fingerprint;
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
    if (user.status != PlatformUserStatus.suspended && scenario == FakeIamScenario.restoreOk) {
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
        (scenario != FakeIamScenario.onboardingExistingUserOk && command.owner.isNewUser);

    final result = isNewUserScenario
        ? TenantOnboardingResultDto(
            // Hướng 1: new owner is not created — an activation code is issued.
            tenantId: 'tenant-new-1',
            tenantStatus: 'provisioning',
            correlationId: command.correlationId ?? 'corr-new-1',
            isNewUser: true,
            activationIssued: true,
          )
        : TenantOnboardingResultDto(
            tenantId: 'tenant-exist-1',
            ownerMembershipId: 'mem-exist-1',
            ownerUserId: command.owner.existingUserId ?? 'lan-le',
            tenantStatus: 'provisioning',
            correlationId: command.correlationId ?? 'corr-exist-1',
            isNewUser: false,
          );

    if (!_tenants.any((tenant) => tenant.tenantId == result.tenantId)) {
      final owner = command.owner;
      PlatformUserDetailDto? existingOwner;
      if (owner.isExisting) {
        for (final user in _users) {
          if (user.userId == owner.existingUserId) {
            existingOwner = user;
            break;
          }
        }
      }
      final ownerUserId = result.ownerUserId;
      // Hướng 1: a new owner has no account/membership yet (activation pending),
      // so the tenant shows no owner until the owner activates.
      if (ownerUserId == null) {
        _tenants.add(
          PlatformTenantDetailDto(
            tenantId: result.tenantId,
            name: command.organizationName.trim(),
            code: 'TEN-NEW',
            status: TenantLifecycleStatus.provisioning,
            createdAt: DateTime(2026, 8, 3, 9),
            ownerUserId: null,
            ownerName: '',
            ownerEmail: '',
            members: const [],
          ),
        );
      } else {
        final ownerName = existingOwner?.fullName ?? 'Chủ sở hữu';
        final ownerEmail = existingOwner?.email ?? 'owner@example.local';
        _tenants.add(
          PlatformTenantDetailDto(
            tenantId: result.tenantId,
            name: command.organizationName.trim(),
            code: 'TEN-NEW',
            status: TenantLifecycleStatus.provisioning,
            createdAt: DateTime(2026, 8, 3, 9),
            ownerUserId: ownerUserId,
            ownerName: ownerName,
            ownerEmail: ownerEmail,
            members: [
              PlatformTenantMemberDto(
                userId: ownerUserId,
                fullName: ownerName,
                email: ownerEmail,
                roleLabel: 'Chủ cửa hàng',
                isOwner: true,
              ),
            ],
          ),
        );
      }
    }

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
        (t) => t.name.toLowerCase().contains(q) || t.code.toLowerCase().contains(q),
      );
    }
    if (query.readinessState != null) {
      filtered = filtered.where(
        (_) => scenario != FakeIamScenario.tenantsSearchFiltered || true,
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
            readinessState: query.readinessState,
            warningCode: query.warningCode,
          ),
        )
        .toList();
    final limit = query.limit;
    final start = int.tryParse(query.cursor ?? '') ?? 0;
    final page = summaries.skip(start).take(limit).toList();
    final next = start + limit < summaries.length ? '${start + limit}' : null;
    return Future.value(
      CursorPageDto(items: page, nextCursor: next) as TResult,
    );
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
      throw const IamBlockedException(IamBlockedCodes.tenantStateInvalid);
    }
    if (tenant.status != TenantLifecycleStatus.active) {
      throw const IamBlockedException(IamBlockedCodes.tenantStateInvalid);
    }
    final suspendedAt = DateTime.now();
    _tenants[index] = PlatformTenantDetailDto(
      tenantId: tenant.tenantId,
      name: tenant.name,
      code: tenant.code,
      status: TenantLifecycleStatus.suspended,
      version: tenant.version + 1,
      createdAt: tenant.createdAt,
      ownerUserId: tenant.ownerUserId,
      ownerName: tenant.ownerName,
      ownerEmail: tenant.ownerEmail,
      ownerRoleLabel: tenant.ownerRoleLabel,
      activatedAt: tenant.activatedAt,
      lastActivityAt: suspendedAt,
      suspendedAt: suspendedAt,
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
      throw const IamBlockedException(IamBlockedCodes.tenantStateInvalid);
    }
    if (tenant.status != TenantLifecycleStatus.suspended) {
      throw const IamBlockedException(IamBlockedCodes.tenantStateInvalid);
    }
    if (tenant.activatedAt == null) {
      throw const IamBlockedException(IamBlockedCodes.tenantStateInvalid);
    }
    _tenants[index] = PlatformTenantDetailDto(
      tenantId: tenant.tenantId,
      name: tenant.name,
      code: tenant.code,
      status: TenantLifecycleStatus.active,
      version: tenant.version + 1,
      createdAt: tenant.createdAt,
      ownerUserId: tenant.ownerUserId,
      ownerName: tenant.ownerName,
      ownerEmail: tenant.ownerEmail,
      ownerRoleLabel: tenant.ownerRoleLabel,
      activatedAt: tenant.activatedAt,
      lastActivityAt: DateTime.now(),
      members: tenant.members,
    );
    return Future.value(null as TResult);
  }

  Future<TResult> _handleTransferOwnership<TResult>(
    TransferPlatformTenantOwnershipCommand command,
  ) {
    _requirePlatformView();
    if (scenario == FakeIamScenario.stepUpRequired) {
      throw const IamBlockedException(IamBlockedCodes.stepUpAuthRequired);
    }
    final fingerprint =
        'transfer|${command.tenantId}|${command.newOwnerUserId}|${command.expectedVersion}';
    final prior = _lifecycleIdempotency[command.idempotencyKey];
    if (prior != null) {
      if (prior != fingerprint || scenario == FakeIamScenario.ownershipIdempotencyConflict) {
        throw const IamBlockedException(IamBlockedCodes.idempotencyConflict);
      }
      return Future.value(null as TResult);
    }
    if (scenario == FakeIamScenario.ownershipIdempotencyConflict) {
      throw const IamBlockedException(IamBlockedCodes.idempotencyConflict);
    }
    if (_ownershipTransferKeys.contains(command.idempotencyKey)) {
      return Future.value(null as TResult);
    }
    final index = _tenants.indexWhere((t) => t.tenantId == command.tenantId);
    if (index == -1) {
      throw ApplicationException('STATE_CHANGED');
    }
    final tenant = _tenants[index];
    if (tenant.status == TenantLifecycleStatus.closed) {
      throw const IamBlockedException(IamBlockedCodes.tenantStateInvalid);
    }
    final memberIndex = tenant.members.indexWhere(
      (m) => m.userId == command.newOwnerUserId,
    );
    if (memberIndex == -1 || scenario == FakeIamScenario.ownershipInvalidTarget) {
      throw const IamBlockedException(IamBlockedCodes.ownerTargetInvalid);
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
    _lifecycleIdempotency[command.idempotencyKey] = fingerprint;
    return Future.value(null as TResult);
  }

  Future<TResult> _handleSearchAudit<TResult>(
    SearchPlatformAuditLogsQuery query,
  ) {
    _requirePlatformView();
    Iterable<PlatformAuditLogDetailDto> filtered = _auditLogs;
    if (query.result != null) {
      filtered = filtered.where(
        (a) => a.status.name == query.result || a.status.toString().endsWith(query.result!),
      );
    }
    if (query.action != null) {
      filtered = filtered.where((a) => a.actionCode == query.action);
    }
    if (query.source != null) {
      filtered = filtered.where((a) => a.sourceApp == query.source);
    }
    if (query.correlationId != null) {
      filtered = filtered.where((a) => a.correlationId == query.correlationId);
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
    final limit = query.limit;
    final start = int.tryParse(query.cursor ?? '') ?? 0;
    final page = summaries.skip(start).take(limit).toList();
    final next = start + limit < summaries.length ? '${start + limit}' : null;
    return Future.value(
      CursorPageDto(items: page, nextCursor: next) as TResult,
    );
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

  Future<TResult> _handleGetTenantMember<TResult>(GetTenantMemberQuery query) {
    if (scenario == FakeIamScenario.memberNotFound) {
      throw const IamBlockedException(IamBlockedCodes.resourceNotFound);
    }
    final member = _findMembership(query.tenantId, query.membershipId);
    return Future.value(member as TResult);
  }

  Future<TResult> _handleDeactivateMembership<TResult>(
    DeactivateMembershipCommand command,
  ) {
    if (scenario == FakeIamScenario.memberForbidden) {
      throw const IamBlockedException(IamBlockedCodes.permissionDenied);
    }
    if (scenario == FakeIamScenario.memberLastOwnerProtected) {
      throw const IamBlockedException(IamBlockedCodes.lastOwnerProtected);
    }
    if (scenario == FakeIamScenario.memberStateChanged) {
      throw const IamBlockedException(IamBlockedCodes.stateChanged);
    }
    final index = _membershipIndex(command.tenantId, command.membershipId);
    final current = _memberships[index];
    if (current.version != command.expectedVersion) {
      throw const IamBlockedException(IamBlockedCodes.stateChanged);
    }
    if (current.isSoleOwner) {
      throw const IamBlockedException(IamBlockedCodes.lastOwnerProtected);
    }
    final updated = TenantMemberDetailDto(
      membershipId: current.membershipId,
      tenantId: current.tenantId,
      userId: current.userId,
      role: current.role,
      isOwner: current.isOwner,
      isSoleOwner: current.isSoleOwner,
      status: MembershipStatus.inactive,
      version: current.version + 1,
      joinedAt: current.joinedAt,
      statusChangedAt: DateTime.now(),
    );
    _memberships[index] = updated;
    return Future.value(updated as TResult);
  }

  Future<TResult> _handleReactivateMembership<TResult>(
    ReactivateMembershipCommand command,
  ) {
    if (scenario == FakeIamScenario.memberForbidden) {
      throw const IamBlockedException(IamBlockedCodes.permissionDenied);
    }
    if (scenario == FakeIamScenario.memberRemovedTerminal) {
      throw const IamBlockedException(IamBlockedCodes.membershipRemoved);
    }
    if (scenario == FakeIamScenario.memberStateChanged) {
      throw const IamBlockedException(IamBlockedCodes.stateChanged);
    }
    final index = _membershipIndex(command.tenantId, command.membershipId);
    final current = _memberships[index];
    if (current.status == MembershipStatus.removed) {
      throw const IamBlockedException(IamBlockedCodes.membershipRemoved);
    }
    if (current.version != command.expectedVersion) {
      throw const IamBlockedException(IamBlockedCodes.stateChanged);
    }
    final updated = TenantMemberDetailDto(
      membershipId: current.membershipId,
      tenantId: current.tenantId,
      userId: current.userId,
      role: current.role,
      isOwner: current.isOwner,
      isSoleOwner: current.isSoleOwner,
      status: MembershipStatus.active,
      version: current.version + 1,
      joinedAt: current.joinedAt,
      statusChangedAt: DateTime.now(),
    );
    _memberships[index] = updated;
    return Future.value(updated as TResult);
  }

  Future<TResult> _handleRemoveMembership<TResult>(
    RemoveMembershipCommand command,
  ) {
    if (scenario == FakeIamScenario.memberForbidden) {
      throw const IamBlockedException(IamBlockedCodes.permissionDenied);
    }
    if (scenario == FakeIamScenario.memberLastOwnerProtected) {
      throw const IamBlockedException(IamBlockedCodes.lastOwnerProtected);
    }
    final index = _membershipIndex(command.tenantId, command.membershipId);
    final current = _memberships[index];
    if (current.isSoleOwner) {
      throw const IamBlockedException(IamBlockedCodes.lastOwnerProtected);
    }
    if (current.version != command.expectedVersion) {
      throw const IamBlockedException(IamBlockedCodes.stateChanged);
    }
    final now = DateTime.now();
    final updated = TenantMemberDetailDto(
      membershipId: current.membershipId,
      tenantId: current.tenantId,
      userId: current.userId,
      role: current.role,
      isOwner: current.isOwner,
      isSoleOwner: current.isSoleOwner,
      status: MembershipStatus.removed,
      version: current.version + 1,
      joinedAt: current.joinedAt,
      statusChangedAt: now,
      removedAt: now,
    );
    _memberships[index] = updated;
    return Future.value(updated as TResult);
  }

  TenantMemberDetailDto _findMembership(String tenantId, String membershipId) {
    final index = _memberships.indexWhere(
      (m) => m.tenantId == tenantId && m.membershipId == membershipId,
    );
    if (index == -1) {
      throw const IamBlockedException(IamBlockedCodes.resourceNotFound);
    }
    return _memberships[index];
  }

  int _membershipIndex(String tenantId, String membershipId) {
    final index = _memberships.indexWhere(
      (m) => m.tenantId == tenantId && m.membershipId == membershipId,
    );
    if (index == -1) {
      throw const IamBlockedException(IamBlockedCodes.resourceNotFound);
    }
    return index;
  }

  int _tenantProfileIndex(String tenantId) {
    final index = _tenantProfiles.indexWhere((t) => t.tenantId == tenantId);
    if (index == -1) {
      throw const IamBlockedException(IamBlockedCodes.resourceNotFound);
    }
    return index;
  }

  Future<TResult> _handleGetTenant<TResult>(GetTenantQuery query) {
    if (scenario == FakeIamScenario.tenantProfileForbidden) {
      throw const IamBlockedException(IamBlockedCodes.permissionDenied);
    }
    if (scenario == FakeIamScenario.tenantProfileNotFound) {
      throw const IamBlockedException(IamBlockedCodes.resourceNotFound);
    }
    final index = _tenantProfiles.indexWhere(
      (t) => t.tenantId == query.tenantId,
    );
    if (index == -1) {
      throw const IamBlockedException(IamBlockedCodes.resourceNotFound);
    }
    return Future.value(_tenantProfiles[index] as TResult);
  }

  Future<TResult> _handleUpdateTenantProfile<TResult>(
    UpdateTenantProfileCommand command,
  ) {
    if (scenario == FakeIamScenario.tenantProfileForbidden) {
      throw const IamBlockedException(IamBlockedCodes.permissionDenied);
    }
    if (scenario == FakeIamScenario.tenantProfileNotFound) {
      throw const IamBlockedException(IamBlockedCodes.resourceNotFound);
    }
    if (scenario == FakeIamScenario.tenantProfileValidation) {
      throw const IamBlockedException(IamBlockedCodes.validationError);
    }
    if (scenario == FakeIamScenario.tenantProfileStale) {
      throw const IamBlockedException(IamBlockedCodes.stateChanged);
    }
    final index = _tenantProfileIndex(command.tenantId);
    final current = _tenantProfiles[index];
    if (current.version != command.expectedVersion) {
      throw const IamBlockedException(IamBlockedCodes.stateChanged);
    }
    final updated = TenantDto(
      tenantId: current.tenantId,
      displayName: command.displayName,
      status: current.status,
      version: current.version + 1,
      businessTimezone: current.businessTimezone,
      baseCurrencyCode: current.baseCurrencyCode,
      createdAt: current.createdAt,
      updatedAt: DateTime.now(),
      contactEmail: command.contactEmail,
      contactPhone: command.contactPhone,
      contactAddressText: command.contactAddressText,
      provinceCode: command.provinceCode,
      communeCode: command.communeCode,
      activatedAt: current.activatedAt,
      legalProfile: current.legalProfile,
    );
    _tenantProfiles[index] = updated;
    return Future.value(updated as TResult);
  }

  Future<TResult> _handleUpsertLegalProfile<TResult>(
    UpsertLegalProfileCommand command,
  ) {
    if (scenario == FakeIamScenario.legalDuplicateWarning && !command.allowDuplicateTaxCode) {
      final index = _tenantProfileIndex(command.tenantId);
      return Future.value(
        UpsertLegalProfileResultDto.warning(
              tenantVersion: _tenantProfiles[index].version,
              warning: const DuplicateTaxCodeWarningDto(
                code: DuplicateTaxCodeWarningDto.codeValue,
                message: 'Tax code already used by another organization',
              ),
            )
            as TResult,
      );
    }
    final index = _tenantProfileIndex(command.tenantId);
    final current = _tenantProfiles[index];
    if (current.version != command.expectedVersion) {
      throw const IamBlockedException(IamBlockedCodes.stateChanged);
    }
    final profile = TenantLegalProfileDto(
      tenantId: command.tenantId,
      legalEntityType:
          LegalEntityTypeCodes.fromCode(command.legalEntityType) ?? LegalEntityType.enterprise,
      legalName: command.legalName,
      taxCode: command.taxCode,
      version: (current.legalProfile?.version ?? 0) + 1,
      createdAt: current.legalProfile?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      registeredAddressText: command.registeredAddressText,
      provinceCode: command.provinceCode,
      communeCode: command.communeCode,
    );
    _tenantProfiles[index] = TenantDto(
      tenantId: current.tenantId,
      displayName: current.displayName,
      status: current.status,
      version: current.version + 1,
      businessTimezone: current.businessTimezone,
      baseCurrencyCode: current.baseCurrencyCode,
      createdAt: current.createdAt,
      updatedAt: DateTime.now(),
      contactEmail: current.contactEmail,
      contactPhone: current.contactPhone,
      contactAddressText: current.contactAddressText,
      provinceCode: current.provinceCode,
      communeCode: current.communeCode,
      activatedAt: current.activatedAt,
      legalProfile: profile,
    );
    return Future.value(
      UpsertLegalProfileResultDto.saved(
            profile: profile,
            tenantVersion: current.version + 1,
          )
          as TResult,
    );
  }

  Future<TResult> _handleGetTenantReadiness<TResult>(
    GetTenantReadinessQuery query,
  ) {
    final index = _tenantProfileIndex(query.tenantId);
    final tenant = _tenantProfiles[index];
    if (scenario == FakeIamScenario.readinessBlocked) {
      return Future.value(
        TenantReadinessDto(
              tenantId: tenant.tenantId,
              status: tenant.status,
              blockers: const [
                TenantReadinessIssueCodes.contactEmailMissingOrInvalid,
                TenantReadinessIssueCodes.ownerEmailUnverified,
              ],
              warnings: const [],
              evaluatedAt: DateTime.now().toUtc(),
              tenantVersion: tenant.version,
              canActivate: false,
            )
            as TResult,
      );
    }
    if (scenario == FakeIamScenario.readinessWarningOnly) {
      return Future.value(
        TenantReadinessDto(
              tenantId: tenant.tenantId,
              status: TenantLifecycleStatus.provisioning,
              blockers: const [],
              warnings: const [TenantReadinessIssueCodes.legalProfileMissing],
              evaluatedAt: DateTime.now().toUtc(),
              tenantVersion: tenant.version,
              canActivate: true,
            )
            as TResult,
      );
    }
    final warnings = tenant.legalProfile == null
        ? const [TenantReadinessIssueCodes.legalProfileMissing]
        : const <String>[];
    return Future.value(
      TenantReadinessDto(
            tenantId: tenant.tenantId,
            status: tenant.status,
            blockers: const [],
            warnings: warnings,
            evaluatedAt: DateTime.now().toUtc(),
            tenantVersion: tenant.version,
            canActivate: tenant.status == TenantLifecycleStatus.provisioning,
          )
          as TResult,
    );
  }

  Future<TResult> _handleActivateTenant<TResult>(
    ActivateTenantCommand command,
  ) {
    if (scenario == FakeIamScenario.activateReadinessBlocked) {
      throw const IamBlockedException(
        IamBlockedCodes.readinessBlocked,
        details: {
          'blockers': [TenantReadinessIssueCodes.contactAddressMissing],
        },
      );
    }
    if (scenario == FakeIamScenario.activateIdempotencyConflict) {
      throw const IamBlockedException(IamBlockedCodes.idempotencyConflict);
    }
    final existing = _activationByKey[command.idempotencyKey];
    if (existing != null) {
      return Future.value(existing as TResult);
    }
    final index = _tenantProfileIndex(command.tenantId);
    final tenant = _tenantProfiles[index];
    if (tenant.status != TenantLifecycleStatus.provisioning &&
        scenario == FakeIamScenario.activateAlreadyActive) {
      throw const IamBlockedException(IamBlockedCodes.tenantStateInvalid);
    }
    if (tenant.version != command.expectedVersion) {
      throw const IamBlockedException(IamBlockedCodes.stateChanged);
    }
    final activatedAt = DateTime.now().toUtc();
    _tenantProfiles[index] = TenantDto(
      tenantId: tenant.tenantId,
      displayName: tenant.displayName,
      status: TenantLifecycleStatus.active,
      version: tenant.version + 1,
      businessTimezone: tenant.businessTimezone,
      baseCurrencyCode: tenant.baseCurrencyCode,
      createdAt: tenant.createdAt,
      updatedAt: activatedAt,
      contactEmail: tenant.contactEmail,
      contactPhone: tenant.contactPhone,
      contactAddressText: tenant.contactAddressText,
      provinceCode: tenant.provinceCode,
      communeCode: tenant.communeCode,
      activatedAt: activatedAt,
      legalProfile: tenant.legalProfile,
    );
    final result = TenantActivationResultDto(
      tenantId: tenant.tenantId,
      status: TenantLifecycleStatus.active,
      activatedAt: activatedAt,
      version: tenant.version + 1,
    );
    _activationByKey[command.idempotencyKey] = result;
    return Future.value(result as TResult);
  }

  Future<TResult> _handleSearchTenantAudit<TResult>(
    SearchTenantAuditLogsQuery query,
  ) {
    if (scenario == FakeIamScenario.tenantAuditForbidden) {
      throw const IamBlockedException(IamBlockedCodes.permissionDenied);
    }
    if (scenario == FakeIamScenario.tenantAuditProviderError) {
      throw const IamBlockedException(IamBlockedCodes.systemError);
    }
    if (scenario == FakeIamScenario.tenantAuditEmpty) {
      return Future.value(
        const TenantAuditLogSearchPageDto(items: []) as TResult,
      );
    }
    if (scenario == FakeIamScenario.tenantAuditCrossTenant) {
      return Future.value(
        const TenantAuditLogSearchPageDto(items: []) as TResult,
      );
    }
    var items = _tenantAuditSummaries.toList();
    final eventCode = query.eventCode;
    if (eventCode != null) {
      items = items.where((s) => s.eventCode == eventCode).toList();
    }
    final result = query.result;
    if (result != null) {
      items = items.where((s) => s.result.code == result).toList();
    }
    final subjectType = query.subjectType;
    if (subjectType != null) {
      items = items.where((s) => s.subjectType == subjectType).toList();
    }
    final actorUserId = query.actorUserId;
    if (actorUserId != null) {
      items = items.where((s) => s.actorUserId == actorUserId).toList();
    }
    // Cursor-paginated fake: first page exposes opaque cursor; next page clears it.
    final nextCursor = query.cursor == null && items.isNotEmpty ? 'opaque-next-cursor' : null;
    return Future.value(
      TenantAuditLogSearchPageDto(items: items, nextCursor: nextCursor) as TResult,
    );
  }

  Future<TResult> _handleGetTenantAuditDetail<TResult>(
    GetTenantAuditLogQuery query,
  ) {
    if (scenario == FakeIamScenario.tenantAuditForbidden) {
      throw const IamBlockedException(IamBlockedCodes.permissionDenied);
    }
    if (scenario == FakeIamScenario.tenantAuditProviderError) {
      throw const IamBlockedException(IamBlockedCodes.systemError);
    }
    if (scenario == FakeIamScenario.tenantAuditActorUnavailable) {
      return Future.value(
        TenantAuditLogDetailDto(
              auditLogId: query.auditLogId,
              tenantId: query.tenantId,
              eventCode: _tenantAuditDetail.eventCode,
              result: _tenantAuditDetail.result,
              occurredAt: _tenantAuditDetail.occurredAt,
              source: _tenantAuditDetail.source,
              trackingId: _tenantAuditDetail.trackingId,
              actorUnavailable: true,
              beforeRedacted: _tenantAuditDetail.beforeRedacted,
              afterRedacted: _tenantAuditDetail.afterRedacted,
              subjectType: _tenantAuditDetail.subjectType,
              subjectId: _tenantAuditDetail.subjectId,
            )
            as TResult,
      );
    }
    if (scenario == FakeIamScenario.tenantAuditCrossTenant) {
      throw const IamBlockedException(IamBlockedCodes.resourceNotFound);
    }
    if (query.auditLogId == 'AUD-REDACTED') {
      return Future.value(
        TenantAuditLogDetailDto(
              auditLogId: query.auditLogId,
              tenantId: query.tenantId,
              eventCode: _tenantAuditDetail.eventCode,
              result: _tenantAuditDetail.result,
              occurredAt: _tenantAuditDetail.occurredAt,
              source: _tenantAuditDetail.source,
              trackingId: _tenantAuditDetail.trackingId,
              actorUnavailable: false,
              beforeRedacted: true,
              afterRedacted: true,
              actorUserId: _tenantAuditDetail.actorUserId,
              actorDisplayName: _tenantAuditDetail.actorDisplayName,
              subjectType: _tenantAuditDetail.subjectType,
              subjectId: _tenantAuditDetail.subjectId,
            )
            as TResult,
      );
    }
    if (query.auditLogId != _tenantAuditDetail.auditLogId ||
        query.tenantId != _tenantAuditDetail.tenantId) {
      throw const IamBlockedException(IamBlockedCodes.resourceNotFound);
    }
    return Future.value(_tenantAuditDetail as TResult);
  }

  Future<TResult> _handleListTenantMembers<TResult>(
    ListTenantMembersQuery query,
  ) {
    if (scenario == FakeIamScenario.memberInvitationForbidden) {
      throw const IamBlockedException(IamBlockedCodes.permissionDenied);
    }
    var rows = _memberSummaries.toList(growable: false);
    final search = query.search?.trim().toLowerCase();
    if (search != null && search.isNotEmpty) {
      rows = rows
          .where(
            (m) =>
                m.displayName.toLowerCase().contains(search) ||
                m.email.toLowerCase().contains(search),
          )
          .toList(growable: false);
    }
    final status = query.status?.trim();
    if (status != null && status.isNotEmpty) {
      rows = rows.where((m) => m.status == status).toList(growable: false);
    }
    if (scenario == FakeIamScenario.membersFilterInactive) {
      rows = rows.where((m) => m.status == 'inactive').toList(growable: false);
    }
    final limit = query.limit.clamp(1, 100);
    final page = rows.take(limit).toList(growable: false);
    return Future.value(
      CursorPageDto<TenantMemberDto>(
            items: page,
            nextCursor: rows.length > limit ? 'next' : null,
          )
          as TResult,
    );
  }

  Future<TResult> _handleListInvitations<TResult>(
    ListInvitationsQuery query,
  ) {
    if (scenario == FakeIamScenario.memberInvitationForbidden) {
      throw const IamBlockedException(IamBlockedCodes.permissionDenied);
    }
    var rows = _invitations.map((i) => i.toSummary()).toList(growable: false);
    final search = query.search?.trim().toLowerCase();
    if (search != null && search.isNotEmpty) {
      rows = rows
          .where((i) => i.inviteeEmail.toLowerCase().contains(search))
          .toList(growable: false);
    }
    final status = query.status?.trim();
    if (status != null && status.isNotEmpty) {
      rows = rows.where((i) => i.status == status).toList(growable: false);
    }
    if (scenario == FakeIamScenario.invitationsExpired) {
      rows = rows.where((i) => i.status == 'expired').toList(growable: false);
    }
    final limit = query.limit.clamp(1, 100);
    final page = rows.take(limit).toList(growable: false);
    return Future.value(
      CursorPageDto<InvitationSummaryDto>(
            items: page,
            nextCursor: rows.length > limit ? 'next' : null,
          )
          as TResult,
    );
  }

  Future<TResult> _handleListAssignableInvitationRoles<TResult>(
    ListAssignableInvitationRolesQuery query,
  ) {
    if (scenario == FakeIamScenario.memberInvitationForbidden ||
        scenario == FakeIamScenario.inviteForbidden) {
      throw const IamBlockedException(IamBlockedCodes.permissionDenied);
    }
    return Future.value(
      const <AssignableRoleOptionDto>[
            AssignableRoleOptionDto(
              roleId: 'role-staff',
              label: 'Nhân viên bán hàng',
            ),
            AssignableRoleOptionDto(
              roleId: 'role-warehouse',
              label: 'Thủ kho',
            ),
            AssignableRoleOptionDto(
              roleId: 'role-accountant',
              label: 'Kế toán',
            ),
            AssignableRoleOptionDto(
              roleId: 'role-manager',
              label: 'Quản lý',
            ),
          ]
          as TResult,
    );
  }

  Future<TResult> _handleGetInvitation<TResult>(GetInvitationQuery query) {
    if (scenario == FakeIamScenario.memberInvitationForbidden) {
      throw const IamBlockedException(IamBlockedCodes.permissionDenied);
    }
    if (scenario == FakeIamScenario.memberInvitationCrossTenantNotFound) {
      throw const IamBlockedException(IamBlockedCodes.resourceNotFound);
    }
    for (final row in _invitations) {
      if (row.invitationId == query.invitationId) {
        return Future.value(row as TResult);
      }
    }
    throw const IamBlockedException(IamBlockedCodes.resourceNotFound);
  }

  Future<TResult> _handleCreateInvitation<TResult>(
    CreateInvitationCommand command,
  ) async {
    if (scenario == FakeIamScenario.inviteForbidden ||
        scenario == FakeIamScenario.memberInvitationForbidden) {
      throw const IamBlockedException(IamBlockedCodes.permissionDenied);
    }
    if (scenario == FakeIamScenario.inviteDuplicateMembership) {
      throw const IamBlockedException(IamBlockedCodes.duplicateMembership);
    }
    if (scenario == FakeIamScenario.inviteInactiveMembership) {
      throw const IamBlockedException(IamBlockedCodes.membershipInactive);
    }
    if (scenario == FakeIamScenario.invitePendingExists) {
      throw const IamBlockedException(IamBlockedCodes.invitationPendingExists);
    }
    if (scenario == FakeIamScenario.inviteRoleNotAssignable) {
      throw const IamBlockedException(IamBlockedCodes.roleNotAssignable);
    }
    if (scenario == FakeIamScenario.inviteIdempotencyConflict) {
      throw const IamBlockedException(IamBlockedCodes.idempotencyConflict);
    }

    final email = command.inviteeEmail.trim().toLowerCase();
    final roleId = command.initialRoleId.trim();
    final key = command.idempotencyKey.trim();
    final payload = '${command.tenantId}|$email|$roleId';

    final existing = _invitationByIdempotency[key];
    if (existing != null) {
      if (_invitationPayloadByKey[key] != payload) {
        throw const IamBlockedException(IamBlockedCodes.idempotencyConflict);
      }
      return existing as TResult;
    }

    final now = DateTime.utc(2026, 7, 29, 12);
    final deliveryStatus = scenario == FakeIamScenario.inviteDeliveryFailed ? 'failed' : 'queued';
    final created = InvitationDetailDto(
      invitationId: 'inv-created-${_invitationByIdempotency.length + 1}',
      inviteeEmail: email,
      initialRoleId: roleId,
      initialRoleLabel: 'Nhân viên bán hàng',
      status: 'pending',
      expiresAt: now.add(const Duration(days: 7)),
      deliveryStatus: deliveryStatus,
      deliveryCorrelationId: 'corr-$key',
      version: 1,
      createdAt: now,
      createdBy: 'lan-le',
      lastSentAt: now,
    );
    _invitationByIdempotency[key] = created;
    _invitationPayloadByKey[key] = payload;
    _invitations = [..._invitations, created];
    return created as TResult;
  }

  InvitationDetailDto? _findInvitation(String invitationId) {
    for (final row in _invitations) {
      if (row.invitationId == invitationId) return row;
    }
    return null;
  }

  Future<TResult> _handleResendInvitation<TResult>(
    ResendInvitationCommand command,
  ) async {
    if (scenario == FakeIamScenario.invitationCrossTenantNotFound) {
      throw const IamBlockedException(IamBlockedCodes.resourceNotFound);
    }
    if (scenario == FakeIamScenario.invitationStateChanged) {
      throw const IamBlockedException(IamBlockedCodes.stateChanged);
    }
    if (scenario == FakeIamScenario.invitationTerminalReject) {
      throw const IamBlockedException(IamBlockedCodes.invitationAlreadyUsed);
    }

    final key = command.idempotencyKey.trim();
    final existing = _invitationByIdempotency[key];
    if (existing != null) {
      return existing as TResult;
    }

    final current = _findInvitation(command.invitationId);
    if (current == null) {
      throw const IamBlockedException(IamBlockedCodes.resourceNotFound);
    }
    if (current.version != command.expectedVersion) {
      throw const IamBlockedException(IamBlockedCodes.stateChanged);
    }
    if (current.status != 'pending') {
      throw const IamBlockedException(IamBlockedCodes.invitationAlreadyUsed);
    }

    final now = DateTime.utc(2026, 7, 30, 12);
    final deliveryStatus = scenario == FakeIamScenario.invitationResendDeliveryFailed
        ? 'failed'
        : 'queued';
    final resent = InvitationDetailDto(
      invitationId: current.invitationId,
      inviteeEmail: current.inviteeEmail,
      initialRoleId: current.initialRoleId,
      initialRoleLabel: current.initialRoleLabel,
      status: 'pending',
      expiresAt: now.add(const Duration(days: 7)),
      deliveryStatus: deliveryStatus,
      deliveryCorrelationId: 'corr-resend-$key',
      version: current.version + 1,
      createdAt: current.createdAt,
      createdBy: current.createdBy,
      lastSentAt: now,
    );
    _invitationByIdempotency[key] = resent;
    _invitations = [
      for (final row in _invitations)
        if (row.invitationId == resent.invitationId) resent else row,
    ];
    return resent as TResult;
  }

  Future<TResult> _handleRevokeInvitation<TResult>(
    RevokeInvitationCommand command,
  ) async {
    if (scenario == FakeIamScenario.invitationCrossTenantNotFound) {
      throw const IamBlockedException(IamBlockedCodes.resourceNotFound);
    }
    if (scenario == FakeIamScenario.invitationStateChanged) {
      throw const IamBlockedException(IamBlockedCodes.stateChanged);
    }
    if (scenario == FakeIamScenario.invitationTerminalReject) {
      throw const IamBlockedException(IamBlockedCodes.invitationAlreadyUsed);
    }

    final key = command.idempotencyKey.trim();
    final existing = _invitationByIdempotency[key];
    if (existing != null) {
      return existing as TResult;
    }

    final current = _findInvitation(command.invitationId);
    if (current == null) {
      throw const IamBlockedException(IamBlockedCodes.resourceNotFound);
    }
    if (current.version != command.expectedVersion) {
      throw const IamBlockedException(IamBlockedCodes.stateChanged);
    }
    if (current.status != 'pending') {
      throw const IamBlockedException(IamBlockedCodes.invitationAlreadyUsed);
    }

    final now = DateTime.utc(2026, 7, 30, 12);
    final revoked = InvitationDetailDto(
      invitationId: current.invitationId,
      inviteeEmail: current.inviteeEmail,
      initialRoleId: current.initialRoleId,
      initialRoleLabel: current.initialRoleLabel,
      status: 'revoked',
      expiresAt: current.expiresAt,
      deliveryStatus: current.deliveryStatus,
      deliveryCorrelationId: current.deliveryCorrelationId,
      version: current.version + 1,
      createdAt: current.createdAt,
      createdBy: current.createdBy,
      lastSentAt: current.lastSentAt,
      revokedAt: now,
    );
    _invitationByIdempotency[key] = revoked;
    _invitations = [
      for (final row in _invitations)
        if (row.invitationId == revoked.invitationId) revoked else row,
    ];
    return revoked as TResult;
  }

  InvitationTokenInspectionDto _defaultInspection({required bool accountExists}) {
    return InvitationTokenInspectionDto(
      tenantId: 'org-001',
      tenantName: 'Mậu Hiên',
      inviteeEmail: 'invitee@example.com',
      initialRoleId: 'role-staff',
      initialRoleLabel: 'Nhân viên bán hàng',
      expiresAt: DateTime.utc(2026, 8, 5),
      accountExists: accountExists,
    );
  }

  Future<TResult> _handleInspectInvitationToken<TResult>(
    InspectInvitationTokenQuery query,
  ) async {
    if (scenario == FakeIamScenario.inspectInvalidNoLeak ||
        scenario == FakeIamScenario.acceptRotatedToken) {
      throw const IamBlockedException(IamBlockedCodes.invitationTokenInvalid);
    }
    if (scenario == FakeIamScenario.acceptExpired) {
      throw const IamBlockedException(IamBlockedCodes.invitationExpired);
    }
    if (scenario == FakeIamScenario.acceptDeclined) {
      throw const IamBlockedException(IamBlockedCodes.invitationAlreadyUsed);
    }
    final exists =
        scenario == FakeIamScenario.inspectExistingAccount ||
        scenario == FakeIamScenario.acceptExistingAccountOk ||
        scenario == FakeIamScenario.acceptEmailMismatch ||
        scenario == FakeIamScenario.acceptRetryAfterIdentityCreated ||
        scenario == FakeIamScenario.acceptConcurrent ||
        scenario == FakeIamScenario.acceptTenantSuspended;
    if (scenario == FakeIamScenario.inspectNewAccount ||
        scenario == FakeIamScenario.registerAndAcceptOk ||
        scenario == FakeIamScenario.registerIdentityConflict) {
      return _defaultInspection(accountExists: false) as TResult;
    }
    return _defaultInspection(accountExists: exists) as TResult;
  }

  Future<TResult> _handleAcceptInvitation<TResult>(
    AcceptInvitationCommand command,
  ) async {
    if (scenario == FakeIamScenario.acceptEmailMismatch) {
      throw const IamBlockedException(IamBlockedCodes.invitationEmailMismatch);
    }
    if (scenario == FakeIamScenario.acceptExpired) {
      throw const IamBlockedException(IamBlockedCodes.invitationExpired);
    }
    if (scenario == FakeIamScenario.acceptRotatedToken ||
        scenario == FakeIamScenario.invitationOldTokenInvalid) {
      throw const IamBlockedException(IamBlockedCodes.invitationTokenInvalid);
    }
    if (scenario == FakeIamScenario.acceptDeclined ||
        scenario == FakeIamScenario.acceptConcurrent) {
      throw const IamBlockedException(IamBlockedCodes.invitationAlreadyUsed);
    }
    if (scenario == FakeIamScenario.acceptTenantSuspended) {
      throw const IamBlockedException(IamBlockedCodes.tenantSuspended);
    }

    final key = command.idempotencyKey.trim();
    final existing = _acceptByKey[key];
    if (existing != null) {
      return existing as TResult;
    }
    if (_consumedInviteTokens.contains(command.token.trim())) {
      throw const IamBlockedException(IamBlockedCodes.invitationAlreadyUsed);
    }

    final membership = TenantMemberDetailDto(
      membershipId: 'mem-accepted-1',
      tenantId: 'org-001',
      userId: 'invitee-user',
      role: 'staff',
      isOwner: false,
      isSoleOwner: false,
      status: MembershipStatus.active,
      version: 1,
      joinedAt: DateTime.utc(2026, 7, 30),
    );
    _acceptByKey[key] = membership;
    _consumedInviteTokens.add(command.token.trim());
    return membership as TResult;
  }

  Future<TResult> _handleDeclineInvitation<TResult>(
    DeclineInvitationCommand command,
  ) async {
    final key = command.idempotencyKey.trim();
    final existing = _declineByKey[key];
    if (existing != null || scenario == FakeIamScenario.declineIdempotentRetry) {
      if (existing != null) {
        return existing as TResult;
      }
    }
    if (scenario == FakeIamScenario.acceptExpired) {
      throw const IamBlockedException(IamBlockedCodes.invitationExpired);
    }
    if (scenario == FakeIamScenario.inspectInvalidNoLeak) {
      throw const IamBlockedException(IamBlockedCodes.invitationTokenInvalid);
    }

    final declined = InvitationDetailDto(
      invitationId: 'inv-1',
      inviteeEmail: 'invitee@example.com',
      initialRoleId: 'role-staff',
      initialRoleLabel: 'Nhân viên bán hàng',
      status: 'declined',
      expiresAt: DateTime.utc(2026, 8, 5),
      deliveryStatus: 'sent',
      deliveryCorrelationId: 'corr-inv-1',
      version: 2,
      createdAt: DateTime.utc(2026, 7, 29),
      createdBy: 'lan-le',
      declinedAt: DateTime.utc(2026, 7, 30),
    );
    _declineByKey[key] = declined;
    return declined as TResult;
  }

  Future<TResult> _handleRegisterFromInvitation<TResult>(
    RegisterFromInvitationCommand command,
  ) async {
    if (scenario == FakeIamScenario.registerIdentityConflict) {
      throw const IamBlockedException(IamBlockedCodes.platformUserAlreadyExists);
    }
    if (scenario == FakeIamScenario.inspectInvalidNoLeak) {
      throw const IamBlockedException(IamBlockedCodes.invitationTokenInvalid);
    }

    final membership = await _handleAcceptInvitation<TenantMemberDetailDto>(
      AcceptInvitationCommand(
        token: command.token,
        idempotencyKey: command.idempotencyKey,
      ),
    );
    return InvitationRegistrationResultDto(
          userId: 'registered-user-1',
          membership: membership,
        )
        as TResult;
  }

  void _seedMyProfile() {
    _myProfile = const MyIdentityProfileDto(
      userId: 'lan-le',
      firstName: 'Lan',
      lastName: 'Le',
      email: 'lan@gmail.com',
      emailVerified: true,
      phoneNumber: '+84901234567',
    );
  }

  Future<TResult> _handleGetMyProfile<TResult>() {
    if (scenario == FakeIamScenario.identityUnavailable) {
      throw const IamBlockedException(IamBlockedCodes.systemError);
    }
    return Future.value(_myProfile as TResult);
  }

  Future<TResult> _handleUpdateMyProfile<TResult>(
    UpdateMyIdentityProfileCommand command,
  ) {
    if (scenario == FakeIamScenario.identityUnavailable) {
      throw const IamBlockedException(IamBlockedCodes.systemError);
    }
    if (command.firstName.trim().isEmpty || command.lastName.trim().isEmpty) {
      throw ValidationException('firstName and lastName are required');
    }
    _myProfile = _myProfile.copyWith(
      firstName: command.firstName.trim(),
      lastName: command.lastName.trim(),
      phoneNumber: command.phoneNumber?.trim(),
      avatarUrl: command.avatarUrl?.trim(),
    );
    return Future.value(_myProfile as TResult);
  }

  String _maskEmail(String email) {
    final at = email.indexOf('@');
    if (at <= 0) return '***';
    final local = email.substring(0, at);
    final domain = email.substring(at);
    if (local.length <= 2) return '${local[0]}***$domain';
    return '${local.substring(0, 2)}***$domain';
  }

  Future<TResult> _handleRequestMyPasswordReset<TResult>() {
    if (scenario == FakeIamScenario.identityUnavailable) {
      throw const IamBlockedException(IamBlockedCodes.systemError);
    }
    if (!_myProfile.emailVerified) {
      throw ValidationException('Email must be verified');
    }
    _passwordResetOperationId = 'op-reset-1';
    _passwordResetVerified = false;
    final now = DateTime.now().toUtc();
    return Future.value(
      PasswordResetRequestResultDto(
            operationId: _passwordResetOperationId!,
            maskedEmail: _maskEmail(_myProfile.email),
            expiresAt: now.add(const Duration(minutes: 10)),
            resendAvailableAt: now.add(const Duration(seconds: 45)),
          )
          as TResult,
    );
  }

  Future<TResult> _handleResendMyPasswordReset<TResult>(
    ResendMyPasswordResetCommand command,
  ) {
    if (_passwordResetOperationId != command.operationId) {
      throw const IamBlockedException(IamBlockedCodes.stateChanged);
    }
    _passwordResetVerified = false;
    final now = DateTime.now().toUtc();
    return Future.value(
      PasswordResetRequestResultDto(
            operationId: _passwordResetOperationId!,
            maskedEmail: _maskEmail(_myProfile.email),
            expiresAt: now.add(const Duration(minutes: 10)),
            resendAvailableAt: now.add(const Duration(seconds: 45)),
          )
          as TResult,
    );
  }

  Future<TResult> _handleVerifyMyPasswordReset<TResult>(
    VerifyMyPasswordResetCommand command,
  ) {
    if (scenario == FakeIamScenario.passwordResetInvalidCode || command.code.trim() != '123456') {
      throw const IamBlockedException(IamBlockedCodes.resetCodeInvalid);
    }
    if (_passwordResetOperationId != command.operationId) {
      throw const IamBlockedException(IamBlockedCodes.stateChanged);
    }
    _passwordResetVerified = true;
    return Future.value(
      const PasswordResetVerifyResultDto(verified: true) as TResult,
    );
  }

  Future<TResult> _handleCompleteMyPasswordReset<TResult>(
    CompleteMyPasswordResetCommand command,
  ) {
    if (!_passwordResetVerified || _passwordResetOperationId != command.operationId) {
      throw const IamBlockedException(IamBlockedCodes.stateChanged);
    }
    if (command.newPassword.length < 8) {
      throw ValidationException('PASSWORD_POLICY_VIOLATION');
    }
    _passwordResetOperationId = null;
    _passwordResetVerified = false;
    return Future.value(
      PasswordResetCompletionResultDto(
            currentSessionRotated: true,
            otherSessionsRevoked: true,
          )
          as TResult,
    );
  }

  Future<TResult> _handleGetOnboardingOperation<TResult>(
    GetTenantOnboardingOperationQuery query,
  ) {
    _requirePlatformView();
    if (scenario == FakeIamScenario.onboardingPartialFailure) {
      return Future.value(
        TenantOnboardingOperationDto(
              operationId: query.operationId,
              status: TenantOnboardingOperationStatus.partialFailure,
              completedSteps: const ['tenant', 'membership'],
              failedStep: 'identity',
              correlationId: 'corr-partial-1',
            )
            as TResult,
      );
    }
    final op = _onboardingOps[query.operationId];
    if (op == null) {
      throw const IamBlockedException(IamBlockedCodes.resourceNotFound);
    }
    return Future.value(op as TResult);
  }

  Future<TResult> _handleRetryOnboardingOperation<TResult>(
    RetryTenantOnboardingOperationCommand command,
  ) {
    _requirePlatformView();
    if (scenario == FakeIamScenario.onboardingResumeOk ||
        scenario == FakeIamScenario.onboardingPartialFailure) {
      final resumed = TenantOnboardingOperationDto(
        operationId: command.operationId,
        status: TenantOnboardingOperationStatus.completed,
        completedSteps: const ['tenant', 'membership', 'identity', 'outbox'],
        correlationId: 'corr-resume-1',
        tenantId: 'tenant-resume-1',
        ownerUserId: 'owner-resume-1',
      );
      _onboardingOps[command.operationId] = resumed;
      return Future.value(resumed as TResult);
    }
    final op = _onboardingOps[command.operationId];
    if (op == null) {
      throw const IamBlockedException(IamBlockedCodes.resourceNotFound);
    }
    if (op.status == TenantOnboardingOperationStatus.completed) {
      throw const IamBlockedException(IamBlockedCodes.stateChanged);
    }
    return Future.value(op as TResult);
  }

  Future<TResult> _handleListAccessibleTenants<TResult>() {
    if (scenario == FakeIamScenario.tenantsAuthenticationRequired ||
        scenario == FakeIamScenario.tenantsIdentityInactive) {
      throw const IamBlockedException(IamBlockedCodes.authenticationRequired);
    }
    final list = _accessibleTenants
        .map(
          (t) => t.copyWith(
            isCurrent: currentTenantId != null && t.tenantId == currentTenantId,
          ),
        )
        .toList(growable: false);
    return Future.value(list as TResult);
  }

  Future<TResult> _handleSwitchTenantContext<TResult>(
    SwitchTenantContextCommand command,
  ) {
    if (scenario == FakeIamScenario.switchDenied) {
      throw ApplicationException('TENANT_ACCESS_DENIED');
    }
    if (scenario == FakeIamScenario.switchSameTenant || command.targetTenantId == currentTenantId) {
      throw ValidationException('Target tenant must differ from current');
    }

    final match = _accessibleTenants.where((t) => t.tenantId == command.targetTenantId).firstOrNull;
    if (match == null) {
      throw ApplicationException('TENANT_ACCESS_DENIED');
    }
    if (scenario == FakeIamScenario.switchSuspended ||
        match.status == TenantLifecycleStatus.suspended) {
      throw ApplicationException('TENANT_SUSPENDED');
    }
    if (scenario == FakeIamScenario.switchClosed || match.status == TenantLifecycleStatus.closed) {
      throw ApplicationException('TENANT_CLOSED');
    }
    if (match.status == TenantLifecycleStatus.provisioning) {
      throw ApplicationException('TENANT_ACCESS_DENIED');
    }
    if (scenario == FakeIamScenario.switchSessionFailure) {
      // Preference must remain unchanged when session establish fails.
      throw const IamBlockedException(IamBlockedCodes.systemError);
    }
    if (scenario == FakeIamScenario.switchPreferenceFailure) {
      // Session would roll back; preference stays on the prior tenant.
      throw const IamBlockedException(IamBlockedCodes.systemError);
    }

    currentTenantId = match.tenantId;
    lastSelectedTenantId = match.tenantId;
    switchTenantCount++;

    final context = TenantContextDto(
      status: TenantContextStatus.valid,
      tenantId: match.tenantId,
      tenantName: match.name,
      roleLabel: match.roleLabel,
      tenantStatus: match.status,
      permissions: const ['tenant.access'],
    );
    return Future.value(context as TResult);
  }

  Future<TResult> _handleGetTenantContext<TResult>(
    GetTenantContextQuery query,
  ) {
    if (query.bootstrapFromLastSelected) {
      if (scenario == FakeIamScenario.contextNone) {
        return Future.value(
          const TenantContextDto(status: TenantContextStatus.none) as TResult,
        );
      }
      final bootstrapTenantId =
          (lastSelectedTenantId == null || lastSelectedTenantId!.trim().isEmpty)
          ? currentTenantId
          : lastSelectedTenantId;
      if (bootstrapTenantId == null || bootstrapTenantId.trim().isEmpty) {
        return Future.value(
          const TenantContextDto(status: TenantContextStatus.none) as TResult,
        );
      }
      if (scenario == FakeIamScenario.bootstrapInvalid) {
        return Future.value(
          const TenantContextDto(status: TenantContextStatus.none) as TResult,
        );
      }

      final match = _accessibleTenants
          .where((t) => t.tenantId == bootstrapTenantId)
          .firstOrNull;
      if (match == null ||
          match.status == TenantLifecycleStatus.suspended ||
          match.status == TenantLifecycleStatus.closed) {
        // OQ-07: invalid preference → none (do not auto-pick).
        return Future.value(
          const TenantContextDto(status: TenantContextStatus.none) as TResult,
        );
      }

      currentTenantId = match.tenantId;
      lastSelectedTenantId ??= match.tenantId;
      return Future.value(
        TenantContextDto(
              status: TenantContextStatus.valid,
              tenantId: match.tenantId,
              tenantName: match.name,
              roleLabel: match.roleLabel,
              tenantStatus: match.status,
              permissions: const ['tenant.access'],
            )
            as TResult,
      );
    }

    if (scenario == FakeIamScenario.contextInvalidated) {
      return Future.value(
        TenantContextDto(
              status: TenantContextStatus.invalidated,
              tenantId: currentTenantId,
              tenantName: 'Thú y Minh Phát',
              invalidationReason: TenantContextInvalidationReason.tenantSuspended,
              blockedErrorCode: 'TENANT_SUSPENDED',
            )
            as TResult,
      );
    }

    if (scenario == FakeIamScenario.contextIdentityInactive) {
      return Future.value(
        TenantContextDto(
              status: TenantContextStatus.invalidated,
              tenantId: currentTenantId,
              tenantName: 'Thú y Minh Phát',
              invalidationReason: TenantContextInvalidationReason.identityInactive,
              blockedErrorCode: 'OWNER_IDENTITY_UNAVAILABLE',
            )
            as TResult,
      );
    }

    if (scenario == FakeIamScenario.contextPermissionsRefreshed) {
      final refreshed = _accessibleTenants.where((t) => t.tenantId == currentTenantId).firstOrNull;
      return Future.value(
        TenantContextDto(
              status: TenantContextStatus.valid,
              tenantId: refreshed?.tenantId ?? currentTenantId,
              tenantName: refreshed?.name ?? 'Thú y Minh Phát',
              roleLabel: refreshed?.roleLabel ?? 'Chủ cửa hàng',
              tenantStatus: refreshed?.status,
              permissions: const [
                'tenant.access',
                'tenant.members.view',
              ],
            )
            as TResult,
      );
    }

    if (currentTenantId == null || currentTenantId!.trim().isEmpty) {
      return Future.value(
        const TenantContextDto(status: TenantContextStatus.none) as TResult,
      );
    }

    final match = _accessibleTenants.where((t) => t.tenantId == currentTenantId).firstOrNull;
    if (match == null) {
      return Future.value(
        const TenantContextDto(
              status: TenantContextStatus.invalidated,
              invalidationReason: TenantContextInvalidationReason.membershipRemoved,
              blockedErrorCode: 'TENANT_ACCESS_DENIED',
            )
            as TResult,
      );
    }

    return Future.value(
      TenantContextDto(
            status: TenantContextStatus.valid,
            tenantId: match.tenantId,
            tenantName: match.name,
            roleLabel: match.roleLabel,
            tenantStatus: match.status,
            permissions: const ['tenant.access'],
          )
          as TResult,
    );
  }
}
