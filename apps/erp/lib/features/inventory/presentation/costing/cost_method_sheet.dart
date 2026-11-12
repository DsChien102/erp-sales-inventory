import 'package:erp/features/inventory/data/stock/stock_models.dart';
import 'package:erp/features/inventory/logic/costing/cost_overview_cubit.dart';
import 'package:erp/features/inventory/logic/costing/costing_rules.dart';
import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Sheet chọn phương pháp tính giá vốn (SCR-072).
Future<void> showCostMethodSheet(
  BuildContext context, {
  required CostMethod initialMethod,
  required CostOverviewCubit cubit,
}) {
  return showVAdaptiveSheet<void>(
    context: context,
    title: 'Chọn phương pháp giá vốn',
    child: _CostMethodSheetBody(
      initialMethod: initialMethod,
      cubit: cubit,
    ),
  );
}

class _CostMethodSheetBody extends StatefulWidget {
  const _CostMethodSheetBody({
    required this.initialMethod,
    required this.cubit,
  });

  final CostMethod initialMethod;
  final CostOverviewCubit cubit;

  @override
  State<_CostMethodSheetBody> createState() => _CostMethodSheetBodyState();
}

class _CostMethodSheetBodyState extends State<_CostMethodSheetBody> {
  late CostMethod _selected;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialMethod;
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  Future<void> _save() async {
    if (_submitting || _selected == widget.initialMethod) return;
    setState(() => _submitting = true);
    final ok = await widget.cubit.changeMethod(_selected);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _submitting = false);
    final msg = widget.cubit.state.message;
    if (msg != null && msg.isNotEmpty) {
      VToast.show(
        context,
        title: msg,
        message: '',
        type: VToastType.danger,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSave = !_submitting && _selected != widget.initialMethod;
    return Padding(
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VChoiceList<CostMethod>(
            selected: [_selected],
            choices: [
              for (final m in const [CostMethod.moving, CostMethod.periodic])
                VChoiceOption(
                  value: m,
                  label: methodCopy(m).$1,
                  helpText: _capitalize(methodCopy(m).$2),
                ),
            ],
            onChanged: (selected) {
              if (_submitting || selected.isEmpty) return;
              setState(() => _selected = selected.last);
            },
          ),
          const SizedBox(height: VSpacing.space3),
          VText(
            'Chỉ đổi được trước lần công bố giá vốn đầu tiên.',
            variant: VTextVariant.bodySmall,
            color: context.vColors.textSecondary,
          ),
          const SizedBox(height: VSpacing.space4),
          Row(
            children: [
              Expanded(
                child: VButton(
                  label: 'Quay lại',
                  variant: VButtonVariant.secondary,
                  fullWidth: true,
                  onPressed:
                      _submitting ? null : () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: VSpacing.space2),
              Expanded(
                child: VButton(
                  label: 'Lưu',
                  variant: VButtonVariant.primary,
                  fullWidth: true,
                  isLoading: _submitting,
                  onPressed: canSave ? _save : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
