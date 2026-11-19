import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/features/partner/data/models/partner_models.dart';

import 'partner_detail_expandable_card.dart';
import 'partner_detail_formatters.dart';

/// Card «Địa chỉ giao hàng» — tỉnh/thành, xã/phường, địa chỉ chi tiết.
class PartnerDetailDeliveryCard extends StatelessWidget {
  const PartnerDetailDeliveryCard({
    super.key,
    required this.dto,
    this.initiallyExpanded = false,
  });

  final PartnerDetailDto dto;
  final bool initiallyExpanded;

  static const _empty = '—';

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final delivery = PartnerDetailFormatters.delivery(dto);
    final province = delivery?.province?.trim() ?? '';
    final commune = delivery?.commune?.trim() ?? '';
    final address = delivery?.address?.trim() ?? '';
    final isEmpty = province.isEmpty && commune.isEmpty && address.isEmpty;

    return PartnerDetailExpandableCard(
      title: 'Địa chỉ giao hàng',
      icon: VIcons.location,
      initiallyExpanded: initiallyExpanded,
      trailingWhenCollapsed: isEmpty
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(VRadius.r8),
              ),
              child: VText(
                'Chưa có',
                style: VTypography.bodySmall.copyWith(
                  color: colors.warning,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Field(
            label: 'Tỉnh / Thành phố',
            value: province.isEmpty ? _empty : province,
          ),
          const SizedBox(height: VSpacing.space3),
          _Field(
            label: 'Xã / Phường',
            value: commune.isEmpty ? _empty : commune,
          ),
          const SizedBox(height: VSpacing.space3),
          _Field(
            label: 'Địa chỉ chi tiết',
            value: address.isEmpty ? _empty : address,
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final isEmpty = value == PartnerDetailDeliveryCard._empty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VText(
          label,
          style: VTypography.bodySmall.copyWith(
            color: colors.textSecondary,
            fontSize: 11,
          ),
        ),
        const VGap.xs(),
        VText(
          value,
          variant: VTextVariant.bodyDefault,
          color: isEmpty ? colors.textMuted : colors.textPrimary,
          style: TextStyle(fontWeight: isEmpty ? FontWeight.w400 : FontWeight.w500),
        ),
      ],
    );
  }
}
