import '../data/models/tenant_audit_log.dart';

/// Local-date filter for tenant audit search (converted to UTC in Cubit).
final class TenantAuditFilter {
  const TenantAuditFilter({
    required this.fromLocal,
    required this.toLocal,
    this.query,
    this.result,
    this.eventCategory,
    this.subjectType,
    this.eventCodes,
  });

  final DateTime fromLocal;
  final DateTime toLocal;
  final String? query;
  final TenantAuditLogResult? result;
  final TenantAuditEventCategory? eventCategory;
  final String? subjectType;
  final List<String>? eventCodes;

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
    String? query,
    TenantAuditLogResult? result,
    TenantAuditEventCategory? eventCategory,
    String? subjectType,
    List<String>? eventCodes,
    bool clearQuery = false,
    bool clearResult = false,
    bool clearEventCategory = false,
    bool clearSubjectType = false,
    bool clearEventCodes = false,
  }) {
    return TenantAuditFilter(
      fromLocal: fromLocal ?? this.fromLocal,
      toLocal: toLocal ?? this.toLocal,
      query: clearQuery ? null : (query ?? this.query),
      result: clearResult ? null : (result ?? this.result),
      eventCategory: clearEventCategory ? null : (eventCategory ?? this.eventCategory),
      subjectType: clearSubjectType ? null : (subjectType ?? this.subjectType),
      eventCodes: clearEventCodes ? null : (eventCodes ?? this.eventCodes),
    );
  }

  bool get hasAdvancedFilters =>
      (query != null && query!.trim().isNotEmpty) ||
      result != null ||
      eventCategory != null ||
      (subjectType != null && subjectType!.isNotEmpty) ||
      (eventCodes != null && eventCodes!.isNotEmpty);
}
