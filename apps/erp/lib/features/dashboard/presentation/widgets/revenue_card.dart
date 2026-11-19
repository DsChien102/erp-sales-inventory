import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

class RevenueCard extends StatelessWidget {
  final String title;
  final String amount;
  final String subtitle;
  final VoidCallback? onTap;
  final VComponentTone tone;
  final VComponentEmphasis emphasis;
  final String? semanticLabel;

  const RevenueCard({
    super.key,
    this.title = 'Doanh thu hôm nay',
    this.amount = '8.420.000 ₫',
    this.subtitle = 'Từ 12 đơn · +18% so với hôm qua',
    this.onTap,
    this.tone = VComponentTone.primary,
    this.emphasis = VComponentEmphasis.strong,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return Semantics(
      label: semanticLabel ?? title,
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VRadius.r16),
        child: Container(
          padding: const EdgeInsets.all(VSpacing.space4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(VRadius.r16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                dynamicColors.primary,
                dynamicColors.primaryPressed,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.trending_up,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: VSpacing.space2),
                      Text(
                        title,
                        style: VTypography.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: VSpacing.space2),
              Text(
                amount,
                style: VTypography.displayD1.copyWith(
                  color: Colors.white,
                  fontFamily: VTypography.monoFontFamily,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: VSpacing.space1),
              Text(
                subtitle,
                style: VTypography.caption.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
