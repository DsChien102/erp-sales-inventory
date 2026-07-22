import 'package:vet45_design_system/design_system.dart';

/// Trạng thái của nhật ký thao tác nền tảng.
enum AuditLogStatus { success, blocked, error }

/// Model dữ liệu nhật ký thao tác nền tảng (Audit Log Item UI Model).
class AuditLogItemUiModel {
  final String id;
  final String title;
  final String actionCode;
  final AuditLogStatus status;
  final String statusLabel;
  final String actorName;
  final String actorRole;
  final String targetOrg;
  final String targetOrgCode;
  final DateTime timestamp;
  final String sourceApp;
  final String correlationId;
  final String beforeState;
  final String afterState;
  final VIcons icon;

  const AuditLogItemUiModel({
    required this.id,
    required this.title,
    required this.actionCode,
    required this.status,
    required this.statusLabel,
    required this.actorName,
    required this.actorRole,
    required this.targetOrg,
    required this.targetOrgCode,
    required this.timestamp,
    required this.sourceApp,
    required this.correlationId,
    required this.beforeState,
    required this.afterState,
    required this.icon,
  });
}
