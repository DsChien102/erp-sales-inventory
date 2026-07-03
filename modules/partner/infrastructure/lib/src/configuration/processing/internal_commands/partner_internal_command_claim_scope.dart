import 'dart:async';

/// Claim metadata for a partner internal command row being processed.
final class PartnerInternalCommandClaim {
  const PartnerInternalCommandClaim({
    required this.tenantId,
    required this.claimToken,
  });

  final String tenantId;
  final String claimToken;
}

/// Zone-scoped claim context for [InternalCommandCompletionDecorator].
abstract final class PartnerInternalCommandClaimScope {
  static final Object _token = Object();

  static PartnerInternalCommandClaim? get current =>
      Zone.current[_token] as PartnerInternalCommandClaim?;

  static Future<T> run<T>(
    PartnerInternalCommandClaim claim,
    Future<T> Function() action,
  ) {
    return runZoned(action, zoneValues: {_token: claim});
  }
}
