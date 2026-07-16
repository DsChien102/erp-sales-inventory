class VDuration {
  VDuration._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 350);

  /// Skeleton / placeholder pulse (shadcn-style).
  static const Duration pulse = Duration(milliseconds: 1000);
}
