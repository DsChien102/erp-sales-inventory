import 'package:c45_design_system/design_system.dart';

import '../data/models/tenant_audit_log.dart';

enum TenantAuditRange { h24, d7, d30 }

/// Local-date filter for tenant audit search (converted to UTC in Cubit).
final class TenantAuditFilter {
  const TenantAuditFilter({
    required this.fromLocal,
    required this.toLocal,
    this.range = TenantAuditRange.d30,
    this.exactFromUtc,
    this.exactToUtc,
    this.query,
    this.result,
    this.eventCategory,
    this.subjectType,
    this.eventCodes,
  });

  final DateTime fromLocal;
  final DateTime toLocal;
  final TenantAuditRange range;
  final DateTime? exactFromUtc;
  final DateTime? exactToUtc;
  final String? query;
  final TenantAuditLogResult? result;
  final TenantAuditEventCategory? eventCategory;
  final String? subjectType;
  final List<String>? eventCodes;

  factory TenantAuditFilter.forRange(
    TenantAuditRange range, {
    required DateTime nowIct,
  }) {
    if (range == TenantAuditRange.h24) {
      final toUtc = DateTime.utc(
        nowIct.year,
        nowIct.month,
        nowIct.day,
        nowIct.hour,
        nowIct.minute,
        nowIct.second,
        nowIct.millisecond,
        nowIct.microsecond,
      ).subtract(VDateTime.ictOffset);
      final fromUtc = toUtc.subtract(const Duration(hours: 24));
      return TenantAuditFilter(
        fromLocal: nowIct.subtract(const Duration(hours: 24)),
        toLocal: nowIct,
        range: TenantAuditRange.h24,
        exactFromUtc: fromUtc,
        exactToUtc: toUtc,
      );
    }
    final today = DateTime(nowIct.year, nowIct.month, nowIct.day);
    final daysBack = range == TenantAuditRange.d7 ? 6 : 29;
    return TenantAuditFilter(
      fromLocal: today.subtract(Duration(days: daysBack)),
      toLocal: today,
      range: range,
    );
  }

  /// Default: last 30 Vietnam calendar days (inclusive start, exclusive end day).
  factory TenantAuditFilter.last30Days({DateTime? nowLocal}) {
    return TenantAuditFilter.forRange(
      TenantAuditRange.d30,
      nowIct: VDateTime.toIct(nowLocal ?? DateTime.now()),
    );
  }

  TenantAuditFilter copyWith({
    DateTime? fromLocal,
    DateTime? toLocal,
    TenantAuditRange? range,
    DateTime? exactFromUtc,
    DateTime? exactToUtc,
    bool clearExactUtc = false,
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
      range: range ?? this.range,
      exactFromUtc: clearExactUtc ? null : (exactFromUtc ?? this.exactFromUtc),
      exactToUtc: clearExactUtc ? null : (exactToUtc ?? this.exactToUtc),
      query: clearQuery ? null : (query ?? this.query),
      result: clearResult ? null : (result ?? this.result),
      eventCategory: clearEventCategory ? null : (eventCategory ?? this.eventCategory),
      subjectType: clearSubjectType ? null : (subjectType ?? this.subjectType),
      eventCodes: clearEventCodes ? null : (eventCodes ?? this.eventCodes),
    );
  }

  bool get hasAdvancedFilters =>
      range != TenantAuditRange.d30 ||
      (query != null && query!.trim().isNotEmpty) ||
      result != null ||
      eventCategory != null ||
      (subjectType != null && subjectType!.isNotEmpty) ||
      (eventCodes != null && eventCodes!.isNotEmpty);
}
