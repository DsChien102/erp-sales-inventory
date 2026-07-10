import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Result of D-09 blocked-delete sheet.
enum PartnerDeleteBlockedResult {
  /// User dismissed / Quay lại / close.
  dismissed,

  /// User chose «Ngừng hoạt động».
  deactivate,
}

/// Shows D-09 when soft-delete is blocked by transactions.
///
/// [showDeactivateAction] false when partner is already inactive (chỉ Quay lại).
Future<PartnerDeleteBlockedResult> showPartnerDeleteBlockedSheet(
  BuildContext context, {
  bool showDeactivateAction = true,
}) async {
  final result = await showVBottomSheet<PartnerDeleteBlockedResult>(
    context: context,
    child: PartnerDeleteBlockedSheet(
      showDeactivateAction: showDeactivateAction,
    ),
  );
  return result ?? PartnerDeleteBlockedResult.dismissed;
}

/// Bottom sheet D-09 — không thể xóa vì đã phát sinh giao dịch.
class PartnerDeleteBlockedSheet extends StatelessWidget {
  const PartnerDeleteBlockedSheet({
    super.key,
    this.showDeactivateAction = true,
  });

  final bool showDeactivateAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Padding(
          key: const Key('wgt_e02_u02_fr04_01'),
          padding: const EdgeInsets.fromLTRB(
            VSpacing.space4,
            VSpacing.space1,
            VSpacing.space4,
            VSpacing.space4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  key: const Key('delete_blocked_close'),
                  onPressed: () => Navigator.of(context).pop(
                    PartnerDeleteBlockedResult.dismissed,
                  ),
                  icon: Icon(Icons.close_rounded, color: colors.textMuted),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ),
              Align(
                child: Icon(
                  Icons.warning_amber_rounded,
                  size: 56,
                  color: colors.warning,
                ),
              ),
              const SizedBox(height: VSpacing.space4),
              Text(
                'Không thể xóa hồ sơ',
                textAlign: TextAlign.center,
                style: VTypography.headingH3.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: VSpacing.space3),
              Text(
                'KH & NCC đã phát sinh giao dịch hoặc chứng từ liên quan nên không thể xóa.',
                textAlign: TextAlign.center,
                style: VTypography.bodyDefault.copyWith(
                  color: colors.textSecondary,
                  height: 1.4,
                ),
              ),
              if (showDeactivateAction) ...[
                const SizedBox(height: VSpacing.space2),
                Text(
                  'Bạn có thể ngừng hoạt động để tránh sử dụng trong giao dịch mới.',
                  textAlign: TextAlign.center,
                  style: VTypography.bodyDefault.copyWith(
                    color: colors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: VSpacing.space5),
              if (showDeactivateAction)
                Row(
                  children: [
                    Expanded(
                      child: VButton(
                        key: const Key('delete_blocked_back'),
                        label: 'Quay lại',
                        variant: VButtonVariant.outline,
                        foregroundColor: colors.success,
                        onPressed: () => Navigator.of(context).pop(
                          PartnerDeleteBlockedResult.dismissed,
                        ),
                      ),
                    ),
                    const SizedBox(width: VSpacing.space3),
                    Expanded(
                      child: VButton(
                        key: const Key('delete_blocked_deactivate'),
                        label: 'Ngừng hoạt động',
                        onPressed: () => Navigator.of(context).pop(
                          PartnerDeleteBlockedResult.deactivate,
                        ),
                      ),
                    ),
                  ],
                )
              else
                VButton(
                  key: const Key('delete_blocked_back'),
                  label: 'Quay lại',
                  variant: VButtonVariant.outline,
                  foregroundColor: colors.success,
                  onPressed: () => Navigator.of(context).pop(
                    PartnerDeleteBlockedResult.dismissed,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
