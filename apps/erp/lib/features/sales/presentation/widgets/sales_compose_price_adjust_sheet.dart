import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/features/sales/data/models.dart';

import '../models/sales_order_draft/sales_compose_line_vm.dart';
import '../models/shared/sales_pricing_models.dart';
import 'package:erp/core/formatting/money_formatter.dart';
/// O-01 — Điều chỉnh giá (VBottomSheet) theo Figma SG-02.
final class SalesComposePriceAdjustResult {
  const SalesComposePriceAdjustResult({required this.manualPrice});

  final SalesManualPriceDraft manualPrice;
}

abstract final class SalesComposePriceAdjustSheet {
  static Future<SalesComposePriceAdjustResult?> show(
    BuildContext context, {
    required SalesComposeLineVm line,
    required bool canSavePrivatePrice,
  }) {
    return showVBottomSheet<SalesComposePriceAdjustResult>(
      context: context,
      child: _SalesComposePriceAdjustContent(
        line: line,
        canSavePrivatePrice: canSavePrivatePrice,
      ),
    );
  }

  static Future<bool> confirmBelowFloor(BuildContext context) async {
    final result = await showVBottomSheet<bool>(
      context: context,
      tone: VComponentTone.warning,
      semanticLabel: 'Xác nhận giá dưới sàn',
      child: const _PriceConfirmationContent(
        title: 'Xác nhận giá dưới sàn?',
        message: 'Giá này cần quyền ghi đè và sẽ được lưu kèm cảnh báo.',
        confirmLabel: 'Xác nhận áp dụng',
      ),
    );
    return result ?? false;
  }

  static Future<bool> confirmOverwrite(BuildContext context) async {
    final result = await showVBottomSheet<bool>(
      context: context,
      semanticLabel: 'Xác nhận ghi đè giá riêng',
      child: const _PriceConfirmationContent(
        title: 'Ghi đè giá riêng hiện có?',
        message: 'Giá riêng đang áp dụng sẽ được cập nhật ngay.',
        confirmLabel: 'Ghi đè và áp dụng',
      ),
    );
    return result ?? false;
  }
}

class _PriceConfirmationContent extends StatelessWidget {
  const _PriceConfirmationContent({
    required this.title,
    required this.message,
    required this.confirmLabel,
  });

  final String title;
  final String message;
  final String confirmLabel;

  @override
  Widget build(BuildContext context) => VPagePadding(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VText(
          title,
          variant: VTextVariant.headingH4,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const VGap.sm(),
        VText(
          message,
          variant: VTextVariant.bodySmall,
          color: context.vColors.textSecondary,
        ),
        const VGap.md(),
        VButton(
          label: confirmLabel,
          tone: VComponentTone.success,
          fullWidth: true,
          onPressed: () => Navigator.of(context).pop(true),
        ),
        const VGap.sm(),
        VButton(
          label: 'Quay lại',
          variant: VButtonVariant.secondary,
          fullWidth: true,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    ),
  );
}

class _SalesComposePriceAdjustContent extends StatefulWidget {
  const _SalesComposePriceAdjustContent({
    required this.line,
    required this.canSavePrivatePrice,
  });

  final SalesComposeLineVm line;
  final bool canSavePrivatePrice;

  @override
  State<_SalesComposePriceAdjustContent> createState() => _SalesComposePriceAdjustContentState();
}

class _SalesComposePriceAdjustContentState extends State<_SalesComposePriceAdjustContent> {
  SalesPriceAdjustMode _mode = SalesPriceAdjustMode.unitPrice;
  late final TextEditingController _controller;
  bool _saveAsPrivate = false;

  SalesComposeLineVm get _line => widget.line;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: _formatDigits(_line.pricing.appliedUnitPrice.amountMinor),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static String _formatDigits(int amount) => VMoneyValidator.format(amount);

  int? get _parsedInput {
    final raw = _controller.text;
    if (raw.trim().isEmpty) return null;
    if (_mode == SalesPriceAdjustMode.percentOff) {
      final pct = double.tryParse(
        raw.replaceAll(RegExp(r'[^0-9.,]'), '').replaceAll(',', '.'),
      );
      return pct?.round();
    }
    return VMoneyValidator.parse(raw);
  }

