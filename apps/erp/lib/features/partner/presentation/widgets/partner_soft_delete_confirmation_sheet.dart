import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vet45_design_system/design_system.dart';

/// Returns `null` if cancelled; otherwise the optional reason (may be empty).
Future<String?> showPartnerSoftDeleteConfirmationSheet(BuildContext context) {
  return showVBottomSheet<String>(
    context: context,
    child: const PartnerSoftDeleteConfirmationSheet(),
  );
}

/// Confirmation sheet for soft delete (S8 / D-07).
class PartnerSoftDeleteConfirmationSheet extends StatefulWidget {
  const PartnerSoftDeleteConfirmationSheet({super.key});

  static const maxReasonLength = 200;

  @override
  State<PartnerSoftDeleteConfirmationSheet> createState() =>
      _PartnerSoftDeleteConfirmationSheetState();
}

class _PartnerSoftDeleteConfirmationSheetState extends State<PartnerSoftDeleteConfirmationSheet> {
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
          key: const Key('wgt_e02_u02_fr05_01'),
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
                  key: const Key('soft_delete_close'),
                  onPressed: () => Navigator.of(context).pop(),
                  icon: VIcon(
                    icon: VIcons.close,
                    color: colors.textMuted,
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ),
              Align(
                child: VIconBox(
                  icon: VIcons.delete,
                  size: 64,
                  iconSize: 32,
                  isCircular: true,
                  backgroundColor: colors.danger.withValues(alpha: 0.12),
                  iconColor: colors.danger,
                ),
              ),
              const SizedBox(height: VSpacing.space4),
              VText(
                'Xóa hồ sơ KH & NCC?',
                textAlign: TextAlign.center,
                variant: VTextVariant.headingH3,
                color: colors.textPrimary,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: VSpacing.space3),
              VText(
                'Hồ sơ sẽ bị xóa khỏi danh sách làm việc và không còn được chọn cho giao dịch mới.',
                textAlign: TextAlign.center,
                style: VTypography.bodyDefault.copyWith(
                  color: colors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: VSpacing.space2),
              VText(
                'Thao tác này không xóa giao dịch hoặc chứng từ đã phát sinh.',
                textAlign: TextAlign.center,
                style: VTypography.bodyDefault.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: VSpacing.space5),
              VText(
                'Lý do (không bắt buộc)',
                variant: VTextVariant.bodySmall,
                color: colors.textPrimary,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: VSpacing.space2),
              VTextArea(
                key: const Key('soft_delete_reason_input'),
                controller: _reasonController,
                hintText: 'Nhập lý do (nếu có)',
                minLines: 3,
                maxLines: 4,
                onChanged: (_) => setState(() {}),
                inputFormatters: [
                  LengthLimitingTextInputFormatter(
                    PartnerSoftDeleteConfirmationSheet.maxReasonLength,
                  ),
                ],
              ),
              const SizedBox(height: VSpacing.space1),
              Align(
                alignment: Alignment.centerRight,
                child: VText(
                  '$reasonLength/${PartnerSoftDeleteConfirmationSheet.maxReasonLength}',
                  variant: VTextVariant.caption,
                  color: colors.textMuted,
                ),
              ),
              const SizedBox(height: VSpacing.space5),
              Row(
                children: [
                  Expanded(
                    child: VButton(
                      key: const Key('soft_delete_cancel'),
                      label: 'Hủy',
                      variant: VButtonVariant.secondary,
                      foregroundColor: colors.textPrimary,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: VSpacing.space3),
                  Expanded(
                    child: VButton(
                      key: const Key('soft_delete_confirm'),
                      label: 'Xóa hồ sơ',
                      variant: VButtonVariant.primary,
                      tone: VComponentTone.danger,
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
