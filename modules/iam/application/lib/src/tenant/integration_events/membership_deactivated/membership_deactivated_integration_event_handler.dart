import 'package:vet45_iam_integration_events/integration_events.dart';

import '../../../ports/i_platform_user_preference_port.dart';

/// Inbox consumer: clears [IPlatformUserPreferencePort.lastSelectedTenantId]
/// for the deactivated member so the next login does not attempt to restore
/// an inactive tenant context.
///
/// Intentionally sets preference to null rather than auto-picking another
/// active tenant — [TenantContextCubit.bootstrap] handles that gracefully
/// by opening the org selector when no valid preference is found.
final class MembershipDeactivatedIntegrationEventHandler
    implements
        IIntegrationEventNotificationHandler<
          MembershipDeactivatedIntegrationEvent
        > {
  MembershipDeactivatedIntegrationEventHandler({
    required IPlatformUserPreferencePort preferencePort,
  }) : _preferencePort = preferencePort;

  final IPlatformUserPreferencePort _preferencePort;

  @override
  Future<void> handle(MembershipDeactivatedIntegrationEvent event) async {
    await _preferencePort.setLastSelectedTenantId(null);
  }
}
