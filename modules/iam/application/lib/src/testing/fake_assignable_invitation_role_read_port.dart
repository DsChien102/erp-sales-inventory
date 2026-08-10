import '../invitation/shared/assignable_role_option_dto.dart';
import '../ports/i_assignable_invitation_role_read_port.dart';

/// In-memory assignable roles for unit/fake tests (S7 / D1).
final class FakeAssignableInvitationRoleReadPort
    implements IAssignableInvitationRoleReadPort {
  FakeAssignableInvitationRoleReadPort([
    this.roles = const [
      AssignableRoleOptionDto(
        roleId: 'role-staff',
        label: 'Nhân viên bán hàng',
      ),
      AssignableRoleOptionDto(
        roleId: 'role-warehouse',
        label: 'Thủ kho',
      ),
      AssignableRoleOptionDto(
        roleId: 'role-accountant',
        label: 'Kế toán',
      ),
    ],
  ]);

  List<AssignableRoleOptionDto> roles;
  int calls = 0;
  String? lastTenantId;

  @override
  Future<List<AssignableRoleOptionDto>> listAssignableRoles({
    required String tenantId,
  }) async {
    calls += 1;
    lastTenantId = tenantId;
    return List<AssignableRoleOptionDto>.from(roles);
  }
}
