import 'package:vet45_iam_application/application.dart';

/// Local-date filter for tenant audit search (converted to UTC in Cubit).
final class TenantAuditFilter {
  const TenantAuditFilter({
    required this.fromLocal,
    required this.toLocal,
    this.result,
    this.actorUserId,
    this.subjectType,
    this.eventCode,
  });

  final DateTime fromLocal;
  final DateTime toLocal;
  final TenantAuditLogResult? result;
  final String? actorUserId;
  final String? subjectType;
  final String? eventCode;

  /// Default: last 30 local calendar days (inclusive start, exclusive end day).
  factory TenantAuditFilter.last30Days({DateTime? nowLocal}) {
    final now = nowLocal ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return TenantAuditFilter(
      fromLocal: today.subtract(const Duration(days: 29)),
      toLocal: today,
    );
  }

  TenantAuditFilter copyWith({
    DateTime? fromLocal,
    DateTime? toLocal,
    TenantAuditLogResult? result,
    String? actorUserId,
    String? subjectType,
    String? eventCode,
    bool clearResult = false,
    bool clearActorUserId = false,
    bool clearSubjectType = false,
    bool clearEventCode = false,
  }) {
    return TenantAuditFilter(
      fromLocal: fromLocal ?? this.fromLocal,
      toLocal: toLocal ?? this.toLocal,
      result: clearResult ? null : (result ?? this.result),
      actorUserId:
          clearActorUserId ? null : (actorUserId ?? this.actorUserId),
      subjectType:
          clearSubjectType ? null : (subjectType ?? this.subjectType),
      eventCode: clearEventCode ? null : (eventCode ?? this.eventCode),
    );
  }

  bool get hasAdvancedFilters =>
      result != null ||
      (actorUserId != null && actorUserId!.isNotEmpty) ||
      (subjectType != null && subjectType!.isNotEmpty) ||
      (eventCode != null && eventCode!.isNotEmpty);
}
