import 'package:erp/features/inventory/logic/supplier_program/program_form_draft.dart';
import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class ProgramTierRows extends StatelessWidget {
  final List<({String minQty, String percent})> tiers;
  final String? uom;
  final Map<String, String> errors;
  final bool showErrors;
  final void Function(int index, {String? minQty, String? percent}) onTierChanged;
  final ValueChanged<int> onRemoveTier;
  final VoidCallback onAddTier;

  const ProgramTierRows({
    super.key,
    required this.tiers,
    required this.uom,
    required this.errors,
    required this.showErrors,
    required this.onTierChanged,
    required this.onRemoveTier,
    required this.onAddTier,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final uomText = (uom != null && uom!.trim().isNotEmpty) ? uom!.trim() : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < tiers.length; i++) ...[
          _TierRowItem(
            key: ValueKey('tier-row-$i'),
            index: i,
            minQty: tiers[i].minQty,
            percent: tiers[i].percent,
            uomText: uomText,
            errorText: showErrors ? errors['tier.$i'] : null,
            canRemove: tiers.length > 1,
            onMinQtyChanged: (v) => onTierChanged(i, minQty: v),
            onPercentChanged: (v) => onTierChanged(i, percent: v),
            onRemove: () => onRemoveTier(i),
          ),
          if (i < tiers.length - 1) const SizedBox(height: VSpacing.space2),
        ],
        if (showErrors && errors['tiers'] != null) ...[
          const SizedBox(height: VSpacing.space1),
          VText(
            errors['tiers']!,
            variant: VTextVariant.bodySmall,
            color: colors.danger,
          ),
        ],
        if (tiers.length < 5) ...[
          const SizedBox(height: VSpacing.space2),
          VButton(
            label: 'Thêm bậc',
            variant: VButtonVariant.tertiary,
            leading: VIcons.add,
            onPressed: onAddTier,
          ),
        ],
      ],
    );
  }
}

class _TierRowItem extends StatefulWidget {
  final int index;
  final String minQty;
  final String percent;
  final String uomText;
  final String? errorText;
  final bool canRemove;
  final ValueChanged<String> onMinQtyChanged;
  final ValueChanged<String> onPercentChanged;
  final VoidCallback onRemove;

  const _TierRowItem({
    super.key,
    required this.index,
    required this.minQty,
    required this.percent,
    required this.uomText,
    required this.errorText,
    required this.canRemove,
    required this.onMinQtyChanged,
    required this.onPercentChanged,
    required this.onRemove,
  });

  @override
  State<_TierRowItem> createState() => _TierRowItemState();
}

class _TierRowItemState extends State<_TierRowItem> {
  late final TextEditingController _minController;
  late final TextEditingController _pctController;

  @override
  void initState() {
    super.initState();
    _minController = TextEditingController(text: widget.minQty);
    _pctController = TextEditingController(text: widget.percent);
  }

  @override
  void didUpdateWidget(covariant _TierRowItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    final parsedMin = ProgramFormDraft.parseNum(_minController.text);
    final nextMin = ProgramFormDraft.parseNum(widget.minQty);
    if (parsedMin != nextMin && widget.minQty != _minController.text) {
      _minController.text = widget.minQty;
    }
    final parsedPct = ProgramFormDraft.parseNum(_pctController.text);
    final nextPct = ProgramFormDraft.parseNum(widget.percent);
    if (parsedPct != nextPct && widget.percent != _pctController.text) {
      _pctController.text = widget.percent;
    }
  }

  @override
  void dispose() {
    _minController.dispose();
    _pctController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final hasError = widget.errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            VText(
              'Từ',
              variant: VTextVariant.bodyDefault,
              color: colors.textSecondary,
            ),
            const SizedBox(width: VSpacing.space2),
            Expanded(
              child: VNumberField(
                controller: _minController,
                allowDecimal: true,
                decimalPlaces: 3,
                suffixText: widget.uomText.isNotEmpty ? widget.uomText : null,
                invalid: hasError,
                onChanged: (val) =>
                    widget.onMinQtyChanged(_formatDraftNum(val)),
              ),
            ),
            const SizedBox(width: VSpacing.space2),
            VText(
              'giảm',
              variant: VTextVariant.bodyDefault,
              color: colors.textSecondary,
            ),
            const SizedBox(width: VSpacing.space2),
            Expanded(
              child: VNumberField(
                controller: _pctController,
                allowDecimal: true,
                decimalPlaces: 2,
                suffixText: '%',
                invalid: hasError,
                onChanged: (val) =>
                    widget.onPercentChanged(_formatDraftNum(val)),
              ),
            ),
            if (widget.canRemove) ...[
              const SizedBox(width: VSpacing.space1),
              IconButton(
                tooltip: 'Xoá bậc',
                icon: VIcon(
                  icon: VIcons.close,
                  size: 18,
                  color: colors.textSecondary,
                ),
                onPressed: widget.onRemove,
              ),
            ],
          ],
        ),
        if (hasError) ...[
          const SizedBox(height: VSpacing.space1),
          VText(
            widget.errorText!,
            variant: VTextVariant.bodySmall,
            color: colors.danger,
          ),
        ],
      ],
    );
  }
}

String _formatDraftNum(num? val) {
  if (val == null) return '';
  if (val == val.truncateToDouble()) return val.toInt().toString();
  return val.toString();
}
