import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class ReceiptRejectReasonSheet extends StatefulWidget {
  const ReceiptRejectReasonSheet({super.key});

  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ReceiptRejectReasonSheet(),
    );
  }

  @override
  State<ReceiptRejectReasonSheet> createState() =>
      _ReceiptRejectReasonSheetState();
}

class _ReceiptRejectReasonSheetState extends State<ReceiptRejectReasonSheet> {
  final TextEditingController _controller = TextEditingController();
  bool _canSubmit = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final isValid = _controller.text.trim().isNotEmpty;
      if (isValid != _canSubmit) {
        setState(() {
          _canSubmit = isValid;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: VBottomSheet(
        title: 'Từ chối yêu cầu',
        tone: VComponentTone.danger,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: VSpacing.space4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              VText(
                'Vui lòng nhập lý do từ chối để nhân viên kho nắm được thông tin:',
                style: VTypography.bodySmall.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const VGap(VSpacing.space3),
              VTextArea(
                controller: _controller,
                hintText: 'Ví dụ: Hàng giao sai quy cách, bao bì rách vỡ...',
                minLines: 3,
                maxLines: 5,
                autofocus: true,
              ),
              const VGap(VSpacing.space4),
              Row(
                children: [
                  Expanded(
                    child: VButton(
                      label: 'Huỷ',
                      variant: VButtonVariant.secondary,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const VGap(VSpacing.space3, axis: Axis.horizontal),
                  Expanded(
                    child: VButton(
                      label: 'Từ chối',
                      tone: VComponentTone.danger,
                      enabled: _canSubmit,
                      onPressed: _canSubmit
                          ? () => Navigator.of(context).pop(_controller.text.trim())
                          : null,
                    ),
                  ),
                ],
              ),
              const VGap(VSpacing.space4),
            ],
          ),
        ),
      ),
    );
  }
}
