import 'dart:convert';

import 'package:vet45_iam_application/application.dart';

import '../catalog/tenant_audit_event_catalog.dart';
import '../catalog/tenant_audit_field_catalog.dart';
import '../models/audit_log_ui_model.dart';

/// Maps Application audit DTOs to Presentation UI models using event & field catalogs.
abstract final class TenantAuditUiMapper {
  static const _redactedValue = '[Đã che theo chính sách]';

  static AuditLogItemUiModel fromSummary(TenantAuditLogSummaryDto dto) {
    final entry = TenantAuditEventCatalog.entryFor(dto.eventCode);
    final eventCategory = dto.eventCategory ?? entry.category;
    final status = _status(dto.result);
    final actorName = _resolveActorName(dto.actor);
    final actorRole = _resolveActorRole(dto.actor);
    final localizedSubject = _localizedSubjectType(dto.subject.type);
    final subjectName = _resolveSubjectName(dto.subject);
    final detailValue = dto.subject.code ?? dto.subject.secondaryLabel ?? '—';

    return AuditLogItemUiModel(
      id: dto.auditLogId,
      title: entry.title,
      actionCode: dto.eventCode,
      status: status,
      statusLabel: _statusLabel(status),
      actorName: actorName,
      actorRole: actorRole,
      actorId: dto.actor.userId ?? '',
      actorType: dto.actor.actorType ?? '',
      actorRoleCode: dto.actor.roleCode ?? '',
      actorDisplayOrigin: dto.actor.displayOrigin ?? TenantAuditDisplayOrigin.unavailable,
      targetOrg: subjectName,
      targetOrgCode: dto.subject.code ?? '',
      timestamp: dto.occurredAt,
      sourceApp: dto.source,
      correlationId: dto.trackingId,
      beforeState: '',
      afterState: '',
      icon: entry.icon,
      category: eventCategory.code,
      eventCategory: eventCategory,
      targetSubjectLabel: 'Loại đối tượng',
      targetSubjectValue: localizedSubject,
      targetDetailLabel: 'Mã đối tượng',
      targetDetailValue: detailValue,
      subjectName: subjectName,
      subjectType: dto.subject.type ?? '',
      subjectId: dto.subject.id ?? '',
      subjectCode: dto.subject.code ?? '',
      subjectDisplayOrigin: dto.subject.displayOrigin ?? TenantAuditDisplayOrigin.unavailable,
      isActorUnavailable: dto.actor.displayOrigin == TenantAuditDisplayOrigin.unavailable,
    );
  }

  static AuditLogItemUiModel fromDetail(TenantAuditLogDetailDto dto) {
    final entry = TenantAuditEventCatalog.entryFor(dto.eventCode);
    final eventCategory = dto.eventCategory ?? entry.category;
    final status = _status(dto.result);
    final actorUnavailable =
        dto.actorUnavailable || dto.actor.displayOrigin == TenantAuditDisplayOrigin.unavailable;
    final actorName = _resolveActorName(
      dto.actor,
      actorUnavailable: actorUnavailable,
    );
    final actorRole = _resolveActorRole(
      dto.actor,
      actorUnavailable: actorUnavailable,
    );
    final localizedSubject = _localizedSubjectType(dto.subject.type);
    final subjectName = _resolveSubjectName(dto.subject);
    final detailValue = dto.subject.code ?? dto.subject.secondaryLabel ?? '—';
    final changes = _computeChanges(
      dto.beforeState,
      dto.afterState,
      beforeRedacted: dto.beforeRedacted,
      afterRedacted: dto.afterRedacted,
    );

    return AuditLogItemUiModel(
      id: dto.auditLogId,
      title: entry.title,
      actionCode: dto.eventCode,
      status: status,
      statusLabel: _statusLabel(status),
      actorName: actorName,
      actorRole: actorRole,
      actorId: dto.actor.userId ?? '',
      actorType: dto.actor.actorType ?? '',
      actorRoleCode: dto.actor.roleCode ?? '',
      actorDisplayOrigin: dto.actor.displayOrigin ?? TenantAuditDisplayOrigin.unavailable,
      targetOrg: subjectName,
      targetOrgCode: dto.subject.code ?? '',
      timestamp: dto.occurredAt,
      sourceApp: dto.source,
      correlationId: dto.trackingId,
      beforeState: _formatStateJson(dto.beforeState, dto.beforeRedacted),
      afterState: _formatStateJson(dto.afterState, dto.afterRedacted),
      icon: entry.icon,
      category: eventCategory.code,
      eventCategory: eventCategory,
      targetSubjectLabel: 'Loại đối tượng',
      targetSubjectValue: localizedSubject,
      targetDetailLabel: 'Mã đối tượng',
      targetDetailValue: detailValue,
      subjectName: subjectName,
      subjectType: dto.subject.type ?? '',
      subjectId: dto.subject.id ?? '',
      subjectCode: dto.subject.code ?? '',
      subjectDisplayOrigin: dto.subject.displayOrigin ?? TenantAuditDisplayOrigin.unavailable,
      changeSectionTitle: 'Dữ liệu thay đổi',
      changes: changes,
      isActorUnavailable: actorUnavailable,
      beforeRedacted: dto.beforeRedacted,
      afterRedacted: dto.afterRedacted,
    );
  }

  static String _resolveActorName(
    TenantAuditActorDto actor, {
    bool actorUnavailable = false,
  }) {
    if (actorUnavailable || actor.displayOrigin == TenantAuditDisplayOrigin.unavailable) {
      return 'Không còn thông tin người thực hiện';
    }
    if (actor.displayOrigin == TenantAuditDisplayOrigin.system) {
      return 'Hệ thống';
    }
    if (actor.displayName != null && actor.displayName!.isNotEmpty) {
      return actor.displayName!;
    }
    return 'Người dùng không xác định';
  }

