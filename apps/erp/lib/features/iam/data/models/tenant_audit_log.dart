/// Canonical event category for tenant audit logs.
enum TenantAuditEventCategory {
  member('member'),
  role('role'),
  organization('organization'),
  invitation('invitation'),
  account('account'),
  security('security'),
  system('system');

  const TenantAuditEventCategory(this.code);

  final String code;

  static TenantAuditEventCategory? fromCode(String? code) {
    if (code == null) return null;
    for (final category in values) {
      if (category.code == code) return category;
    }
    return null;
  }
}

enum TenantAuditLogResult { success, blocked, error }

extension TenantAuditLogResultCodes on TenantAuditLogResult {
  String get code => switch (this) {
    TenantAuditLogResult.success => 'success',
    TenantAuditLogResult.blocked => 'blocked',
    TenantAuditLogResult.error => 'error',
  };

  static TenantAuditLogResult? fromCode(String? raw) => switch (raw) {
    'success' => TenantAuditLogResult.success,
    'blocked' => TenantAuditLogResult.blocked,
    'error' => TenantAuditLogResult.error,
    _ => null,
  };
}

enum TenantAuditDisplayOrigin {
  snapshot('snapshot'),
  current('current'),
  system('system'),
  unavailable('unavailable');

  const TenantAuditDisplayOrigin(this.code);

  final String code;

  static TenantAuditDisplayOrigin? fromCode(String? code) {
    if (code == null) return null;
    for (final origin in values) {
      if (origin.code == code) return origin;
    }
    return null;
  }
}

final class TenantAuditActor {
  const TenantAuditActor({
    this.userId,
    this.displayName,
    this.actorType,
    this.roleCode,
    this.roleLabel,
    this.displayOrigin,
  });

  final String? userId;
  final String? displayName;
  final String? actorType;
  final String? roleCode;
  final String? roleLabel;
  final TenantAuditDisplayOrigin? displayOrigin;

  factory TenantAuditActor.fromJson(Map<String, dynamic>? actorMap) {
    if (actorMap == null) {
      return const TenantAuditActor(displayOrigin: TenantAuditDisplayOrigin.unavailable);
    }
    return TenantAuditActor(
      userId: actorMap['user_id'] as String?,
      displayName: actorMap['display_name'] as String?,
      actorType: actorMap['actor_type'] as String?,
      roleCode: actorMap['role_code'] as String?,
      roleLabel: actorMap['role_label'] as String?,
      displayOrigin: TenantAuditDisplayOrigin.fromCode(actorMap['display_origin'] as String?),
    );
  }
}

final class TenantAuditSubject {
  const TenantAuditSubject({
    this.type,
    this.id,
    this.displayName,
    this.code,
    this.secondaryLabel,
    this.displayOrigin,
  });

  final String? type;
  final String? id;
  final String? displayName;
  final String? code;
  final String? secondaryLabel;
  final TenantAuditDisplayOrigin? displayOrigin;

  factory TenantAuditSubject.fromJson(Map<String, dynamic>? subjectMap) {
    if (subjectMap == null) {
      return const TenantAuditSubject(displayOrigin: TenantAuditDisplayOrigin.unavailable);
    }
    return TenantAuditSubject(
      type: subjectMap['type'] as String?,
      id: subjectMap['id'] as String?,
      displayName: subjectMap['display_name'] as String?,
      code: subjectMap['code'] as String?,
      secondaryLabel: subjectMap['secondary_label'] as String?,
      displayOrigin: TenantAuditDisplayOrigin.fromCode(subjectMap['display_origin'] as String?),
    );
  }
}

final class TenantAuditLogItem {
  const TenantAuditLogItem({
    required this.auditLogId,
    required this.eventCode,
    this.eventCategory,
    required this.result,
    required this.occurredAt,
    required this.source,
    required this.trackingId,
    required this.actor,
    required this.subject,
  });

  final String auditLogId;
  final String eventCode;
  final TenantAuditEventCategory? eventCategory;
  final TenantAuditLogResult result;
  final DateTime occurredAt;
  final String source;
  final String trackingId;
  final TenantAuditActor actor;
  final TenantAuditSubject subject;

