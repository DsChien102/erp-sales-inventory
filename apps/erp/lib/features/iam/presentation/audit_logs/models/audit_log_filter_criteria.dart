import '../../../logic/tenant_audit_filter.dart';
import 'audit_log_ui_model.dart';

/// Tiêu chí lọc nâng cao cho danh sách lịch sử quản trị.
class AuditLogFilterCriteria {
  final TenantAuditRange range;
  final AuditLogStatus? status;

  const AuditLogFilterCriteria({
    this.range = TenantAuditRange.d30,
    this.status,
  });

  /// Kiểm tra xem có tiêu chí lọc nào khác mặc định không.
  bool get isFilterActive => range != TenantAuditRange.d30 || status != null;

  AuditLogFilterCriteria copyWith({
    TenantAuditRange? range,
    AuditLogStatus? status,
    bool clearStatus = false,
  }) {
    return AuditLogFilterCriteria(
      range: range ?? this.range,
      status: clearStatus ? null : (status ?? this.status),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuditLogFilterCriteria &&
          runtimeType == other.runtimeType &&
          range == other.range &&
          status == other.status;

  @override
  int get hashCode => range.hashCode ^ status.hashCode;
}
