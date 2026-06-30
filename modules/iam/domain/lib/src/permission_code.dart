/// Temporary permission code — align with SRS catalog later.
final class PermissionCode {
  PermissionCode(this.value) {
    if (value.trim().isEmpty) {
      throw ArgumentError('Permission code must not be empty');
    }
  }

  final String value;
}
