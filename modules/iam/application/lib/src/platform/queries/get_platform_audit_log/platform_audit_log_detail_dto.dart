import '../../shared/platform_audit_log_status.dart';

/// Detail DTO for a platform audit log (EP-02/US-10). Sensitive fields are redacted.
final class PlatformAuditLogDetailDto {
  const PlatformAuditLogDetailDto({
    required this.id,
    this.auditNo = 0,
    required this.title,
    required this.actionCode,
    required this.status,
    required this.statusLabel,
    required this.actorName,
    required this.actorRole,
    required this.targetOrgName,
    required this.targetOrgCode,
    this.targetType = '',
    this.targetDisplayName = '',
    required this.timestamp,
    required this.sourceApp,
    required this.correlationId,
    required this.beforeState,
    required this.afterState,
    this.changeBefore = const {},
    this.changeAfter = const {},
  });

  final String id;

  /// Số tuần tự hiển thị (AUD-000982) từ `audit_logs.audit_no`.
  final int auditNo;
  final String title;
  final String actionCode;
  final PlatformAuditLogStatus status;
  final String statusLabel;
  final String actorName;
  final String actorRole;
  final String targetOrgName;
  final String targetOrgCode;

  /// Loại đối tượng thô (vd `account`, `Tenant`) để UI chọn nhãn phù hợp.
  final String targetType;

  /// Tên hiển thị của đối tượng (tên tổ chức hoặc tên/email người dùng).
  final String targetDisplayName;
  final DateTime timestamp;
  final String sourceApp;
  final String correlationId;
  final String beforeState;
  final String afterState;

  /// Trạng thái trước/sau dạng map field→value, để dựng diff "Trước/Sau".
  final Map<String, Object?> changeBefore;
  final Map<String, Object?> changeAfter;
}
