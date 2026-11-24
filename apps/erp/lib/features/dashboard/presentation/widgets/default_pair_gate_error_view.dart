import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

class DefaultPairGateErrorView extends StatelessWidget {
  const DefaultPairGateErrorView({
    super.key,
    required this.onRetry,
    required this.onChooseOrganization,
  });

  final VoidCallback onRetry;
  final VoidCallback onChooseOrganization;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Container(
      alignment: Alignment.topCenter,
      padding: const EdgeInsets.only(top: VSpacing.space3),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: VSpacing.screenMobile),
        child: SizedBox(
          width: double.infinity,
          child: VCard(
            padding: const EdgeInsets.all(VSpacing.space6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: colors.dangerBg,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: VIcon(
                      icon: VIcons.error,
                      color: colors.danger,
                      size: 28,
                    ),
                  ),
                ),
                const VGap.md(),
                VText(
                  'Không thiết lập được kho mặc định',
                  variant: VTextVariant.headingH3,
                  color: colors.danger,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const VGap.xs(),
                VText(
                  'Cửa hàng và kho mặc định chưa sẵn sàng. Thử lại hoặc chọn tổ chức khác.',
                  variant: VTextVariant.bodyDefault,
                  color: colors.textSecondary,
                  textAlign: TextAlign.center,
                ),
                const VGap.md(),
                GestureDetector(
                  onTap: onRetry,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: VText(
                      'Thử lại',
                      variant: VTextVariant.bodyDefault,
                      color: colors.primary,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const VGap.sm(),
                GestureDetector(
                  onTap: onChooseOrganization,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: VText(
                      'Chọn tổ chức khác',
                      variant: VTextVariant.bodyDefault,
                      color: colors.primary,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
