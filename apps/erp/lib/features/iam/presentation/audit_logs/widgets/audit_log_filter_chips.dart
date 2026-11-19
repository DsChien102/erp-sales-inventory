import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';
import '../models/audit_log_ui_model.dart';

/// Widget lọc trạng thái danh sách nhật ký bằng các [VChip] nằm ngang (chuẩn theo OrganizationFilterChips).
class AuditLogFilterChips extends StatelessWidget {
  final AuditLogStatus? selectedStatus;
  final ValueChanged<AuditLogStatus?> onStatusSelected;

  const AuditLogFilterChips({
    super.key,
    required this.selectedStatus,
    required this.onStatusSelected,
  });

  static const List<({String label, AuditLogStatus? status})> filterOptions = [
    (label: 'Tất cả', status: null),
    (label: 'Thành công', status: AuditLogStatus.success),
    (label: 'Bị chặn', status: AuditLogStatus.blocked),
    (label: 'Lỗi', status: AuditLogStatus.error),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: VSpacing.screenMobile,
          vertical: VSpacing.space1,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: filterOptions.map((option) {
            final isSelected = selectedStatus == option.status;
            return Padding(
              padding: const EdgeInsets.only(right: VSpacing.space2),
              child: VChip(
                label: option.label,
                tone: isSelected ? VComponentTone.primary : VComponentTone.neutral,
                onTap: () => onStatusSelected(option.status),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
