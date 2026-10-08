import 'package:vet45_design_system/design_system.dart';
import '../../../data/models/tenant_audit_log.dart';

/// Trạng thái của nhật ký thao tác.
enum AuditLogStatus { success, blocked, error }

/// Dòng thay đổi dữ liệu giữa trước và sau thao tác.
final class AuditLogChangeRowUiModel {
  const AuditLogChangeRowUiModel({
    required this.fieldKey,
    required this.fieldLabel,
    required this.beforeValue,
    required this.afterValue,
    required this.isChanged,
  });

  final String fieldKey;
  final String fieldLabel;
  final String? beforeValue;
  final String? afterValue;
  final bool isChanged;
}

/// Model dữ liệu nhật ký thao tác (Audit Log Item UI Model).
class AuditLogItemUiModel {
  final String id;
  final String title;
  final String actionCode;
  final AuditLogStatus status;
  final String statusLabel;
  final String actorName;
  final String actorRole;
  final String actorId;
  final String actorType;
  final String actorRoleCode;
  final TenantAuditDisplayOrigin actorDisplayOrigin;
  final String targetOrg;
  final String targetOrgCode;
  final DateTime timestamp;
  final String sourceApp;
  final String correlationId;
  final String beforeState;
  final String afterState;
  final VIcons icon;
  final String? category;
  final TenantAuditEventCategory? eventCategory;
  final String? targetSubjectLabel;
  final String? targetSubjectValue;
  final String? targetDetailLabel;
  final String? targetDetailValue;
  final String subjectName;
  final String subjectType;
  final String subjectId;
  final String subjectCode;
  final TenantAuditDisplayOrigin subjectDisplayOrigin;
  final String? changeSectionTitle;
  final List<AuditLogChangeRowUiModel> changes;
  final bool isActorUnavailable;
  final bool beforeRedacted;
  final bool afterRedacted;

  /// Mã audit hiển thị cho người dùng (vd `AUD-000982`); null nếu không có.
  final String? auditDisplayId;

  const AuditLogItemUiModel({
    required this.id,
    this.auditDisplayId,
    required this.title,
    required this.actionCode,
    required this.status,
    required this.statusLabel,
    required this.actorName,
    required this.actorRole,
    this.actorId = '',
    this.actorType = '',
    this.actorRoleCode = '',
    this.actorDisplayOrigin = TenantAuditDisplayOrigin.snapshot,
    required this.targetOrg,
    required this.targetOrgCode,
    required this.timestamp,
    required this.sourceApp,
    required this.correlationId,
    required this.beforeState,
    required this.afterState,
    required this.icon,
    this.category,
    this.eventCategory,
    this.targetSubjectLabel,
    this.targetSubjectValue,
    this.targetDetailLabel,
    this.targetDetailValue,
    this.subjectName = '',
    this.subjectType = '',
    this.subjectId = '',
    this.subjectCode = '',
    this.subjectDisplayOrigin = TenantAuditDisplayOrigin.snapshot,
    this.changeSectionTitle,
    this.changes = const [],
    this.isActorUnavailable = false,
    this.beforeRedacted = false,
    this.afterRedacted = false,
  });
}
