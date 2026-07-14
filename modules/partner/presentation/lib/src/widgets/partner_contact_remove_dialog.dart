import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class PartnerContactRemoveDialog extends StatelessWidget {
  const PartnerContactRemoveDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return VBottomSheet(
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              VSpacing.space4,
              VSpacing.space2,
              VSpacing.space4,
              VSpacing.space4,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Gỡ người liên hệ?',
                  textAlign: TextAlign.center,
                  style: VTypography.headingH3.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: VSpacing.space3),
                Text(
                  'Người này sẽ được gỡ khỏi danh sách liên hệ của tổ chức. Hồ sơ cá nhân không bị xóa khỏi hệ thống.',
                  textAlign: TextAlign.center,
                  style: VTypography.bodyDefault.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: VSpacing.space5),
                Row(
                  children: [
                    Expanded(
                      child: VButton(
                        label: 'Quay lại',
                        variant: VButtonVariant.outline,
                        foregroundColor: colors.success,
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                    ),
                    const SizedBox(width: VSpacing.space3),
                    Expanded(
                      child: VButton(
                        label: 'Gỡ liên hệ',
                        variant: VButtonVariant.danger,
                        onPressed: () => Navigator.of(context).pop(true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
