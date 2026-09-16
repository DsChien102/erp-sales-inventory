import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_iam_access_gateway.dart';
import '../../../ports/i_iam_session_port.dart';
import '../../../ports/i_platform_user_preference_port.dart';
import '../../../authentication/shared/bind_session_from_access.dart';
import '../../shared/tenant_context_dto.dart';
import '../../../shared/iam_blocked_codes.dart';
import '../../../shared/iam_blocked_exception.dart';
import 'switch_tenant_context_command.dart';

@CommandHandlerFor(SwitchTenantContextCommand)
final class SwitchTenantContextCommandHandler
    implements
        ICommandHandler<SwitchTenantContextCommand, TenantContextDto> {
  SwitchTenantContextCommandHandler({
    required IIamAccessGateway accessGateway,
    required IPlatformUserPreferencePort preferencePort,
    required IIamSessionPort sessionPort,
    required ICurrentTenant currentTenant,
  }) : _accessGateway = accessGateway,
       _preferencePort = preferencePort,
       _sessionPort = sessionPort,
       _currentTenant = currentTenant;

  final IIamAccessGateway _accessGateway;
  final IPlatformUserPreferencePort _preferencePort;
  final IIamSessionPort _sessionPort;
  final ICurrentTenant _currentTenant;

  @override
  Future<TenantContextDto> handle(SwitchTenantContextCommand command) async {
    final previousTenantId = _currentTenant.tenantId;

    final differRule = TargetTenantMustDifferFromCurrentRule(
      targetTenantId: command.targetTenantId,
      currentTenantId: previousTenantId,
    );
    if (differRule.isBroken()) {
      throw ValidationException(differRule.message);
    }

    final context = await _accessGateway.switchTenantContext(
      targetTenantId: command.targetTenantId,
    );

    if (context.status != TenantContextStatus.valid ||
        context.tenantId == null) {
      throw ApplicationException(
        context.blockedErrorCode ?? 'TENANT_ACCESS_DENIED',
      );
    }

    // Step 3: establish session before preference so preference failure can
    // restore the previous session.
    try {
      await bindSessionFromAccessContext(
        accessGateway: _accessGateway,
        sessionPort: _sessionPort,
        tenantId: context.tenantId!,
      );
    } catch (error) {
      throw _mapSwitchSessionError(error);
    }

    try {
      await _preferencePort.setLastSelectedTenantId(context.tenantId);
    } catch (_) {
      final prior = previousTenantId?.trim();
      if (prior != null && prior.isNotEmpty) {
        try {
          await bindSessionFromAccessContext(
            accessGateway: _accessGateway,
            sessionPort: _sessionPort,
            tenantId: prior,
          );
        } catch (_) {
          // Best-effort restore; still surface preference failure.
        }
      }
      throw const IamBlockedException(IamBlockedCodes.systemError);
    }

    return context;
  }

  Never _mapSwitchSessionError(Object error) {
    if (error is IamBlockedException) {
      throw error;
    }

    if (error is ApplicationException) {
      final code = _iamBlockedCodeFromApplication(error);
      if (code != null) {
        throw IamBlockedException(code);
      }
    }

    throw const IamBlockedException(IamBlockedCodes.systemError);
  }

  String? _iamBlockedCodeFromApplication(ApplicationException error) {
    final message = error.message.trim();
    if (message.isEmpty) {
      return null;
    }

    const knownCodes = <String>{
      IamBlockedCodes.contextInvalid,
      IamBlockedCodes.membershipInactive,
      IamBlockedCodes.membershipRemoved,
      'TENANT_ACCESS_DENIED',
      'TENANT_SUSPENDED',
      'TENANT_CLOSED',
      'NOT_AUTHENTICATED',
    };

    if (knownCodes.contains(message)) {
      return message;
    }

    final lower = message.toLowerCase();
    if (lower.contains('context_invalid')) {
      return IamBlockedCodes.contextInvalid;
    }
    if (lower.contains('membership_inactive')) {
      return IamBlockedCodes.membershipInactive;
    }
    if (lower.contains('membership_removed')) {
      return IamBlockedCodes.membershipRemoved;
    }
    if (lower.contains('tenant_access_denied')) {
      return 'TENANT_ACCESS_DENIED';
    }

    return null;
  }
}
