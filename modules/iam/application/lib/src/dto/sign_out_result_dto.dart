/// Sign-out result (§S14).
///
/// Local IAM session is always cleared when [localCleared] is true. Remote
/// provider failure is reported via [remoteSucceeded] so FE can warn without
/// retaining local secrets.
final class SignOutResultDto {
  const SignOutResultDto({
    required this.localCleared,
    required this.remoteSucceeded,
  });

  final bool localCleared;
  final bool remoteSucceeded;
}
