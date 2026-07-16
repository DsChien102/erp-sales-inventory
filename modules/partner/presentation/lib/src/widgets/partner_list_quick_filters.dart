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
              selected: selectedRole == null,
              onTap: () => onRoleSelected(null),
            ),
            VChip(
              label: 'Khách hàng',
              selected: selectedRole == PartnerRoleFilter.customer,
              onTap: () => onRoleSelected(PartnerRoleFilter.customer),
            ),
            VChip(
              label: 'Nhà cung cấp',
              selected: selectedRole == PartnerRoleFilter.supplier,
              onTap: () => onRoleSelected(PartnerRoleFilter.supplier),
            ),
            VChip(
              label: 'KH & NCC',
              selected: selectedRole == PartnerRoleFilter.both,
              onTap: () => onRoleSelected(PartnerRoleFilter.both),
            ),
          ],
        ),
      ),
    );
  }
}
