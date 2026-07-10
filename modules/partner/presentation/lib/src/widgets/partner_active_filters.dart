import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_domain/domain.dart';
import '../bloc/partner_list_state.dart';

class PartnerActiveFilters extends StatelessWidget {
  const PartnerActiveFilters({
    super.key,
    required this.partnerType,
    required this.roleFilter,
    required this.status,
    required this.onRemoveFilter,
    required this.onClearAll,
  });

  final PartnerType? partnerType;
  final PartnerRoleFilter? roleFilter;
  final PartnerStatus? status;
  final ValueChanged<String> onRemoveFilter;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final hasFilters = partnerType != null || status != null;
    if (!hasFilters) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.space4,
        vertical: VSpacing.space2,
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (partnerType != null) ...[
                    _buildActiveChip(
                      context,
                      label: partnerType == PartnerType.person ? 'Cá nhân' : 'Tổ chức',
                      onRemove: () => onRemoveFilter('partnerType'),
                    ),
                    const SizedBox(width: VSpacing.space2),
                  ],
                  if (status != null) ...[
                    _buildActiveChip(
                      context,
                      label: status == PartnerStatus.active ? 'Đang hoạt động' : 'Ngừng hoạt động',
                      onRemove: () => onRemoveFilter('status'),
                    ),
                    const SizedBox(width: VSpacing.space2),
                  ],
                ],
              ),
            ),
          ),
          InkWell(
            onTap: onClearAll,
            child: Padding(
              padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
              child: Text(
                'Xóa lọc',
                style: VTypography.bodySmall.copyWith(
                  color: context.vColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveChip(
    BuildContext context, {
    required String label,
    required VoidCallback onRemove,
  }) {
    final colors = context.vColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: VColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: VTypography.bodySmall.copyWith(
              color: colors.success,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 14, color: VColors.success),
          ),
        ],
      ),
    );
  }
}
