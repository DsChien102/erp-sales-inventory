import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vet45_design_system/design_system.dart';

/// Returns `null` if cancelled; otherwise the optional reason (may be empty).
Future<String?> showPartnerDeactivateConfirmationSheet(BuildContext context) {
  return showVBottomSheet<String>(
    context: context,
    child: const PartnerDeactivateConfirmationSheet(),
  );
}

/// Confirmation sheet for deactivate (S7) — UI theo SG-07.
class PartnerDeactivateConfirmationSheet extends StatefulWidget {
  const PartnerDeactivateConfirmationSheet({super.key});

  static const maxReasonLength = 200;

  @override
  State<PartnerDeactivateConfirmationSheet> createState() =>
      _PartnerDeactivateConfirmationSheetState();
}

class _PartnerDeactivateConfirmationSheetState
    extends State<PartnerDeactivateConfirmationSheet> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final reasonLength = _reasonController.text.characters.length;

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          key: const Key('wgt_e02_u01_fr05_01'),
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
                  iconData: Icons.pause_rounded,
                  size: 64,
                  iconSize: 32,
                  isCircular: true,
                  backgroundColor: VColors.warning.withValues(alpha: 0.15),
                  iconColor: VColors.warning,
                ),
              ),
              const SizedBox(height: VSpacing.space4),
              Text(
                'Ngừng hoạt động KH & NCC?',
                textAlign: TextAlign.center,
                style: VTypography.headingH3.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: VSpacing.space3),
              Text(
                'KH & NCC này sẽ không còn được chọn cho giao dịch mới.\n'
                'Hồ sơ và lịch sử vẫn được giữ lại.',
                textAlign: TextAlign.center,
                style: VTypography.bodyDefault.copyWith(
                  color: colors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: VSpacing.space5),
              Text(
                'Lý do (không bắt buộc)',
                style: VTypography.bodySmall.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: VSpacing.space2),
              VTextField(
                key: const Key('deactivate_reason_input'),
                controller: _reasonController,
                hintText: 'Nhập lý do (nếu có)',
                minLines: 3,
                maxLines: 4,
                onChanged: (_) => setState(() {}),
                inputFormatters: [
                  LengthLimitingTextInputFormatter(
                    PartnerDeactivateConfirmationSheet.maxReasonLength,
                  ),
                ],
              ),
              const SizedBox(height: VSpacing.space1),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '$reasonLength/${PartnerDeactivateConfirmationSheet.maxReasonLength}',
                  style: VTypography.caption.copyWith(
                    color: colors.textMuted,
                  ),
                ),
              ),
              const SizedBox(height: VSpacing.space5),
              Row(
                children: [
                  Expanded(
                    child: VButton(
                      key: const Key('deactivate_cancel'),
                      label: 'Hủy',
                      variant: VButtonVariant.outline,
                      foregroundColor: colors.success,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: VSpacing.space3),
                  Expanded(
                    child: VButton(
                      key: const Key('deactivate_confirm'),
                      label: 'Ngừng hoạt động',
                      onPressed: () {
                        Navigator.of(context).pop(
                          _reasonController.text.trim(),
                        );
                      },
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
