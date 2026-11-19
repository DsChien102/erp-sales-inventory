import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

Future<bool?> showPartnerContactRemoveDialog(BuildContext context) {
  return showVAdaptiveSheet<bool>(
    context: context,
    child: const PartnerContactRemoveDialog(),
  );
}

class PartnerContactRemoveDialog extends StatelessWidget {
  const PartnerContactRemoveDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Material(
      color: colors.surface.withValues(alpha: 0),
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
              VText(
                'Gỡ người liên hệ?',
                variant: VTextVariant.headingH3,
                color: colors.textPrimary,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: VSpacing.space3),
              VText(
                'Người này sẽ được gỡ khỏi danh sách liên hệ của tổ chức. Hồ sơ cá nhân không bị xóa khỏi hệ thống.',
                variant: VTextVariant.bodyDefault,
                color: colors.textSecondary,
                textAlign: TextAlign.center,
              ),
              const VGap.md(),
              Row(
                children: [
                  Expanded(
                    child: VButton(
                      label: 'Quay lại',
                      variant: VButtonVariant.secondary,
                      foregroundColor: colors.success,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const VGap.horizontalSm(),
                  Expanded(
                    child: VButton(
                      label: 'Gỡ liên hệ',
                      variant: VButtonVariant.primary,
                      tone: VComponentTone.danger,
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
