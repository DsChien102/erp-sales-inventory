/// Platform-scoped permission codes for Admin App (TH-01 S15).
///
/// Codes match APPENDICES §6.3.2.
abstract final class IamPlatformPermissions {
  static const userView = 'platform.user.view';
  static const userCreate = 'platform.user.create';
  static const userActivationInviteSend = 'platform.user.activation_invite.send';
  static const userPasswordResetInitiate = 'platform.user.password_reset.initiate';
  static const userSuspend = 'platform.user.suspend';
  static const userRestore = 'platform.user.restore';
  static const tenantCreate = 'platform.tenant.create';
  static const tenantView = 'platform.tenant.view';
}
