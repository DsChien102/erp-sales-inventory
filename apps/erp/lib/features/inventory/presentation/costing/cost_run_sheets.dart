import 'package:erp/features/inventory/data/costing/costing_models.dart';
import 'package:erp/features/inventory/logic/costing/costing_rules.dart';
import 'package:erp/features/inventory/presentation/costing/cost_run_blocks.dart';
import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

/// Sheet xác nhận công bố giá vốn (SCR-074).
Future<bool> showCostPublishSheet(
  BuildContext context, {
  required CostRunView run,
  required Future<bool> Function() onConfirm,
}) async {
  final result = await showVAdaptiveSheet<bool>(
    context: context,
    title: 'Công bố giá vốn?',
    child: _CostPublishSheetBody(run: run, onConfirm: onConfirm),
  );
  return result == true;
}

class _CostPublishSheetBody extends StatefulWidget {
  const _CostPublishSheetBody({
    required this.run,
    required this.onConfirm,
  });

  final CostRunView run;
  final Future<bool> Function() onConfirm;

  @override
  State<_CostPublishSheetBody> createState() => _CostPublishSheetBodyState();
}

class _CostPublishSheetBodyState extends State<_CostPublishSheetBody> {
  bool _submitting = false;

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final ok = await widget.onConfirm();
    if (!mounted) return;
    Navigator.of(context).pop(ok);
  }

  @override
  Widget build(BuildContext context) {
    final run = widget.run;
    return Padding(
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VText(
            'Kết quả đã rà soát sẽ có hiệu lực. Hệ thống chỉ ghi phần chênh lệch, không sửa chứng từ lịch sử.',
            variant: VTextVariant.bodyDefault,
            color: context.vColors.textSecondary,
          ),
          const SizedBox(height: VSpacing.space3),
          VKeyValueGroup(
            rows: [
              VKeyValueRow(
                label: 'Kỳ ghi nhận',
                value: periodLabel(run.periodMonth),
                mono: true,
              ),
              const VKeyValueRow(
                label: 'Phạm vi',
                value: 'Toàn bộ sản phẩm',
              ),
              VKeyValueRow(
                label: 'Phương pháp',
                value: methodCopy(run.method).$1,
              ),
              VKeyValueRow(
                label: 'Điều chỉnh giá vốn xuất',
                value: signedMoney(run.totals.cogsAdjust),
                mono: true,
              ),
              VKeyValueRow(
                label: 'Điều chỉnh giá trị tồn',
                value: signedMoney(run.totals.valueAdjust),
                mono: true,
              ),
            ],
          ),
          const SizedBox(height: VSpacing.space4),
          Row(
            children: [
              Expanded(
                child: VButton(
                  label: 'Quay lại',
                  variant: VButtonVariant.secondary,
                  fullWidth: true,
                  onPressed: _submitting
                      ? null
                      : () => Navigator.of(context).pop(false),
                ),
              ),
              const SizedBox(width: VSpacing.space2),
              Expanded(
                child: VButton(
                  label: 'Công bố giá vốn',
                  variant: VButtonVariant.primary,
                  fullWidth: true,
                  isLoading: _submitting,
                  onPressed: _submitting ? null : _submit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Sheet đối chiếu theo phương pháp còn lại.
Future<void> showCostCompareSheet(
  BuildContext context, {
  required CostAlt alt,
}) {
  final (label, _) = methodCopy(alt.method);
  return showVAdaptiveSheet<void>(
    context: context,
    title: 'Đối chiếu theo $label',
    child: Padding(
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VText(
            'Chỉ để đối chiếu; không dùng để công bố.',
            variant: VTextVariant.bodySmall,
            color: context.vColors.textSecondary,
          ),
          const SizedBox(height: VSpacing.space3),
          VKeyValueGroup(
            rows: [
              VKeyValueRow(
                label: 'Giá trị tồn cuối',
                value: moneyWithSpace(alt.closingValue),
                mono: true,
              ),
              VKeyValueRow(
                label: 'Giá vốn xuất',
                value: moneyWithSpace(alt.cogsValue),
                mono: true,
              ),
            ],
          ),
          const SizedBox(height: VSpacing.space4),
          VButton(
            label: 'Đóng',
            variant: VButtonVariant.secondary,
            fullWidth: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    ),
  );
}

/// Sheet danh sách toàn bộ sản phẩm (mobile).
Future<void> showCostProductsSheet(
  BuildContext context, {
  required List<CostRunLineView> lines,
}) {
  return showVAdaptiveSheet<void>(
    context: context,
    title: 'Theo sản phẩm',
    child: Padding(
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: lines.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                thickness: 1,
                color: context.vColors.borderDefault,
              ),
              itemBuilder: (_, i) => CostProductMobileRow(line: lines[i]),
            ),
          ),
          const SizedBox(height: VSpacing.space4),
          VButton(
            label: 'Đóng',
            variant: VButtonVariant.secondary,
            fullWidth: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    ),
  );
}
