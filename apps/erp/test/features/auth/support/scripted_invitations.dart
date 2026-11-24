import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/iam/iam_codes.dart';
import 'package:erp/core/session/session_controller.dart';
import 'package:erp/features/auth/data/invitation_acceptance_repository.dart';
import 'package:erp/features/auth/data/models/invitation_token_inspection.dart';
import 'package:erp/features/auth/presentation/pages/invitation_token_page.dart';
import 'package:erp/features/iam/data/models/tenant_invitation.dart';
import 'package:erp/features/iam/data/models/tenant_member.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase/supabase.dart';
import '../../iam/support/iam_fixtures.dart';

import '../../iam/support/fake_iam_backend.dart';
import 'scripted_auth.dart';

class _MockFunctions extends Mock implements FunctionsClient {}

/// Lời mời giả theo các kịch bản [FakeIamScenario] mà cubit/trang kích hoạt đang dùng.
class ScriptedInvitations extends InvitationAcceptanceRepository {
  ScriptedInvitations({
    required this.scenario,
    this.acceptError,
    this.registerError,
    List<String>? log,
    this.declineFailures = 0,
  }) : _log = log,
       super(rpc: testRpc(), functions: _MockFunctions());

  final FakeIamScenario scenario;
  final Object? acceptError;

  /// Lỗi của `registerAndAccept` (Edge Function `invitation-signup`).
  final Object? registerError;
  final List<String>? _log;
  int declineFailures;

  final accepts = <String>[];
  final registers = <({String givenName, String familyName, String password, String? phone, String key})>[];
  final declines = <String>[];

  @override
  Future<InvitationTokenInspection> inspect(String token) async {
    _log?.add('inspect');
    if (scenario == FakeIamScenario.inspectInvalidNoLeak ||
        scenario == FakeIamScenario.acceptRotatedToken) {
      throw const AppException(IamBlockedCodes.invitationTokenInvalid);
    }
    if (scenario == FakeIamScenario.acceptExpired) {
      throw const AppException(IamBlockedCodes.invitationExpired);
    }
    if (scenario == FakeIamScenario.acceptDeclined) {
      throw const AppException(IamBlockedCodes.invitationAlreadyUsed);
    }
    final exists = switch (scenario) {
      FakeIamScenario.inspectNewAccount ||
      FakeIamScenario.registerAndAcceptOk ||
      FakeIamScenario.registerIdentityConflict => false,
      _ => true,
    };
    return InvitationTokenInspection(
      tenantId: 'org-001',
      tenantName: 'Mậu Hiên',
      inviteeEmail: 'invitee@example.com',
      initialRoleId: 'role-staff',
      initialRoleLabel: 'Nhân viên bán hàng',
      expiresAt: DateTime.utc(2026, 8, 5),
      accountExists: exists,
      givenName: exists ? null : 'Chiến',
      familyName: exists ? null : 'Đỗ Sỹ',
      phone: exists ? null : '0901234567',
    );
  }

  @override
  Future<TenantMemberDetail> accept(
    String token, {
    required String idempotencyKey,
  }) async {
    accepts.add(idempotencyKey);
    _log?.add('accept');
    if (acceptError != null) throw acceptError!;
    if (scenario == FakeIamScenario.acceptEmailMismatch) {
      throw const AppException(IamBlockedCodes.invitationEmailMismatch);
    }
    if (scenario == FakeIamScenario.acceptConcurrent) {
      throw const AppException(IamBlockedCodes.invitationAlreadyUsed);
    }
    return _acceptedMembership();
  }

  @override
  Future<TenantMemberDetail> registerAndAccept({
    required String token,
    required String password,
    required String givenName,
    required String familyName,
    String? phone,
    required String idempotencyKey,
  }) async {
    registers.add((
      givenName: givenName,
      familyName: familyName,
      password: password,
      phone: phone,
      key: idempotencyKey,
    ));
    _log?.add('registerAndAccept');
    if (registerError != null) throw registerError!;
    return _acceptedMembership();
  }

  TenantMemberDetail _acceptedMembership() {
    return TenantMemberDetail(
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
  }

  @override
  Future<TenantInvitationDetail> decline(
    String token, {
    required String idempotencyKey,
  }) async {
    declines.add(idempotencyKey);
    _log?.add('decline');
    if (declineFailures > 0) {
      declineFailures -= 1;
      throw const AppException(IamBlockedCodes.idempotencyConflict);
    }
    return TenantInvitationDetail(
      invitationId: 'inv-1',
      inviteeEmail: 'invitee@example.com',
      initialRoleId: 'role-staff',
      initialRoleLabel: 'Staff',
      status: 'declined',
      expiresAt: DateTime.utc(2026, 8, 5),
      deliveryStatus: 'sent',
      deliveryCorrelationId: 'corr',
      version: 2,
      createdAt: DateTime.utc(2026, 7, 29),
      createdBy: 'lan-le',
      declinedAt: DateTime.utc(2026, 7, 30),
    );
  }
}

/// Trang nhận lời mời gắn repository giả, dùng cho widget test.
class InvitationPageHarness {
  InvitationPageHarness({
    FakeIamScenario scenario = FakeIamScenario.inspectExistingAccount,
    Object? acceptError,
    Object? registerError,
    List<String>? log,
  }) : invitations = ScriptedInvitations(
         scenario: scenario,
         acceptError: acceptError,
         registerError: registerError,
         log: log,
       ),
       auth = ScriptedAuthRepository(log: log),
       session = loginSession(email: 'invitee@example.com', log: log);

  final ScriptedInvitations invitations;
  final ScriptedAuthRepository auth;
  final SessionController session;

  InvitationTokenPage get page => InvitationTokenPage(
    invitations: invitations,
    auth: auth,
    session: session,
    keyFactory: FakeIdempotencyKeyFactory(),
  );
}
