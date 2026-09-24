import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

IamBlockedException mapIamBlockedRpcError(RpcException error) {
  final message = error.message;
  final upper = message.toUpperCase();

  for (final code in [
    IamBlockedCodes.platformUserSuspended,
    IamBlockedCodes.lastOwnerProtected,
    IamBlockedCodes.stateChanged,
    IamBlockedCodes.membershipInactive,
    IamBlockedCodes.noActiveMembership,
    IamBlockedCodes.membershipRemoved,
    IamBlockedCodes.duplicateMembership,
    IamBlockedCodes.roleNotAssignable,
    IamBlockedCodes.readinessBlocked,
    IamBlockedCodes.ownerIdentityUnavailable,
    IamBlockedCodes.idempotencyConflict,
    IamBlockedCodes.tenantStateInvalid,
    IamBlockedCodes.tenantSuspended,
    IamBlockedCodes.tenantClosed,
    IamBlockedCodes.ownerTargetInvalid,
    IamBlockedCodes.platformPermissionDenied,
    IamBlockedCodes.invitationPendingExists,
    IamBlockedCodes.invitationTokenInvalid,
    IamBlockedCodes.invitationExpired,
    IamBlockedCodes.invitationRevoked,
    IamBlockedCodes.invitationAlreadyUsed,
    IamBlockedCodes.invitationEmailMismatch,
    IamBlockedCodes.platformUserAlreadyExists,
    IamBlockedCodes.stepUpAuthRequired,
    IamBlockedCodes.resourceNotFound,
    IamBlockedCodes.validationError,
    IamBlockedCodes.permissionDenied,
    IamBlockedCodes.authenticationRequired,
    IamBlockedCodes.sessionExpired,
    IamBlockedCodes.resetRateLimited,
    IamBlockedCodes.resetCodeInvalid,
    IamBlockedCodes.resetCodeExpired,
    IamBlockedCodes.resetCodeAttemptsExceeded,
    IamBlockedCodes.passwordPolicyViolation,
    IamBlockedCodes.systemError,
  ]) {
    if (upper.contains(code)) {
      return IamBlockedException(code, message: message);
    }
  }

  // Legacy aliases → canonical (draft SQL / older adapters).
  if (upper.contains('RATE_LIMITED')) {
    return IamBlockedException(
      IamBlockedCodes.resetRateLimited,
      message: message,
    );
  }
  if (upper.contains('ATTEMPTS_EXCEEDED')) {
    return IamBlockedException(
      IamBlockedCodes.resetCodeAttemptsExceeded,
      message: message,
    );
  }
  if (upper.contains('IDENTITY_CONFLICT')) {
    return IamBlockedException(
      IamBlockedCodes.platformUserAlreadyExists,
      message: message,
    );
  }
  if (upper.contains('INVITATION_ALREADY_ACCEPTED')) {
    return IamBlockedException(
      IamBlockedCodes.invitationAlreadyUsed,
      message: message,
    );
  }
  if (upper.contains('NO_PERMISSION')) {
    return IamBlockedException(
      IamBlockedCodes.permissionDenied,
      message: message,
    );
  }
  if (upper.contains('NOT_FOUND')) {
    return const IamBlockedException(IamBlockedCodes.resourceNotFound);
  }

  if (message.toLowerCase().contains('permission denied') ||
      message.toLowerCase().contains('not authenticated')) {
    return IamBlockedException(
      IamBlockedCodes.permissionDenied,
      message: message,
    );
  }

  if (message.toLowerCase().contains('membership not found') ||
      message.toLowerCase().contains('not found')) {
    return const IamBlockedException(IamBlockedCodes.resourceNotFound);
  }

  return IamBlockedException(
    IamBlockedCodes.systemError,
    message: message,
  );
}
