import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_pricing_application/application.dart';

import '../cubit/price_rule_detail_cubit.dart';

/// D-03 SG-05 — Bottom sheet Bật lại giá riêng (precheck + confirm).
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
  bool _isLoadingPrecheck = true;
  bool _isSubmitting = false;
  bool _acknowledgeFloorWarning = false;
  CustomerPriceRuleReenablePrecheckDto? _precheck;
  String? _precheckError;

  @override
  void initState() {
    super.initState();
    _runPrecheck();
  }

  Future<void> _runPrecheck() async {
    setState(() {
      _isLoadingPrecheck = true;
      _precheckError = null;
      _precheck = null;
      _acknowledgeFloorWarning = false;
    });

    final result = await widget.cubit.precheckReenable(
      ruleId: widget.rule.id,
      expectedVersion: widget.rule.version,
    );

    if (!mounted) return;

    if (result == null) {
      setState(() {
        _isLoadingPrecheck = false;
        _precheckError =
            widget.cubit.actionErrorMessage ??
            'Không thể kiểm tra điều kiện bật lại.';
      });
      return;
    }

    setState(() {
      _isLoadingPrecheck = false;
      _precheck = result;
    });
  }

  bool get _hasFloorWarning =>
      _precheck?.validationOutcome.outcome == 'warning' &&
      _precheck!.validationOutcome.warningCodes.contains('below_floor_price');

  bool get _isBlocked => _precheck?.validationOutcome.outcome == 'blocked';

  bool get _canConfirm =>
      !_isLoadingPrecheck &&
      !_isSubmitting &&
      _precheck != null &&
      !_isBlocked &&
      (!_hasFloorWarning || _acknowledgeFloorWarning);

  Future<void> _onReenable() async {
    final precheck = _precheck;
    if (precheck == null || !_canConfirm) return;

    setState(() => _isSubmitting = true);
    final result = await widget.cubit.reenableRule(
      ruleId: widget.rule.id,
      expectedVersion: precheck.ruleVersion,
      precheckToken: precheck.precheckToken,
      acknowledgeFloorWarning: _hasFloorWarning && _acknowledgeFloorWarning,
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
        message: widget.cubit.actionErrorMessage ?? 'Vui lòng thử lại sau.',
        type: VToastType.danger,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final rule = widget.rule;
    final to = rule.effectivePeriod.effectiveTo;

    if (_isLoadingPrecheck) {
      return const Material(
        color: Colors.transparent,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.all(VSpacing.space4),
            child: VSkeletonScope(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  VSkeleton(width: double.infinity, height: 56),
                  VGap.md(),
                  VSkeleton(width: double.infinity, height: 120),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_precheckError != null) {
      return Material(
        color: Colors.transparent,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(VSpacing.space4),
            child: VEmptyState(
              icon: VIcons.error,
              title: 'Không thể kiểm tra',
              description: _precheckError!,
              actionLabel: 'Thử lại',
              onActionPressed: _runPrecheck,
            ),
          ),
        ),
      );
    }

    final precheck = _precheck!;
    final blockedMessage = _isBlocked
        ? widget.cubit.messageForPrecheckBlocked(precheck.validationOutcome)
        : null;

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            VSpacing.space4,
            VSpacing.space2,
            VSpacing.space4,
            VSpacing.space5,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: VIconBox(
                  icon: _isBlocked ? VIcons.warning : VIcons.success,
                  size: 56,
                  iconSize: 28,
                  tone: _isBlocked
                      ? VComponentTone.danger
                      : VComponentTone.success,
                  isCircular: true,
                ),
              ),
              const VGap.md(),
              VText(
                _isBlocked ? 'Không thể bật lại' : 'Bật lại giá riêng?',
                variant: VTextVariant.headingH3,
                textAlign: TextAlign.center,
              ),
              const VGap.xs(),
              VText(
                _isBlocked
                    ? blockedMessage!
                    : 'Giá riêng sẽ được áp dụng lại nếu còn trong thời gian hiệu lực.',
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
              if (_hasFloorWarning) ...[
                const VGap.md(),
                VBanner(
                  tone: VComponentTone.warning,
                  icon: VIcons.warning,
                  title: 'Giá dưới giá sàn',
                  message:
                      'Giá riêng thấp hơn giá sàn hiện tại. Bạn cần xác nhận trước khi bật lại.',
                ),
                const VGap.sm(),
                VCheckbox(
                  value: _acknowledgeFloorWarning,
                  label: 'Tôi xác nhận bật lại giá dưới giá sàn',
                  enabled: !_isSubmitting,
                  onChanged: (value) => setState(
                    () => _acknowledgeFloorWarning = value ?? false,
                  ),
                ),
              ],
              if (!_isBlocked) ...[
                const VGap.md(),
                VBanner(
                  tone: VComponentTone.info,
                  icon: VIcons.info,
                  title: 'Lưu ý',
                  message:
                      'Bật lại giá riêng này sẽ tự động tắt giá riêng đang áp dụng trùng khách hàng / sản phẩm / đơn vị (nếu có).',
                ),
              ],
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
                  if (!_isBlocked) ...[
                    const VGap.horizontalMd(),
                    Expanded(
                      child: VButton(
                        label: _isSubmitting
                            ? 'Đang bật lại...'
                            : 'Bật lại giá riêng',
                        variant: VButtonVariant.primary,
                        fullWidth: true,
                        onPressed: _canConfirm ? _onReenable : null,
                      ),
                    ),
                  ],
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
