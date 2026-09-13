import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vet45_design_system/design_system.dart';

/// D-08 SG-03 — Bottom sheet xác nhận lưu thay đổi khi sửa giá riêng.
///
/// Dùng [showVBottomSheet] + [VBottomSheet] (handle, viewInsets) và [VCard].
/// Tuân thủ chuẩn thiết kế vet45_design_system:
/// - Header tiêu đề "Lưu thay đổi?" + nút đóng (VIcons.close) + subtitle "Bạn có chắc muốn cập nhật giá riêng này?"
/// - Thẻ thông tin [VCard] hiển thị sự thay đổi của:
///   - Giá riêng: [oldPriceLabel] → [newPriceLabel] (nổi bật màu success)
///   - Đến ngày: [oldToLabel] → [newToLabel] (nổi bật màu success)
/// - Trường [VTextField] nhập lý do thay đổi với hint text + counter 0/200.
/// - Hàng nút bấm Hủy ([VButtonVariant.secondary]) và Lưu thay đổi ([VButtonVariant.primary]).
class PriceRuleSaveConfirmSheet extends StatefulWidget {
  const PriceRuleSaveConfirmSheet({
    super.key,
    required this.oldPriceLabel,
    required this.newPriceLabel,
    required this.oldFromLabel,
    required this.newFromLabel,
    required this.oldToLabel,
    required this.newToLabel,
    this.showOverwriteWarning = false,
    required this.onConfirm,
  });

  static const int maxReasonLength = 200;

  final String oldPriceLabel;
  final String newPriceLabel;
  final String oldFromLabel;
  final String newFromLabel;
  final String oldToLabel;
  final String newToLabel;
  final bool showOverwriteWarning;
  final ValueChanged<String?> onConfirm;

  static Future<({bool confirmed, String? changeReason})?> show({
    required BuildContext context,
    required String oldPriceLabel,
    required String newPriceLabel,
    required String oldFromLabel,
    required String newFromLabel,
    required String oldToLabel,
    required String newToLabel,
    bool showOverwriteWarning = false,
  }) async {
    final result = await showVBottomSheet<({bool confirmed, String? reason})>(
      context: context,
      semanticLabel: 'Xác nhận lưu thay đổi giá riêng',
      child: _PriceRuleSaveConfirmSheetHost(
        oldPriceLabel: oldPriceLabel,
        newPriceLabel: newPriceLabel,
        oldFromLabel: oldFromLabel,
        newFromLabel: newFromLabel,
        oldToLabel: oldToLabel,
        newToLabel: newToLabel,
        showOverwriteWarning: showOverwriteWarning,
      ),
    );
    if (result == null) {
      return (confirmed: false, changeReason: null);
    }
    return (confirmed: result.confirmed, changeReason: result.reason);
  }

  @override
  State<PriceRuleSaveConfirmSheet> createState() =>
      _PriceRuleSaveConfirmSheetState();
}

class _PriceRuleSaveConfirmSheetHost extends StatelessWidget {
  const _PriceRuleSaveConfirmSheetHost({
    required this.oldPriceLabel,
    required this.newPriceLabel,
    required this.oldFromLabel,
    required this.newFromLabel,
    required this.oldToLabel,
    required this.newToLabel,
    required this.showOverwriteWarning,
  });

  final String oldPriceLabel;
  final String newPriceLabel;
  final String oldFromLabel;
  final String newFromLabel;
  final String oldToLabel;
  final String newToLabel;
  final bool showOverwriteWarning;

  @override
  Widget build(BuildContext context) {
    return PriceRuleSaveConfirmSheet(
      oldPriceLabel: oldPriceLabel,
      newPriceLabel: newPriceLabel,
      oldFromLabel: oldFromLabel,
      newFromLabel: newFromLabel,
      oldToLabel: oldToLabel,
      newToLabel: newToLabel,
      showOverwriteWarning: showOverwriteWarning,
      onConfirm: (reason) =>
          Navigator.of(context).pop((confirmed: true, reason: reason)),
    );
  }
}

class _PriceRuleSaveConfirmSheetState extends State<PriceRuleSaveConfirmSheet> {
  final TextEditingController _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final reasonLength = _reasonController.text.length;

