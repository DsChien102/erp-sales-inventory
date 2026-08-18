import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../provider_connection_status.dart';

/// Connection must be CONNECTED for provider-dependent operations.
final class ConnectionMustBeVerifiedRule implements IBusinessRule {
  const ConnectionMustBeVerifiedRule({required this.status});

  final ProviderConnectionStatus status;

  @override
  bool isBroken() => status != ProviderConnectionStatus.connected;

  @override
  String get message => 'Provider connection must be verified and connected';
}
