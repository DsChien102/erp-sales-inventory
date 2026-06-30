/// Temporary role code — align with SRS role model later.
final class RoleCode {
  RoleCode(this.value) {
    if (value.trim().isEmpty) {
      throw ArgumentError('Role code must not be empty');
    }
  }

  static final owner = RoleCode('owner');
  static final staff = RoleCode('staff');

  final String value;
}
