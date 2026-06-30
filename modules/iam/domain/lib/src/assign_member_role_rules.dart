/// Interim role assignment rules until SRS Theme 1 lands.
abstract final class AssignMemberRoleRules {
  static const allowedRoleValues = {'owner', 'staff'};

  static void ensureRoleAllowed(String role) {
    if (!allowedRoleValues.contains(role)) {
      throw ArgumentError('Role not allowed: $role');
    }
  }
}
