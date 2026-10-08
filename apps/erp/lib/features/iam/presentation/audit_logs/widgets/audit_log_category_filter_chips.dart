import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../../data/models/tenant_audit_log.dart';

/// Dải chip lọc danh mục nhật ký thao tác (Tất cả, Thành viên, Vai trò, Tổ chức).
class AuditLogCategoryFilterChips extends StatelessWidget {
  final TenantAuditEventCategory? selectedCategory;
  final ValueChanged<TenantAuditEventCategory?> onCategorySelected;

  const AuditLogCategoryFilterChips({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  static const List<({String label, TenantAuditEventCategory? category})> filterOptions = [
    (label: 'Tất cả', category: null),
    (label: 'Thành viên', category: TenantAuditEventCategory.member),
    (label: 'Vai trò', category: TenantAuditEventCategory.role),
    (label: 'Tổ chức', category: TenantAuditEventCategory.organization),
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
            final isSelected = selectedCategory == option.category;
            return Padding(
              padding: const EdgeInsets.only(right: VSpacing.space2),
              child: VChip(
                label: option.label,
                tone: isSelected
                    ? VComponentTone.primary
                    : VComponentTone.neutral,
                onTap: () => onCategorySelected(option.category),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
