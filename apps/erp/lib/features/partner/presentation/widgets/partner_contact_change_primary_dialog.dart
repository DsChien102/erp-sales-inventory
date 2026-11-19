import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

Future<bool?> showPartnerContactChangePrimaryDialog(
  BuildContext context, {
  required String currentPrimaryName,
  required String newPrimaryName,
}) {
  return showVAdaptiveSheet<bool>(
    context: context,
    child: PartnerContactChangePrimaryDialog(
      currentPrimaryName: currentPrimaryName,
      newPrimaryName: newPrimaryName,
    ),
  );
}

class PartnerContactChangePrimaryDialog extends StatelessWidget {
  const PartnerContactChangePrimaryDialog({
    super.key,
    required this.currentPrimaryName,
    required this.newPrimaryName,
  });

  final String currentPrimaryName;
  final String newPrimaryName;

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
                VText(
                  'Đổi người liên hệ chính?',
                  textAlign: TextAlign.center,
                  variant: VTextVariant.headingH3,
                  color: colors.textPrimary,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: VSpacing.space3),
                VText(
                  '$currentPrimaryName hiện đang là người liên hệ chính. Nếu tiếp tục, $newPrimaryName sẽ trở thành người liên hệ chính mới.',
                  textAlign: TextAlign.center,
                  color: colors.textSecondary,
                ),
                const SizedBox(height: VSpacing.space4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    VAvatar(name: currentPrimaryName, size: 48, textSize: 16),
                    const SizedBox(width: VSpacing.space4),
                    VIcon(
                      icon: VIcons.arrowForward,
                      color: colors.textMuted,
                      size: 24,
                    ),
                    const SizedBox(width: VSpacing.space4),
                    VAvatar(name: newPrimaryName, size: 48, textSize: 16),
                  ],
                ),
                const SizedBox(height: VSpacing.space5),
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
                    const SizedBox(width: VSpacing.space3),
                    Expanded(
                      child: VButton(
                        label: 'Xác nhận đổi',
                        variant: VButtonVariant.primary,
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
