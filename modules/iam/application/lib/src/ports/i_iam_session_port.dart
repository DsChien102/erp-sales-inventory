import '../dto/session_dto.dart';

/// Coordinates in-memory session after auth events.
abstract interface class IIamSessionPort {
  SessionDto get snapshot;

  Future<void> establishAfterSignIn({
    String? tenantId,
    bool requireTenantContext = true,
  });

  Future<void> clear();

  Future<void> restoreFromPersistedAuth({bool requireTenantContext = true});
}