  MoneyDto? get _previewApplied {
    final input = _parsedInput;
    if (input == null) return null;
    switch (_mode) {
      case SalesPriceAdjustMode.unitPrice:
        return MoneyDto(amountMinor: input, currencyCode: 'VND');
      case SalesPriceAdjustMode.amountOff:
        final next = _line.identity.catalogUnitPrice.amountMinor - input;
        return MoneyDto(
          amountMinor: next < 0 ? 0 : next,
          currencyCode: 'VND',
        );
      case SalesPriceAdjustMode.percentOff:
        if (input < 0 || input > 100) return null;
        final discounted = (_line.identity.catalogUnitPrice.amountMinor * (100 - input) / 100).round();
        return MoneyDto(
          amountMinor: discounted < 0 ? 0 : discounted,
          currencyCode: 'VND',
        );
    }
  }

  bool get _belowFloor {
    final applied = _previewApplied;
    final floor = _line.pricing.floorUnitPrice;
    if (applied == null || floor == null) return false;
    return applied.amountMinor < floor.amountMinor;
  }

  void _onModeChanged(int index) {
    final next = switch (index) {
      1 => SalesPriceAdjustMode.amountOff,
      2 => SalesPriceAdjustMode.percentOff,
      _ => SalesPriceAdjustMode.unitPrice,
    };
    if (next == _mode) return;
    setState(() {
      _mode = next;
      _controller.text = switch (next) {
        SalesPriceAdjustMode.unitPrice => _formatDigits(_line.pricing.appliedUnitPrice.amountMinor),
        SalesPriceAdjustMode.amountOff => '0',
        SalesPriceAdjustMode.percentOff => '0',
      };
    });
  }

  Future<void> _openKeypad() async {
    final isPercent = _mode == SalesPriceAdjustMode.percentOff;
    final raw = await showVNumericKeypadSheet(
      context: context,
      mode: isPercent ? VNumericKeypadMode.quantity : VNumericKeypadMode.money,
      title: switch (_mode) {
        SalesPriceAdjustMode.unitPrice => 'Nhập số tiền',
        SalesPriceAdjustMode.amountOff => 'Nhập số tiền giảm',
        SalesPriceAdjustMode.percentOff => 'Nhập phần trăm',
      },
      unitLabel: isPercent ? 'Đơn vị: %' : 'Đơn vị: VND',
      initialRaw: _controller.text.replaceAll('.', ''),
      allowDecimal: isPercent,
    );
    if (raw == null || !mounted) return;
    setState(() {
      _controller.text = isPercent ? raw : _formatDigits(int.tryParse(raw) ?? 0);
    });
  }

