import '../dto/assignable_role_option_dto.dart';

/// Read port for roles assignable when creating a tenant invitation (S7 / D1).
abstract interface class IAssignableInvitationRoleReadPort {
  Future<List<AssignableRoleOptionDto>> listAssignableRoles({
    required String tenantId,
  });
}
