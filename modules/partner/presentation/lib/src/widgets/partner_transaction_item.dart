import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import '../bloc/partner_detail_state.dart';

class PartnerTransactionItem extends StatelessWidget {
  final TransactionItemModel transaction;

  const PartnerTransactionItem({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    
    final statusColor = transaction.status == 'Đã hoàn tất' ? VColors.success : dynamicColors.textSecondary;
    final statusBgColor = transaction.status == 'Đã hoàn tất' ? VColors.successBg : dynamicColors.borderDefault;

    return Container(
      margin: const EdgeInsets.only(bottom: VSpacing.space3),
      padding: const EdgeInsets.all(VSpacing.space4),
      decoration: BoxDecoration(
        color: dynamicColors.surface,
        borderRadius: BorderRadius.circular(VRadius.card),
        border: Border.all(color: dynamicColors.borderDefault),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: VColors.successBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined, // Box icon
                  color: VColors.success,
                  size: 20,
                ),
              ),
              const SizedBox(width: VSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.title,
                      style: VTypography.bodyDefault.copyWith(
                        fontWeight: FontWeight.w600,
                        color: dynamicColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      transaction.id,
                      style: VTypography.bodySmall.copyWith(
                        color: dynamicColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: dynamicColors.textMuted,
              ),
            ],
          ),
          const SizedBox(height: VSpacing.space3),
          const Divider(height: 1),
          const SizedBox(height: VSpacing.space3),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 14, color: dynamicColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                transaction.date,
                style: VTypography.bodySmall.copyWith(
                  color: dynamicColors.textSecondary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  transaction.status,
                  style: VTypography.bodySmall.copyWith(
                    color: statusColor,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(width: VSpacing.space2),
              Text(
                transaction.amount,
                style: VTypography.bodyDefault.copyWith(
                  fontWeight: FontWeight.w700,
                  color: dynamicColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
