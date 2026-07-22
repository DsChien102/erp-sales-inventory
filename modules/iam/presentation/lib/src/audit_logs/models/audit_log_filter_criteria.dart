import 'audit_log_ui_model.dart';

/// Class chứa các tiêu chí lọc nâng cao cho danh sách nhật ký nền tảng (AuditLogFilterCriteria).
class AuditLogFilterCriteria {
  final String timeRange;
  final AuditLogStatus? status;
  final String actorType;

  const AuditLogFilterCriteria({
    this.timeRange = '24 giờ',
    this.status,
    this.actorType = 'Tất cả',
  });

  /// Kiểm tra xem có tiêu chí lọc nào khác mặc định không.
  bool get isFilterActive =>
      timeRange != '24 giờ' || status != null || actorType != 'Tất cả';

  AuditLogFilterCriteria copyWith({
    String? timeRange,
    AuditLogStatus? status,
    bool clearStatus = false,
    String? actorType,
  }) {
    return AuditLogFilterCriteria(
      timeRange: timeRange ?? this.timeRange,
      status: clearStatus ? null : (status ?? this.status),
      actorType: actorType ?? this.actorType,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuditLogFilterCriteria &&
          runtimeType == other.runtimeType &&
          timeRange == other.timeRange &&
          status == other.status &&
          actorType == other.actorType;

  @override
  int get hashCode => timeRange.hashCode ^ status.hashCode ^ actorType.hashCode;
}
