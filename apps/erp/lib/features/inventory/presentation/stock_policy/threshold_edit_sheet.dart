import 'package:erp/features/inventory/data/stock_policy/stock_policy_models.dart';
import 'package:erp/features/inventory/logic/stock/stock_indicator_rules.dart';
import 'package:erp/features/inventory/logic/stock_policy/stock_policy_cubit.dart';
import 'package:erp/features/inventory/logic/stock_policy/stock_policy_rules.dart';
import 'package:erp/features/inventory/presentation/patterns/k7_edit_cell.dart';
import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class ThresholdEditSheet extends StatefulWidget {
  final StockPolicyProduct product;
  final StockPolicyCubit cubit;

  const ThresholdEditSheet({
    super.key,
    required this.product,
    required this.cubit,
  });

  static Future<void> show(
    BuildContext context,
    StockPolicyProduct product,
    StockPolicyCubit cubit,
  ) {
    return showVAdaptiveSheet(
      context: context,
      title: product.name,
      child: ThresholdEditSheet(product: product, cubit: cubit),
    );
  }

  @override
  State<ThresholdEditSheet> createState() => _ThresholdEditSheetState();
}

class _ThresholdEditSheetState extends State<ThresholdEditSheet> {
  late String _threshold;
  late String _target;

  @override
  void initState() {
    super.initState();
    final draft = widget.cubit.state.shownThreshold(widget.product);
    _threshold = draft.threshold;
    _target = draft.target;
  }

  String _previewText() {
    final t = num.tryParse(_threshold.trim());
    final g = num.tryParse(_target.trim());
    if (t == null || g == null) return '';

    final inds = stockIndicators(
      available: widget.product.available,
      threshold: t,
      hasExpired: widget.product.hasExpired,
      hasNearExpiry: widget.product.hasNearExpiry,
    );

    const checkOrder = [
      StockIndicator.out,
      StockIndicator.expired,
      StockIndicator.low,
      StockIndicator.nearExpiry,
    ];

    for (final ind in checkOrder) {
      if (inds.contains(ind)) {
        return ind.label;
      }
    }
    return 'Không có cảnh báo';
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final err = thresholdRowError(_threshold, _target, configured: p.configured);
    final isBlocked = singleBlocked(_threshold, _target, configured: p.configured);
    final preview = (!isBlocked && err == null) ? _previewText() : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Khả dụng ${p.available} ${p.uom}',
          style: const TextStyle(
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF0E1116),
          ),
        ),
        const SizedBox(height: VSpacing.space3),
        const Text(
          'Ngưỡng cảnh báo',
          style: TextStyle(
            fontSize: 13,
            height: 18 / 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0E1116),
          ),
        ),
        const SizedBox(height: VSpacing.space1),
        K7EditCell(
          value: _threshold,
          unit: p.uom,
          semanticLabel: 'Ngưỡng cảnh báo — ${p.name}',
          onChanged: (val) => setState(() => _threshold = val),
        ),
        const SizedBox(height: VSpacing.space3),
        const Text(
          'Mức tồn mục tiêu',
          style: TextStyle(
            fontSize: 13,
            height: 18 / 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0E1116),
          ),
        ),
        const SizedBox(height: VSpacing.space1),
        K7EditCell(
          value: _target,
          unit: p.uom,
          errorText: err,
          semanticLabel: 'Mức tồn mục tiêu — ${p.name}',
          onChanged: (val) => setState(() => _target = val),
        ),
        if (preview.isNotEmpty) ...[
          const SizedBox(height: VSpacing.space3),
          Text(
            'Sau khi lưu: $preview',
            style: const TextStyle(
              fontSize: 14,
              height: 20 / 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF0E1116),
            ),
          ),
        ],
        const SizedBox(height: VSpacing.space4),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            VButton(
              label: 'Huỷ',
              variant: VButtonVariant.secondary,
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: VSpacing.space3),
            VButton(
              label: 'Lưu',
              variant: VButtonVariant.primary,
              onPressed: isBlocked
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      widget.cubit.saveSingle(p.productId, _threshold, _target);
                    },
            ),
          ],
        ),
      ],
    );
  }
}

