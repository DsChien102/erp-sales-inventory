import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Sheet xác nhận hành động (và nhập lý do nếu [withReason] bật) dùng chung cho SCR-043 / 044 / 045.
/// Trả chuỗi lý do (hoặc `''` khi [withReason] tắt) nếu người dùng xác nhận; trả `null` nếu quay lại.
Future<String?> showStocktakeConfirmSheet(
  BuildContext context, {
  required String title,
  required String description,
  required String confirmLabel,
  String cancelLabel = 'Quay lại',
  bool withReason = false,
  String reasonLabel = 'Lý do',
  String? reasonHint,
  bool danger = false,
}) {
  return showVAdaptiveSheet<String>(
    context: context,
    title: title,
    child: _StocktakeConfirmSheetBody(
      description: description,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      withReason: withReason,
      reasonLabel: reasonLabel,
      reasonHint: reasonHint,
      danger: danger,
    ),
  );
}

class _StocktakeConfirmSheetBody extends StatefulWidget {
  const _StocktakeConfirmSheetBody({
    required this.description,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.withReason,
    required this.reasonLabel,
    this.reasonHint,
    required this.danger,
  });

  final String description;
  final String confirmLabel;
  final String cancelLabel;
  final bool withReason;
  final String reasonLabel;
  final String? reasonHint;
  final bool danger;

  @override
  State<_StocktakeConfirmSheetBody> createState() =>
      _StocktakeConfirmSheetBodyState();
}

class _StocktakeConfirmSheetBodyState
    extends State<_StocktakeConfirmSheetBody> {
  final TextEditingController _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final trimmedReason = _reasonController.text.trim();
    final canConfirm = !widget.withReason || trimmedReason.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VText(
            widget.description,
            variant: VTextVariant.bodyDefault,
            color: colors.textSecondary,
          ),
          if (widget.withReason) ...[
            const SizedBox(height: VSpacing.space3),
            VField(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  VFieldLabel(widget.reasonLabel, isRequired: true),
                  const SizedBox(height: VSpacing.space2),
                  VTextField(
                    controller: _reasonController,
                    hintText: widget.reasonHint,
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: VSpacing.space4),
          Row(
            children: [
              Expanded(
                child: VButton(
                  label: widget.cancelLabel,
                  variant: VButtonVariant.secondary,
                  fullWidth: true,
                  onPressed: () => Navigator.of(context).pop(null),
                ),
              ),
              const SizedBox(width: VSpacing.space2),
              Expanded(
                child: VButton(
                  label: widget.confirmLabel,
                  variant: VButtonVariant.primary,
                  tone: widget.danger ? VComponentTone.danger : null,
                  fullWidth: true,
                  onPressed: canConfirm
                      ? () => Navigator.of(context).pop(
                          widget.withReason ? trimmedReason : '',
                        )
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
