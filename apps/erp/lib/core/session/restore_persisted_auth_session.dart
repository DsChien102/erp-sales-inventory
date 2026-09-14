import 'package:vet45_iam_application/application.dart';

/// Host-owned: hydrate in-memory IAM identity from a persisted Supabase auth
/// session. Does **not** bind tenant/store — ERP defers that to tenant bootstrap.
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
