import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// D-07 SG-03 — Thông tin áp dụng read-only (avatar + SP/ĐV trong 1 [VCard]).
class PriceRuleFormIdentityCard extends StatelessWidget {
  const PriceRuleFormIdentityCard({
    super.key,
    required this.customerName,
    required this.customerId,
    required this.productName,
    required this.productUnitName,
  });

  final String customerName;
  final String customerId;
  final String productName;
  final String productUnitName;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return VCard(
      padding: const EdgeInsets.all(VSpacing.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VAvatar(name: customerName, textSize: 16),
              const VGap.horizontalMd(),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VText(
                      customerName,
                      variant: VTextVariant.bodyDefault,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const VGap.xs(),
                    VText(
                      customerId,
                      variant: VTextVariant.bodySmall,
                      color: colors.textSecondary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const VGap.md(),
          _LabeledValueRow(label: 'Sản phẩm', value: productName),
          const VGap.sm(),
          _LabeledValueRow(
            label: 'Đơn vị bán',
            value: productUnitName,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

/// D-07 SG-03 — Card audit cập nhật gần nhất (icon + copy).
class PriceRuleFormLastUpdatedCard extends StatelessWidget {
  const PriceRuleFormLastUpdatedCard({
    super.key,
    required this.updatedAt,
    required this.updatedBy,
  });

  final DateTime updatedAt;
  final String updatedBy;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final local = updatedAt.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    final y = local.year;
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    final formatted = '$d/$m/$y $h:$min';

    return VCard(
      padding: const EdgeInsets.all(VSpacing.space3),
      backgroundColor: colors.surfaceAlt,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VIconBox(
            icon: VIcons.info,
            size: 36,
            iconSize: 18,
            tone: VComponentTone.neutral,
            backgroundColor: colors.surface,
            iconColor: colors.textSecondary,
          ),
          const VGap.horizontalMd(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VText(
                  'Cập nhật gần nhất',
                  variant: VTextVariant.bodyDefault,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const VGap.xs(),
                VText(
                  'Cập nhật bởi: $updatedBy',
                  variant: VTextVariant.bodySmall,
                  color: colors.textSecondary,
                ),
                const VGap.xs(),
                VText(
                  formatted,
                  variant: VTextVariant.bodySmallMono,
                  color: colors.textSecondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledValueRow extends StatelessWidget {
  const _LabeledValueRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : VSpacing.space1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: VText(
              label,
              variant: VTextVariant.bodySmall,
              color: colors.textSecondary,
            ),
          ),
          Expanded(
            child: VText(
              value,
              variant: VTextVariant.bodyDefault,
              color: colors.textPrimary,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
