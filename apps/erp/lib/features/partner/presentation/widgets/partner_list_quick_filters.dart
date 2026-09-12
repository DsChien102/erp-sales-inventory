import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import '../bloc/partner_list_state.dart';

class PartnerListQuickFilters extends StatelessWidget {
  const PartnerListQuickFilters({
    super.key,
    required this.selectedRole,
    required this.onRoleSelected,
  });

  final PartnerRoleFilter? selectedRole;
  final ValueChanged<PartnerRoleFilter?> onRoleSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: VPagePadding(
        child: Row(
          spacing: VSpacing.sm,
          children: [
            VChip(
              label: 'Tất cả',
              tone: selectedRole == null
                  ? VComponentTone.primary
                  : VComponentTone.neutral,
              onTap: () => onRoleSelected(null),
            ),
            VChip(
              label: 'Khách hàng',
              tone: selectedRole == PartnerRoleFilter.customer
                  ? VComponentTone.primary
                  : VComponentTone.neutral,
              onTap: () => onRoleSelected(PartnerRoleFilter.customer),
            ),
            VChip(
              label: 'Nhà cung cấp',
              tone: selectedRole == PartnerRoleFilter.supplier
                  ? VComponentTone.primary
                  : VComponentTone.neutral,
              onTap: () => onRoleSelected(PartnerRoleFilter.supplier),
            ),
            VChip(
              label: 'KH & NCC',
              tone: selectedRole == PartnerRoleFilter.both
                  ? VComponentTone.primary
                  : VComponentTone.neutral,
              onTap: () => onRoleSelected(PartnerRoleFilter.both),
            ),
          ],
        ),
      ),
    );
  }
}
