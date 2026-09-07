import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../provider_connection_status.dart';

/// Allowed provider connection status transitions (Phase 1 state machine).
final class ProviderConnectionStatusTransitionAllowedRule implements IBusinessRule {
  const ProviderConnectionStatusTransitionAllowedRule({
    required this.from,
    required this.to,
  });

  final ProviderConnectionStatus from;
  final ProviderConnectionStatus to;

  static const _allowed = {
    ProviderConnectionStatus.disconnected: {
      ProviderConnectionStatus.checkRequired,
      ProviderConnectionStatus.connected,
    },
    ProviderConnectionStatus.checkRequired: {
      ProviderConnectionStatus.connected,
      ProviderConnectionStatus.reconnectRequired,
      ProviderConnectionStatus.disconnected,
    },
    ProviderConnectionStatus.connected: {
      ProviderConnectionStatus.checkRequired,
      ProviderConnectionStatus.reconnectRequired,
      ProviderConnectionStatus.disconnected,
    },
    ProviderConnectionStatus.reconnectRequired: {
      ProviderConnectionStatus.checkRequired,
      ProviderConnectionStatus.connected,
      ProviderConnectionStatus.disconnected,
    },
  };

  @override
  bool isBroken() => !(_allowed[from]?.contains(to) ?? false);

  @override
  String get message => 'Provider connection transition from $from to $to is not allowed';
}
