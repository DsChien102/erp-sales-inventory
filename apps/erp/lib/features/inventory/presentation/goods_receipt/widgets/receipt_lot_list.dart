import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/features/inventory/data/goods_receipt/goods_receipt_models.dart';
import 'package:erp/features/inventory/logic/goods_receipt/receipt_draft.dart';
import 'package:erp/features/inventory/presentation/patterns/expiry_date_field.dart';

class ReceiptLotList extends StatefulWidget {
  const ReceiptLotList({
    super.key,
    required this.line,
    required this.knownLots,
    required this.onChanged,
  });

  final ReceiptLineDraft line;
  final List<KnownLot> knownLots;
  final ValueChanged<ReceiptLineDraft> onChanged;

  @override
  State<ReceiptLotList> createState() => _ReceiptLotListState();
}

class _ReceiptLotListState extends State<ReceiptLotList> {
  String? _expandedLotKey;
  final Set<String> _showManufactureLots = {};

  @override
  void initState() {
    super.initState();
    if (widget.line.lots.isNotEmpty) {
      _expandedLotKey = widget.line.lots.first.key;
    }
  }

  @override
  void didUpdateWidget(covariant ReceiptLotList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.line.key != widget.line.key) {
      _expandedLotKey = widget.line.lots.firstOrNull?.key;
    }
  }

  void _addLot() {
    final newLotKey = 'lot_${DateTime.now().microsecondsSinceEpoch}';
    final newLot = ReceiptLotEntry(
      key: newLotKey,
      code: '',
      expiryText: '',
      manufactureText: '',
      quantity: 0,
    );
    final updatedLots = [...widget.line.lots, newLot];
    setState(() {
      _expandedLotKey = newLotKey;
    });
    widget.onChanged(widget.line.copyWith(lots: updatedLots));
  }

  void _removeLot(String lotKey) {
    if (widget.line.lots.length <= 1) return;
    final updatedLots = widget.line.lots.where((l) => l.key != lotKey).toList();
    setState(() {
      if (_expandedLotKey == lotKey) {
        _expandedLotKey = updatedLots.first.key;
      }
    });
    widget.onChanged(widget.line.copyWith(lots: updatedLots));
  }

  void _updateLot(String lotKey, ReceiptLotEntry Function(ReceiptLotEntry) change) {
    final updatedLots = widget.line.lots.map((l) {
      if (l.key != lotKey) return l;
      final modified = change(l);

      // Tự động điền HSD nếu gõ mã trùng knownLots
      if (modified.code.trim().isNotEmpty &&
          modified.code.trim() != l.code.trim() &&
          modified.expiryText.isEmpty) {
        final match = widget.knownLots.where(
          (k) =>
              k.productId == widget.line.product.id &&
              k.code.trim().toLowerCase() == modified.code.trim().toLowerCase(),
        ).firstOrNull;
        if (match != null && match.expiry != null) {
          return modified.copyWith(expiryText: match.expiry!.format());
        }
      }
      return modified;
    }).toList();

    widget.onChanged(widget.line.copyWith(lots: updatedLots));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final isLotTracked = widget.line.product.isLotTracked;

    // Sản phẩm không quản lý lô
    if (!isLotTracked) {
      final lot = widget.line.lots.firstOrNull ??
          ReceiptLotEntry(
            key: 'lot_0',
            code: '',
            expiryText: '',
            manufactureText: '',
            quantity: 0,
          );

      return VField(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const VFieldLabel('Số lượng nhận', isRequired: true),
            const SizedBox(height: VSpacing.space1),
            VNumberField(
              key: const Key('receipt_untracked_qty'),
              value: lot.quantity > 0 ? lot.quantity : null,
              suffixText: widget.line.unit.name,
              onChanged: (val) {
                _updateLot(lot.key, (l) => l.copyWith(quantity: val ?? 0));
              },
            ),
          ],
        ),
      );
    }

    // Sản phẩm quản lý theo lô
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Các lô thực nhận',
          style: VTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: VSpacing.space2),
        for (var i = 0; i < widget.line.lots.length; i++) ...[
          _buildLotAccordionItem(context, widget.line.lots[i], i),
          const SizedBox(height: VSpacing.space2),
        ],
        VButton(
          variant: VButtonVariant.secondary,
          size: VButtonSize.small,
          fullWidth: true,
          label: 'Thêm lô khác',
          onPressed: _addLot,
        ),
      ],
    );
  }

  Widget _buildLotAccordionItem(
    BuildContext context,
    ReceiptLotEntry lot,
    int index,
  ) {
    final colors = context.vColors;
    final isExpanded = _expandedLotKey == lot.key;

    final parts = <String>[];
    parts.add(lot.code.trim().isNotEmpty ? lot.code.trim() : 'Lô ${index + 1}');
    if (lot.expiryText.trim().isNotEmpty) {
      parts.add('HSD ${lot.expiryText.trim()}');
    }
    if (lot.quantity > 0) {
      parts.add('${lot.quantity} ${widget.line.unit.name}');
    } else {
      parts.add('Chưa hoàn tất');
    }
    final summaryLabel = parts.join(' · ');

    final hasKnown = widget.knownLots.any(
      (k) =>
          k.productId == widget.line.product.id &&
          k.code.trim().toLowerCase() == lot.code.trim().toLowerCase(),
    );

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(VRadius.r12),
        border: Border.all(
          color: isExpanded ? colors.borderBrand : colors.borderDefault,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _expandedLotKey = isExpanded ? null : lot.key;
              });
            },
            borderRadius: BorderRadius.circular(VRadius.r12),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: VSpacing.space4,
                vertical: VSpacing.space3,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      summaryLabel,
                      style: VTypography.bodyDefault.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: colors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const VDivider(),
            Padding(
              padding: const EdgeInsets.all(VSpacing.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VField(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const VFieldLabel('Mã lô', isRequired: true),
                        const SizedBox(height: VSpacing.space1),
                        VTextField(
                          key: const Key('receipt_lot_code'),
                          controller: TextEditingController(text: lot.code),
                          hintText: 'Nhập mã trên bao bì',
                          onChanged: (val) {
                            _updateLot(lot.key, (l) => l.copyWith(code: val));
                          },
                        ),
                        if (hasKnown) ...[
                          const SizedBox(height: VSpacing.space1),
                          const VFieldDescription('Lô đã có trong kho'),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: VSpacing.space3),
                  InventoryExpiryField(
                    label: 'Hạn dùng',
                    required: widget.line.product.expiryRequired,
                    helper:
                        'Ghi như trên bao bì: ngày/tháng/năm, tháng/năm hoặc năm',
                    errorText: 'Hạn dùng chưa đúng dạng',
                    value: lot.expiryText,
                    onChanged: (val) {
                      _updateLot(lot.key, (l) => l.copyWith(expiryText: val));
                    },
                  ),
                  const SizedBox(height: VSpacing.space3),
                  if (_showManufactureLots.contains(lot.key) ||
                      lot.manufactureText.trim().isNotEmpty) ...[
                    InventoryExpiryField(
                      label: 'Ngày sản xuất',
                      errorText: 'Ngày sản xuất chưa đúng dạng',
                      value: lot.manufactureText,
                      onChanged: (val) {
                        _updateLot(
                            lot.key, (l) => l.copyWith(manufactureText: val));
                      },
                    ),
                    const SizedBox(height: VSpacing.space3),
                  ] else ...[
                    VButton(
                      variant: VButtonVariant.tertiary,
                      label: 'Thêm ngày sản xuất',
                      onPressed: () {
                        setState(() {
                          _showManufactureLots.add(lot.key);
                        });
                      },
                    ),
                    const SizedBox(height: VSpacing.space3),
                  ],
                  VField(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const VFieldLabel('Số lượng nhận', isRequired: true),
                        const SizedBox(height: VSpacing.space1),
                        VNumberField(
                          key: const Key('receipt_lot_qty'),
                          value: lot.quantity > 0 ? lot.quantity : null,
                          suffixText: widget.line.unit.name,
                          onChanged: (val) {
                            _updateLot(
                                lot.key, (l) => l.copyWith(quantity: val ?? 0));
                          },
                        ),
                      ],
                    ),
                  ),
                  if (widget.line.lots.length > 1) ...[
                    const SizedBox(height: VSpacing.space3),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: VButton(
                        variant: VButtonVariant.tertiary,
                        tone: VComponentTone.danger,
                        label: 'Xóa lô',
                        onPressed: () => _removeLot(lot.key),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
