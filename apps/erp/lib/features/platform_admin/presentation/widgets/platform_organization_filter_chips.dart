import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../logic/platform_tenants_state.dart';

/// 4 chip trạng thái ở C1: Tất cả / Đang hoạt động / Tạm ngừng / Đã đóng.
class PlatformOrganizationFilterChips extends StatelessWidget {
  const PlatformOrganizationFilterChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final PlatformTenantFilter selected;
  final ValueChanged<PlatformTenantFilter> onSelected;

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
          children: [
            for (final filter in PlatformTenantFilter.values)
              Padding(
                padding: const EdgeInsets.only(right: VSpacing.space2),
                child: VChip(
                  label: filter.label,
                  tone: filter == selected ? VComponentTone.primary : VComponentTone.neutral,
                  onTap: () => onSelected(filter),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
