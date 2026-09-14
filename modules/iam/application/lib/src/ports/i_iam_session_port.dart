import '../authentication/shared/principal_access_dto.dart';
import '../authentication/shared/session_dto.dart';

/// In-memory IAM session state — no auth/restore orchestration.
abstract interface class IIamSessionPort {
  SessionDto get snapshot;

  void applyAuthenticatedUser(String userId);

  void apply(PrincipalAccessDto context);

  void clear();
}