  static String _resolveSubjectName(TenantAuditSubjectDto subject) {
    if (subject.displayName != null && subject.displayName!.isNotEmpty) {
      return subject.displayName!;
    }
    if (subject.displayOrigin == TenantAuditDisplayOrigin.unavailable) {
      return 'Không còn thông tin đối tượng';
    }
    if (subject.displayOrigin == TenantAuditDisplayOrigin.system) {
      return 'Hệ thống';
    }
    return 'Đối tượng không xác định';
  }

  static String _resolveActorRole(
    TenantAuditActorDto actor, {
    bool actorUnavailable = false,
  }) {
    if (actorUnavailable || actor.displayOrigin == TenantAuditDisplayOrigin.unavailable) {
      return '—';
    }
    if (actor.displayOrigin == TenantAuditDisplayOrigin.system) {
      return 'Tiến trình hệ thống';
    }
    if (actor.roleLabel != null && actor.roleLabel!.isNotEmpty) {
      return actor.roleLabel!;
    }
    if (actor.roleCode != null && actor.roleCode!.isNotEmpty) {
      return TenantAuditFieldCatalog.formatValue('role', actor.roleCode);
    }
    return '—';
  }

  static String _localizedSubjectType(String? subjectType) {
    if (subjectType == null || subjectType.isEmpty) return '—';
    return switch (subjectType.toLowerCase()) {
      'tenant' || 'organization' => 'Tổ chức',
      'membership' || 'member' => 'Thành viên',
      'role' => 'Vai trò',
      'account' || 'user' => 'Tài khoản',
      'invitation' => 'Lời mời',
      _ => subjectType,
    };
  }

  static AuditLogStatus _status(TenantAuditLogResult result) {
    return switch (result) {
      TenantAuditLogResult.success => AuditLogStatus.success,
      TenantAuditLogResult.blocked => AuditLogStatus.blocked,
      TenantAuditLogResult.error => AuditLogStatus.error,
    };
  }

  static String _statusLabel(AuditLogStatus status) {
    return switch (status) {
      AuditLogStatus.success => 'Thành công',
      AuditLogStatus.blocked => 'Bị chặn',
      AuditLogStatus.error => 'Lỗi',
    };
  }

  static List<AuditLogChangeRowUiModel> _computeChanges(
    Map<String, Object?>? before,
    Map<String, Object?>? after, {
    required bool beforeRedacted,
    required bool afterRedacted,
  }) {
    final visibleBefore = beforeRedacted ? null : before;
    final visibleAfter = afterRedacted ? null : after;
    if (visibleBefore == null && visibleAfter == null) return const [];

    final keys = <String>{
      if (visibleBefore != null) ...visibleBefore.keys,
      if (visibleAfter != null) ...visibleAfter.keys,
    }.toList()..sort();

    final rows = <AuditLogChangeRowUiModel>[];
    for (final key in keys) {
      final beforeVal = visibleBefore?[key];
      final afterVal = visibleAfter?[key];
      if (!beforeRedacted && !afterRedacted && _deepEquals(beforeVal, afterVal)) {
        continue;
      }
      rows.add(
        AuditLogChangeRowUiModel(
          fieldKey: key,
          fieldLabel: TenantAuditFieldCatalog.labelFor(key),
          beforeValue: _formatSanitizedValue(
            key,
            beforeVal,
            isRedacted: beforeRedacted,
          ),
          afterValue: _formatSanitizedValue(
            key,
            afterVal,
            isRedacted: afterRedacted,
          ),
          isChanged: true,
        ),
      );
    }
    return rows;
  }

  static String _formatStateJson(Map<String, Object?>? state, bool isRedacted) {
    return _formatSanitizedValue(
      '',
      state,
      isRedacted: isRedacted,
      prettyJson: true,
    );
  }

  static String _formatSanitizedValue(
    String fieldKey,
    Object? value, {
    required bool isRedacted,
    bool prettyJson = false,
  }) {
    if (isRedacted) return _redactedValue;
    if (prettyJson && (value == null || (value is Map && value.isEmpty))) {
      return '';
    }
    final sanitized = _sanitizeFieldValue(fieldKey, value);
    if (!prettyJson) {
      return TenantAuditFieldCatalog.formatValue(fieldKey, sanitized);
    }
    try {
      return const JsonEncoder.withIndent('  ').convert(sanitized);
    } catch (_) {
      return sanitized.toString();
    }
  }

  static Object? _sanitizeFieldValue(String key, Object? value) {
    if (TenantAuditFieldCatalog.isSensitive(key)) return _redactedValue;
    return _sanitizeValue(value);
  }

  static Object? _sanitizeValue(Object? value) {
    if (value is Map) {
      return value.map(
        (key, item) => MapEntry(
          key.toString(),
          _sanitizeFieldValue(key.toString(), item),
        ),
      );
    }
    if (value is List) return value.map(_sanitizeValue).toList(growable: false);
    return value;
  }

  static bool _deepEquals(Object? left, Object? right) {
    if (identical(left, right)) return true;
    if (left is List && right is List) {
      if (left.length != right.length) return false;
      for (var index = 0; index < left.length; index++) {
        if (!_deepEquals(left[index], right[index])) return false;
      }
      return true;
    }
    if (left is Map && right is Map) {
      if (left.length != right.length) return false;
      for (final key in left.keys) {
        if (!right.containsKey(key) || !_deepEquals(left[key], right[key])) {
          return false;
        }
      }
      return true;
    }
    return left == right;
  }
}