    final hasDateChange =
        (widget.oldFromLabel != widget.newFromLabel &&
            widget.oldFromLabel.isNotEmpty) ||
        (widget.oldToLabel != widget.newToLabel);
    final shouldShowWarning = widget.showOverwriteWarning || hasDateChange;

    return Material(
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: VText(
                      'Lưu thay đổi?',
                      variant: VTextVariant.headingH3,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                      color: colors.textPrimary,
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(
                      context,
                    ).pop((confirmed: false, reason: null)),
                    borderRadius: BorderRadius.circular(VRadius.r8),
                    child: Padding(
                      padding: const EdgeInsets.all(VSpacing.space1),
                      child: VIcon(
                        icon: VIcons.close,
                        size: 20,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const VGap.xs(),
              VText(
                'Bạn có chắc muốn cập nhật giá riêng này?',
                variant: VTextVariant.bodyDefault,
                color: colors.textSecondary,
              ),
              const VGap.md(),
              VCard(
                padding: const EdgeInsets.all(VSpacing.space4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ChangeRow(
                      label: 'Giá riêng:',
                      from: widget.oldPriceLabel,
                      to: widget.newPriceLabel,
                    ),
                    if (widget.oldFromLabel != widget.newFromLabel &&
                        widget.oldFromLabel.isNotEmpty) ...[
                      const VGap.sm(),
                      _ChangeRow(
                        label: 'Từ ngày:',
                        from: widget.oldFromLabel,
                        to: widget.newFromLabel,
                      ),
                    ],
                    const VGap.sm(),
                    _ChangeRow(
                      label: 'Đến ngày:',
                      from: widget.oldToLabel,
                      to: widget.newToLabel,
                    ),
                  ],
                ),
              ),
              if (shouldShowWarning) ...[
                const VGap.md(),
                const VBanner(
                  tone: VComponentTone.info,
                  title: 'Lưu ý tự động ghi đè',
                  description:
                      'Cập nhật thời gian hiệu lực này sẽ tự động ghi đè giá riêng đang áp dụng trùng khoảng thời gian (nếu có).',
                ),
              ],
              const VGap.md(),
              VTextFormField(
                label: 'Lý do thay đổi (không bắt buộc)',
                hintText: 'Nhập lý do thay đổi...',
                controller: _reasonController,
                minLines: 3,
                maxLines: 4,
                onChanged: (_) => setState(() {}),
                inputFormatters: [
                  LengthLimitingTextInputFormatter(
                    PriceRuleSaveConfirmSheet.maxReasonLength,
                  ),
                ],
              ),
              const VGap.xs(),
              Align(
                alignment: Alignment.centerRight,
                child: VText(
                  '$reasonLength/${PriceRuleSaveConfirmSheet.maxReasonLength}',
                  variant: VTextVariant.caption,
                  color: colors.textMuted,
                ),
              ),
              const VGap.lg(),
              Row(
                children: [
                  Expanded(
                    child: VButton(
                      label: 'Hủy',
                      variant: VButtonVariant.secondary,
                      fullWidth: true,
                      onPressed: () => Navigator.of(
                        context,
                      ).pop((confirmed: false, reason: null)),
                    ),
                  ),
                  const VGap.horizontalMd(),
                  Expanded(
                    child: VButton(
                      label: 'Lưu thay đổi',
                      variant: VButtonVariant.primary,
                      fullWidth: true,
                      onPressed: () {
                        final reason = _reasonController.text.trim();
                        widget.onConfirm(reason.isEmpty ? null : reason);
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

class _ChangeRow extends StatelessWidget {
  const _ChangeRow({required this.label, required this.from, required this.to});

  final String label;
  final String from;
  final String to;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        VText(
          label,
          variant: VTextVariant.bodyDefault,
          color: colors.textSecondary,
        ),
        const VGap.horizontalSm(),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: VText(
                  from,
                  variant: VTextVariant.bodyDefault,
                  color: colors.textPrimary,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: VSpacing.space2,
                ),
                child: VText(
                  '→',
                  variant: VTextVariant.bodyDefault,
                  color: colors.success,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Flexible(
                child: VText(
                  to,
                  variant: VTextVariant.bodyDefault,
                  color: colors.success,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