  void _apply() {
    final applied = _previewApplied;
    if (applied == null) {
      VToast.show(
        context,
        title: 'Giá không hợp lệ',
        message: 'Vui lòng nhập giá trị hợp lệ.',
        type: VToastType.warning,
      );
      return;
    }
    Navigator.of(context).pop(
      SalesComposePriceAdjustResult(
        manualPrice: SalesManualPriceDraft(
          mode: _mode,
          acceptedUnitPrice: applied,
          manualUnitPriceMinor: _mode == SalesPriceAdjustMode.unitPrice
              ? applied.amountMinor
              : null,
          manualDiscountMinor: _mode == SalesPriceAdjustMode.amountOff ? _parsedInput : null,
          manualDiscountBasisPoints: _mode == SalesPriceAdjustMode.percentOff
              ? (_parsedInput! * 100)
              : null,
          saveAsPrivatePrice: widget.canSavePrivatePrice && _saveAsPrivate,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final list = _line.resolvedListPrice;
    final appliedLabel =
        '${MoneyFormatter.format(amountMinor: _line.pricing.appliedUnitPrice.amountMinor, currencyCode: _line.pricing.appliedUnitPrice.currencyCode)}/${_line.identity.unitLabel}';
    final listLabel = '${MoneyFormatter.format(amountMinor: list.amountMinor, currencyCode: list.currencyCode)}/${_line.identity.unitLabel}';
    final floor = _line.pricing.floorUnitPrice;

    return VPagePadding(
      child: SingleChildScrollView(
        child: Column(
          key: const Key('wgt_sg02_price_adjust_sheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const VText(
              'Điều chỉnh giá',
              variant: VTextVariant.headingH3,
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const VGap.sm(),
            VCard(
              child: Row(
                children: [
                  VIconBox(
                    icon: VIcons.inventory,
                    size: 48,
                    iconSize: 24,
                    backgroundColor: colors.surfaceAlt,
                    iconColor: colors.textMuted,
                    borderRadius: VRadius.r8,
                  ),
                  const VGap.horizontalSm(),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        VText(
                          _line.identity.productName,
                          variant: VTextVariant.bodyDefault,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const VGap.xs(),
                        VText(
                          'Giá riêng áp dụng: $appliedLabel',
                          variant: VTextVariant.bodySmall,
                          color: colors.textSecondary,
                        ),
                        VText(
                          'Giá niêm yết: $listLabel',
                          variant: VTextVariant.bodySmall,
                          color: colors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const VGap.sm(),
            VText(
              'Cách điều chỉnh',
              variant: VTextVariant.bodyDefault,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const VGap.sm(),
            VSegmentedControl(
              key: const Key('segment_price_adjust_mode'),
              segments: const ['Đơn giá', 'Giảm tiền', 'Giảm %'],
              selectedIndex: switch (_mode) {
                SalesPriceAdjustMode.unitPrice => 0,
                SalesPriceAdjustMode.amountOff => 1,
                SalesPriceAdjustMode.percentOff => 2,
              },
              onChanged: _onModeChanged,
              tone: VComponentTone.success,
            ),
            const VGap.sm(),
            // Sheet đã bọc VPagePadding ngoài — không bọc thêm (tránh double inset).
            // Tap → keypad; money modes dùng VMoneyField, % dùng VNumberField.
            VField(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const VFieldLabel('Nhập điều chỉnh'),
                  GestureDetector(
                    key: const Key('input_price_adjust_value'),
                    onTap: _openKeypad,
                    behavior: HitTestBehavior.opaque,
                    child: AbsorbPointer(
                      child: _mode == SalesPriceAdjustMode.percentOff
                          ? VNumberField(
                              controller: _controller,
                              suffixText: '%',
                              textAlign: TextAlign.start,
                            )
                          : VMoneyField(
                              controller: _controller,
                              suffixText: 'đ',
                              textAlign: TextAlign.start,
                            ),
                    ),
                  ),
                  VFieldDescription(
                    'Áp dụng cho 1 ${_line.identity.unitLabel}',
                  ),
                ],
              ),
            ),
            if (_belowFloor && floor != null) ...[
              const VGap.md(),
              VBanner(
                status: VBannerStatus.warning,
                title: 'Dưới giá sàn',
                description:
                    'Giá sàn hiện tại: ${MoneyFormatter.format(amountMinor: floor.amountMinor, currencyCode: floor.currencyCode)}/${_line.identity.unitLabel}',
              ),
            ],
            VCheckbox(
              key: const Key('chk_save_private_price'),
              value: _saveAsPrivate,
              enabled: widget.canSavePrivatePrice,
              onChanged: (v) => setState(() => _saveAsPrivate = v ?? false),
              label: 'Lưu làm giá riêng',
              tone: VComponentTone.success,
            ),
            VText(
              'Lưu ngay làm giá riêng cho khách hàng này.',
              variant: VTextVariant.bodySmall,
              color: colors.textSecondary,
            ),
            if (!widget.canSavePrivatePrice)
              VText(
                'Chọn khách hàng để lưu giá riêng.',
                variant: VTextVariant.bodySmall,
                color: colors.textSecondary,
              ),
            const VGap.md(),
            Row(
              children: [
                Expanded(
                  child: VButton(
                    key: const Key('btn_price_adjust_cancel'),
                    label: 'Hủy',
                    variant: VButtonVariant.secondary,
                    fullWidth: true,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const VGap.horizontalSm(),
                Expanded(
                  child: VButton(
                    key: const Key('btn_apply_price_adjust'),
                    label: 'Áp dụng',
                    tone: VComponentTone.success,
                    fullWidth: true,
                    onPressed: _apply,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
