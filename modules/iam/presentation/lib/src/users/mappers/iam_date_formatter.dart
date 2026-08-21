import 'package:vet45_design_system/design_system.dart';

/// Date/time labels for IAM presentation. Never uses wall clock internally.
abstract final class IamDateFormatter {
  static String formatDate(DateTime value) => VDateTime.date(value);

  static String formatDateTime(DateTime value) => VDateTime.dateTime(value);

  /// Remaining invitation window relative to [nowUtc].
  static String invitationExpiryDetail(DateTime expiresAt, DateTime nowUtc) {
    final delta = expiresAt.toUtc().difference(nowUtc.toUtc());
    if (delta.isNegative) return 'Đã hết hạn';
    final days = delta.inDays;
    if (days <= 0) {
      final hours = delta.inHours;
      if (hours <= 0) return 'Hết hạn trong dưới 1 giờ';
      return 'Hết hạn trong $hours giờ';
    }
    if (days == 1) return 'Hết hạn trong 1 ngày';
    return 'Hết hạn sau $days ngày';
  }

  static bool isExpiringSoon(
    DateTime expiresAt,
    DateTime nowUtc, {
    Duration threshold = const Duration(days: 2),
  }) {
    final remaining = expiresAt.toUtc().difference(nowUtc.toUtc());
    return !remaining.isNegative && remaining <= threshold;
  }
}
