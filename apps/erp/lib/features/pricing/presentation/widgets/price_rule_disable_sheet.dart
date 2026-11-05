import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/core/formatting/money_formatter.dart';
import 'package:erp/features/pricing/data/models.dart';

import '../../logic/price_rule_detail_cubit.dart';

/// D-01 SG-05 — Bottom sheet Tắt giá riêng.
class PriceRuleDisableSheet extends StatefulWidget {
  const PriceRuleDisableSheet({
    super.key,
    required this.rule,
    required this.cubit,
  });

  final CustomerPriceRuleDetailDto rule;
  final PriceRuleDetailCubit cubit;

  static Future<bool> show({
    required BuildContext context,
    required CustomerPriceRuleDetailDto rule,
    required PriceRuleDetailCubit cubit,
  }) async {
    final result = await showVBottomSheet<bool>(
      context: context,
      title: 'Tắt giá riêng',
      semanticLabel: 'Xác nhận tắt giá riêng',
      child: PriceRuleDisableSheet(
        key: const Key('wgt_e02_u07_fr01_01'),
        rule: rule,
        cubit: cubit,
      ),
    );
    return result ?? false;
  }

  @override
  State<PriceRuleDisableSheet> createState() => _PriceRuleDisableSheetState();
}

class _PriceRuleDisableSheetState extends State<PriceRuleDisableSheet> {
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _onDisable() async {
    setState(() => _isSubmitting = true);
    final result = await widget.cubit.disableRule(
      ruleId: widget.rule.id,
      expectedVersion: widget.rule.version,
      reason: _reasonController.text.trim().isEmpty ? null : _reasonController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (result != null) {
      Navigator.of(context).pop(true);
      VToast.show(
        context,
        title: 'Đã tắt giá riêng',
        message: 'Giá riêng sẽ không áp dụng cho đơn hàng mới.',
        type: VToastType.success,
      );
    } else {
      VToast.show(
        context,
        title: 'Không thể tắt giá riêng',
        message: widget.cubit.actionErrorMessage ?? 'Vui lòng thử lại sau.',
        type: VToastType.danger,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final rule = widget.rule;

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
              Center(
                child: VIconBox(
                  icon: VIcons.warning,
                  size: 56,
                  iconSize: 28,
                  tone: VComponentTone.danger,
                  isCircular: true,
                ),
              ),
              const VGap.md(),
              VText(
                'Tắt giá riêng?',
                variant: VTextVariant.headingH3,
                textAlign: TextAlign.center,
              ),
              const VGap.xs(),
              VText(
                'Giá riêng sẽ không còn áp dụng cho đơn hàng mới. Lịch sử vẫn được giữ lại.',
                variant: VTextVariant.bodySmall,
                color: colors.textSecondary,
                textAlign: TextAlign.center,
              ),
              const VGap.md(),
              VCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VText(
                      rule.customer.displayName,
                      variant: VTextVariant.bodyDefault,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const VGap.xs(),
                    VText(
                      '${rule.productUnit.productName} · ${rule.productUnit.unitName}',
                      variant: VTextVariant.bodySmall,
                      color: colors.textSecondary,
                    ),
                    const VGap.xs(),
                    VText(
                      _formatMoney(rule.price),
                      variant: VTextVariant.monoNumeric,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const VGap.md(),
              VTextFormField(
                label: 'Lý do tắt (không bắt buộc)',
                controller: _reasonController,
                maxLines: 2,
              ),
              const VGap.md(),
              Row(
                children: [
                  Expanded(
                    child: VButton(
                      label: 'Giữ giá riêng',
                      variant: VButtonVariant.secondary,
                      fullWidth: true,
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const VGap.horizontalMd(),
                  Expanded(
                    child: VButton(
                      label: _isSubmitting ? 'Đang tắt...' : 'Tắt giá riêng',
                      variant: VButtonVariant.primary,
                      tone: VComponentTone.danger,
                      fullWidth: true,
                      onPressed: _isSubmitting ? null : _onDisable,
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

  String _formatMoney(MoneyDto money) {
    final formatted = MoneyFormatter.format(
      amountMinor: money.amountMinor,
      currencyCode: money.currencyCode,
    );
    return '$formatted / ${widget.rule.productUnit.unitName}';
  }
}
