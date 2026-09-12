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
    required this.updatedTimeFilter,
    required this.onRemoveFilter,
    required this.onClearAll,
  });

  final PartnerType? partnerType;
  final PartnerRoleFilter? roleFilter;
  final PartnerStatus? status;
  final PartnerUpdatedTimeFilter? updatedTimeFilter;
  final ValueChanged<String> onRemoveFilter;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final hasFilters =
        partnerType != null || roleFilter != null || status != null || updatedTimeFilter != null;
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
                    _FilterChip(
                      label: partnerType == PartnerType.person ? 'Cá nhân' : 'Tổ chức',
                      onRemove: () => onRemoveFilter('partnerType'),
                    ),
                    const SizedBox(width: VSpacing.space2),
                  ],
                  if (status != null) ...[
                    _FilterChip(
                      label: status == PartnerStatus.active ? 'Đang hoạt động' : 'Ngừng hoạt động',
                      onRemove: () => onRemoveFilter('status'),
                    ),
                    const SizedBox(width: VSpacing.space2),
                  ],
                  if (updatedTimeFilter != null) ...[
                    _FilterChip(
                      label: updatedTimeFilter == PartnerUpdatedTimeFilter.last7Days
                          ? '7 ngày gần đây'
                          : '30 ngày gần đây',
                      onRemove: () => onRemoveFilter('updatedTime'),
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
              child: VText(
                'Xóa lọc',
                variant: VTextVariant.bodySmall,
                color: context.vColors.primary,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.onRemove,
  });

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return VChip(
      label: label,
      tone: VComponentTone.success,
      onRemove: onRemove,
    );
  }
}
