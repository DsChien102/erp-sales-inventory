import 'package:vet45_iam_application/application.dart';

/// Host-owned: hydrate in-memory IAM identity from a persisted Supabase auth
/// session (platform admin — auth-only, no tenant).
void restorePersistedAuthSession({
  required IAuthenticator authenticator,
  required IIamSessionPort sessionPort,
}) {
  final userId = authenticator.currentUserId?.trim();
  if (userId == null || userId.isEmpty) {
    sessionPort.clear();
    return;
  }
  sessionPort.applyAuthenticatedUser(userId);
}