  factory TenantAuditLogItem.fromJson(Map<String, dynamic> row) {
    return TenantAuditLogItem(
      auditLogId: row['audit_log_id'] as String,
      eventCode: row['event_code'] as String,
      eventCategory: TenantAuditEventCategory.fromCode(row['event_category'] as String?),
      result:
          TenantAuditLogResultCodes.fromCode(row['result'] as String?) ??
          TenantAuditLogResult.success,
      occurredAt: DateTime.parse(row['occurred_at'] as String),
      source: (row['source'] as String?) ?? 'iam',
      trackingId: (row['tracking_id'] as String?) ?? '',
      actor: TenantAuditActor.fromJson((row['actor'] as Map?)?.cast<String, dynamic>()),
      subject: TenantAuditSubject.fromJson((row['subject'] as Map?)?.cast<String, dynamic>()),
    );
  }
}

final class TenantAuditLogPage {
  const TenantAuditLogPage({required this.items, required this.totalCount, this.nextCursor});

  final List<TenantAuditLogItem> items;
  final int totalCount;
  final String? nextCursor;

  factory TenantAuditLogPage.fromJson(Map<String, dynamic> page) {
    final items = (page['items'] as List? ?? const [])
        .map((item) => TenantAuditLogItem.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList(growable: false);
    return TenantAuditLogPage(
      items: items,
      totalCount: (page['total_count'] as num?)?.toInt() ?? items.length,
      nextCursor: page['next_cursor'] as String?,
    );
  }
}

final class TenantAuditLogDetail {
  const TenantAuditLogDetail({
    required this.auditLogId,
    this.auditDisplayId,
    required this.tenantId,
    this.activityCode,
    required this.eventCode,
    this.eventCategory,
    this.titleSnapshot,
    required this.result,
    required this.occurredAt,
    required this.source,
    this.correlationId,
    required this.trackingId,
    required this.actorUnavailable,
    required this.beforeRedacted,
    required this.afterRedacted,
    required this.actor,
    required this.subject,
    this.beforeState,
    this.afterState,
  });

  final String auditLogId;
  final String? auditDisplayId;
  final String tenantId;
  final String? activityCode;
  final String eventCode;
  final TenantAuditEventCategory? eventCategory;
  final String? titleSnapshot;
  final TenantAuditLogResult result;
  final DateTime occurredAt;
  final String source;
  final String? correlationId;
  final String trackingId;
  final bool actorUnavailable;
  final bool beforeRedacted;
  final bool afterRedacted;
  final TenantAuditActor actor;
  final TenantAuditSubject subject;
  final Map<String, Object?>? beforeState;
  final Map<String, Object?>? afterState;

  factory TenantAuditLogDetail.fromJson(Map<String, dynamic> row) {
    return TenantAuditLogDetail(
      auditLogId: row['audit_log_id'] as String,
      auditDisplayId: row['audit_display_id'] as String?,
      tenantId: row['tenant_id'] as String,
      activityCode: row['activity_code'] as String?,
      eventCode: row['event_code'] as String,
      eventCategory: TenantAuditEventCategory.fromCode(row['event_category'] as String?),
      titleSnapshot: row['title_snapshot'] as String?,
      result:
          TenantAuditLogResultCodes.fromCode(row['result'] as String?) ??
          TenantAuditLogResult.success,
      occurredAt: DateTime.parse(row['occurred_at'] as String),
      source: (row['source'] as String?) ?? 'iam',
      correlationId: row['correlation_id'] as String?,
      trackingId: (row['tracking_id'] as String?) ?? '',
      actorUnavailable: row['actor_unavailable'] as bool? ?? false,
      beforeRedacted: row['before_redacted'] as bool? ?? false,
      afterRedacted: row['after_redacted'] as bool? ?? false,
      actor: TenantAuditActor.fromJson((row['actor'] as Map?)?.cast<String, dynamic>()),
      subject: TenantAuditSubject.fromJson((row['subject'] as Map?)?.cast<String, dynamic>()),
      beforeState: _asJsonMap(row['before_state']),
      afterState: _asJsonMap(row['after_state']),
    );
  }
}

Map<String, Object?>? _asJsonMap(Object? value) {
  if (value == null) return null;
  return Map<String, Object?>.unmodifiable(
    (value as Map).map((key, item) => MapEntry(key.toString(), item)),
  );
}

// TODO(P9): xoá typedef khi cubit / widget không còn tên DTO cũ.
typedef TenantAuditLogSummaryDto = TenantAuditLogItem;
typedef TenantAuditLogDetailDto = TenantAuditLogDetail;
typedef TenantAuditLogSearchPageDto = TenantAuditLogPage;
typedef TenantAuditActorDto = TenantAuditActor;
typedef TenantAuditSubjectDto = TenantAuditSubject;
