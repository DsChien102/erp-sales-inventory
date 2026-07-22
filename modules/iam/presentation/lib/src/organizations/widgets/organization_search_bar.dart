import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Widget thanh tìm kiếm và nút Filter cho danh sách tổ chức.
class OrganizationSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;
  final bool isFilterActive;

  const OrganizationSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    this.onFilterTap,
    this.isFilterActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.screenMobile,
        vertical: VSpacing.space2,
      ),
      child: Row(
        children: [
          Expanded(
            child: VSearchBar(
              hintText: 'Tìm tên hoặc mã tổ chức',
              controller: controller,
              onChanged: onChanged,
            ),
          ),
          const VGap.horizontalSm(),
          VIconBox(
            icon: VIcons.tune,
            size: 44,
            iconSize: 20,
            backgroundColor: isFilterActive ? colors.surfaceBrand : colors.surface,
            iconColor: isFilterActive ? colors.primary : colors.textPrimary,
            borderColor: isFilterActive ? colors.primary : colors.borderDefault,
            borderRadius: VRadius.button,
            onTap: onFilterTap,
          ),
        ],
      ),
    );
  }
}
