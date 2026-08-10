/// Platform Identity activation snapshot for Owner (§S11).
final class TenantActivationIdentitySnapshot {
  const TenantActivationIdentitySnapshot({
    required this.userId,
    required this.identityStatus,
    required this.emailVerified,
    required this.platformBlockerCodes,
    required this.snapshotVersion,
  });

  final String userId;
  final String identityStatus;
  final bool emailVerified;
  final List<String> platformBlockerCodes;
  final String snapshotVersion;
}
