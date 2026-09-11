import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../models/organization_ui_model.dart';

/// Widget lọc trạng thái danh sách tổ chức bằng các [VChip] nằm ngang.
class OrganizationFilterChips extends StatelessWidget {
  final OrganizationStatus selectedStatus;
  final ValueChanged<OrganizationStatus> onStatusSelected;

  const OrganizationFilterChips({
    super.key,
    required this.selectedStatus,
    required this.onStatusSelected,
  });

  static const List<OrganizationStatus> filterOptions = [
    OrganizationStatus.all,
    OrganizationStatus.settingUp,
    OrganizationStatus.active,
    OrganizationStatus.suspended,
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
          children: filterOptions.map((status) {
            final isSelected = selectedStatus == status;
            return Padding(
              padding: const EdgeInsets.only(right: VSpacing.space2),
              child: VChip(
                label: status.filterLabel,
                tone: isSelected
                    ? VComponentTone.primary
                    : VComponentTone.neutral,
                onTap: () => onStatusSelected(status),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
