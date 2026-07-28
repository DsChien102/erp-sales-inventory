import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_presentation/presentation.dart';

abstract final class PlatformAuditUiMapper {
  static AuditLogStatus toUiStatus(PlatformAuditLogStatus status) {
    return switch (status) {
      PlatformAuditLogStatus.success => AuditLogStatus.success,
      PlatformAuditLogStatus.blocked => AuditLogStatus.blocked,
      PlatformAuditLogStatus.error => AuditLogStatus.error,
    };
  }

  static String statusLabel(PlatformAuditLogStatus status) {
    return switch (status) {
      PlatformAuditLogStatus.success => 'Thành công',
      PlatformAuditLogStatus.blocked => 'Bị chặn',
      PlatformAuditLogStatus.error => 'Lỗi',
    };
  }

  static AuditLogItemUiModel fromSummary(PlatformAuditLogSummaryDto dto) {
    return AuditLogItemUiModel(
      id: dto.id.startsWith('#') ? dto.id : '#${dto.id}',
      title: dto.title,
      actionCode: dto.actionCode,
      status: toUiStatus(dto.status),
      statusLabel: statusLabel(dto.status),
      actorName: dto.actorName,
      actorRole: dto.actorRole,
      targetOrg: dto.targetOrgName,
      targetOrgCode: dto.targetOrgCode,
      timestamp: dto.timestamp,
      sourceApp: dto.sourceApp,
      correlationId: '',
      beforeState: '',
      afterState: '',
      icon: VIcons.edit,
    );
  }

  static AuditLogItemUiModel fromDetail(PlatformAuditLogDetailDto dto) {
    return AuditLogItemUiModel(
      id: dto.id.startsWith('#') ? dto.id : '#${dto.id}',
      title: dto.title,
      actionCode: dto.actionCode,
      status: toUiStatus(dto.status),
      statusLabel: dto.statusLabel.isEmpty ? statusLabel(dto.status) : dto.statusLabel,
      actorName: dto.actorName,
      actorRole: dto.actorRole,
      targetOrg: dto.targetOrgName,
      targetOrgCode: dto.targetOrgCode,
      timestamp: dto.timestamp,
      sourceApp: dto.sourceApp,
      correlationId: dto.correlationId,
      beforeState: dto.beforeState,
      afterState: dto.afterState,
      icon: VIcons.edit,
    );
  }
}
