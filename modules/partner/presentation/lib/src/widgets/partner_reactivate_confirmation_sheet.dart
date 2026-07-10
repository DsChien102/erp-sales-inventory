import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Returns `true` if confirmed; `null` if cancelled.
Future<bool?> showPartnerReactivateConfirmationSheet(BuildContext context) {
  return showVBottomSheet<bool>(
    context: context,
    child: const PartnerReactivateConfirmationSheet(),
  );
}

/// Confirmation sheet for reactivate (S7) — UI theo mockup SG-07.
class PartnerReactivateConfirmationSheet extends StatelessWidget {
  const PartnerReactivateConfirmationSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Padding(
          key: const Key('wgt_e02_u01_fr03_01'),
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
              Align(
                child: VIconBox(
                  iconData: Icons.power_settings_new_rounded,
                  size: 64,
                  iconSize: 32,
                  isCircular: true,
                  backgroundColor: colors.success.withValues(alpha: 0.12),
                  iconColor: colors.success,
                ),
              ),
              const SizedBox(height: VSpacing.space4),
              Text(
                'Kích hoạt lại KH & NCC?',
                textAlign: TextAlign.center,
                style: VTypography.headingH3.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: VSpacing.space3),
              Text(
                'KH & NCC này sẽ có thể được chọn lại cho giao dịch mới.',
                textAlign: TextAlign.center,
                style: VTypography.bodyDefault.copyWith(
                  color: colors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: VSpacing.space5),
              Row(
                children: [
                  Expanded(
                    child: VButton(
                      key: const Key('reactivate_cancel'),
                      label: 'Hủy',
                      variant: VButtonVariant.outline,
                      foregroundColor: colors.success,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: VSpacing.space3),
                  Expanded(
                    child: VButton(
                      key: const Key('reactivate_confirm'),
                      label: 'Kích hoạt lại',
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
