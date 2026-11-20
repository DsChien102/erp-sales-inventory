import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';
import '../models/sales_order/sales_order_detail_vm.dart';
import 'package:erp/core/formatting/money_formatter.dart';
/// SG-10 — VBottomSheet Hủy đơn hàng (EP-05/US-01..05 & Figma Spec O-01).
Future<bool?> showSalesOrderCancelSheet(
  BuildContext context, {
  required SalesOrderDetailVm vm,
  Future<bool> Function(String reason, String note)? onConfirmCancel,
}) {
  return showVBottomSheet<bool>(
    context: context,
    semanticLabel: 'Hủy đơn hàng',
    child: SalesOrderCancelSheet(
      vm: vm,
      onConfirmCancel: onConfirmCancel,
    ),
  );
}

class SalesOrderCancelSheet extends StatefulWidget {
  const SalesOrderCancelSheet({
    super.key,
    required this.vm,
    this.onConfirmCancel,
  });

  final SalesOrderDetailVm vm;
  final Future<bool> Function(String reason, String note)? onConfirmCancel;

  @override
  State<SalesOrderCancelSheet> createState() => _SalesOrderCancelSheetState();
}

class _SalesOrderCancelSheetState extends State<SalesOrderCancelSheet> {
  late final TextEditingController _reasonCtrl;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _reasonCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    setState(() => _isSubmitting = true);
    bool ok = true;
    if (widget.onConfirmCancel != null) {
      ok = await widget.onConfirmCancel!('Khách hủy', _reasonCtrl.text);
    }
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (ok) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final totalItems = widget.vm.items.fold<int>(0, (sum, item) => sum + item.quantity);
    final itemCountText =
        'Hoàn lại ${totalItems > 0 ? totalItems : widget.vm.items.length} mặt hàng';
    final formattedAmount = 'Giảm ${MoneyFormatter.formatMinor(widget.vm.totalAmountMinor)}';
    final formattedOrderNumber = widget.vm.orderNumber.replaceAll('#', '');

    return Padding(
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
            'Hủy đơn hàng?',
            variant: VTextVariant.headingH3,
            color: colors.danger,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const VGap.xs(),
          VText(
            'Đơn $formattedOrderNumber sẽ chuyển sang Đã hủy và không thể mở lại.',
            variant: VTextVariant.bodyDefault,
            color: colors.textSecondary,
          ),
          const VGap.md(),
          VField(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const VFieldLabel('Lý do hủy', isRequired: false),
                VTextField(
                  key: const Key('input_cancel_reason'),
                  controller: _reasonCtrl,
                  hintText: 'Nhập lý do nếu cần',
                ),
                const VFieldDescription('Không bắt buộc'),
              ],
            ),
          ),
          const VGap.md(),
          VCard(
            backgroundColor: colors.surfaceAlt,
            padding: const EdgeInsets.all(VSpacing.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const VText(
                  'Điều chỉnh dự kiến',
                  variant: VTextVariant.bodyDefault,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const VGap.sm(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    VText(
                      'Tồn kho',
                      variant: VTextVariant.bodyDefault,
                      color: colors.textSecondary,
                    ),
                    VText(
                      itemCountText,
                      variant: VTextVariant.bodyDefault,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const VGap.sm(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    VText(
                      'Công nợ',
                      variant: VTextVariant.bodyDefault,
                      color: colors.textSecondary,
                    ),
                    VText(
                      formattedAmount,
                      variant: VTextVariant.bodyDefault,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const VGap.lg(),
          VButton(
            key: const Key('btn_cancel_sheet_back'),
            label: 'Quay lại',
            variant: VButtonVariant.secondary,
            size: VButtonSize.large,
            fullWidth: true,
            onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
          ),
          const VGap.sm(),
          VButton(
            key: const Key('btn_cancel_sheet_confirm'),
            label: _isSubmitting ? 'Đang hủy...' : 'Hủy đơn hàng',
            variant: VButtonVariant.secondary,
            tone: VComponentTone.danger,
            size: VButtonSize.large,
            fullWidth: true,
            onPressed: _isSubmitting ? null : _handleConfirm,
          ),
        ],
      ),
    );
  }
}
