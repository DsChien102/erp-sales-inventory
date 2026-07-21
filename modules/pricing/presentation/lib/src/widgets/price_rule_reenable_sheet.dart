import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_pricing_application/application.dart';

import '../cubit/price_rule_detail_cubit.dart';

/// D-03 SG-05 — Bottom sheet Bật lại giá riêng (không validate D-06).
class PriceRuleReenableSheet extends StatefulWidget {
  const PriceRuleReenableSheet({
    super.key,
    required this.rule,
    required this.cubit,
  });

  final CustomerPriceRuleDetailDto rule;
  final PriceRuleDetailCubit cubit;

  static Future<void> show({
    required BuildContext context,
    required CustomerPriceRuleDetailDto rule,
    required PriceRuleDetailCubit cubit,
  }) {
    return showVBottomSheet(
      context: context,
      title: 'Bật lại giá riêng',
      semanticLabel: 'Xác nhận bật lại giá riêng',
      child: PriceRuleReenableSheet(
        key: const Key('wgt_e02_u08_fr01_01'),
        rule: rule,
        cubit: cubit,
      ),
    );
  }

  @override
  State<PriceRuleReenableSheet> createState() =>
      _PriceRuleReenableSheetState();
}

class _PriceRuleReenableSheetState extends State<PriceRuleReenableSheet> {
  bool _isSubmitting = false;

  Future<void> _onReenable() async {
    setState(() => _isSubmitting = true);
    final result = await widget.cubit.reenableRule(
      ruleId: widget.rule.id,
      expectedVersion: widget.rule.version,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result != null) {
      Navigator.of(context).pop();
      VToast.show(
        context,
        title: 'Bật lại giá riêng thành công',
        message: 'Giá riêng sẽ tiếp tục áp dụng cho các đơn hàng mới.',
        type: VToastType.success,
      );
    } else {
      VToast.show(
        context,
        title: 'Không thể bật lại',
        message: 'Vui lòng thử lại sau.',
        type: VToastType.danger,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final rule = widget.rule;
    final to = rule.effectivePeriod.effectiveTo;

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
              icon: VIcons.success,
              size: 56,
              iconSize: 28,
              tone: VComponentTone.success,
              isCircular: true,
            ),
          ),
          const VGap.md(),
          VText(
            'Bật lại giá riêng?',
            variant: VTextVariant.headingH3,
            textAlign: TextAlign.center,
          ),
          const VGap.xs(),
          VText(
            'Giá riêng sẽ được áp dụng lại nếu còn trong thời gian hiệu lực. Nếu có giá riêng khác trùng, hệ thống sẽ tự tắt giá đó.',
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
                const VGap.sm(),
                _MetaRow(
                  label: 'Hiệu lực từ',
                  value: _formatDate(rule.effectivePeriod.effectiveFrom),
                ),
                _MetaRow(
                  label: 'Đến ngày',
                  value: to == null ? 'Không giới hạn' : _formatDate(to),
                ),
              ],
            ),
          ),
          const VGap.md(),
          VBanner(
            tone: VComponentTone.info,
            icon: VIcons.info,
            title: 'Lưu ý',
            message:
                'Bật lại giá riêng này sẽ tự động tắt giá riêng trùng (nếu có).',
          ),
          const VGap.md(),
          Row(
            children: [
              Expanded(
                child: VButton(
                  label: 'Giữ đã tắt',
                  variant: VButtonVariant.secondary,
                  fullWidth: true,
                  onPressed: _isSubmitting
                      ? null
                      : () => Navigator.of(context).pop(),
                ),
              ),
              const VGap.horizontalMd(),
              Expanded(
                child: VButton(
                  label: _isSubmitting ? 'Đang bật lại...' : 'Bật lại giá riêng',
                  variant: VButtonVariant.primary,
                  fullWidth: true,
                  onPressed: _isSubmitting ? null : _onReenable,
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

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: VSpacing.space1),
      child: Row(
        children: [
          Expanded(
            child: VText(
              label,
              variant: VTextVariant.caption,
              color: context.vColors.textMuted,
            ),
          ),
          VText(value, variant: VTextVariant.monoNumeric),
        ],
      ),
    );
  }
}
