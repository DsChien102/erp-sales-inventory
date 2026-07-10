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
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.space4,
        vertical: VSpacing.space2,
      ),
      child: Row(
        children: [
          _buildChip(
            context,
            label: 'Tất cả',
            isSelected: selectedRole == null,
            onTap: () => onRoleSelected(null),
          ),
          const SizedBox(width: VSpacing.space2),
          _buildChip(
            context,
            label: 'Khách hàng',
            isSelected: selectedRole == PartnerRoleFilter.customer,
            onTap: () => onRoleSelected(PartnerRoleFilter.customer),
          ),
          const SizedBox(width: VSpacing.space2),
          _buildChip(
            context,
            label: 'Nhà cung cấp',
            isSelected: selectedRole == PartnerRoleFilter.supplier,
            onTap: () => onRoleSelected(PartnerRoleFilter.supplier),
          ),
          const SizedBox(width: VSpacing.space2),
          _buildChip(
            context,
            label: 'KH & NCC',
            isSelected: selectedRole == PartnerRoleFilter.both,
            onTap: () => onRoleSelected(PartnerRoleFilter.both),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colors = context.vColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : colors.background,
          border: Border.all(
            color: isSelected ? colors.primary : colors.borderDefault,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: VTypography.bodySmall.copyWith(
            color: isSelected ? Colors.white : colors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
