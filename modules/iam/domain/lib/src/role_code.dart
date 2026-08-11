/// Temporary role code — align with SRS role model later.
final class RoleCode {
  RoleCode(this.value) {
    if (value.trim().isEmpty) {
      throw ArgumentError('Role code must not be empty');
    }
  }

  static final storeOwner = RoleCode('store_owner');
  static final staff = RoleCode('staff');
  static final accountant = RoleCode('accountant');
  static final warehouse = RoleCode('warehouse');

  final String value;
}
