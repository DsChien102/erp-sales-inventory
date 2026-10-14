import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../data/models/receipt_item_draft.dart';
import '../../data/models/receipt_lot_draft.dart';
import '../../logic/quick_receipt_session_cubit.dart';
import '../../logic/receipt_rules.dart';
import '../widgets/receipt_key_value_row.dart';
import '../widgets/receipt_lot_editor_card.dart';

class GoodsReceiptItemDetailPage extends StatefulWidget {
  const GoodsReceiptItemDetailPage({
    super.key,
    required this.item,
    this.readOnly = false,
  });

  final ReceiptItemDraft item;
  final bool readOnly;

  @override
  State<GoodsReceiptItemDetailPage> createState() =>
      _GoodsReceiptItemDetailPageState();
}

class _GoodsReceiptItemDetailPageState
    extends State<GoodsReceiptItemDetailPage> {
  late List<ReceiptLotDraft> _lots;
  bool _showErrors = false;

  @override
  void initState() {
    super.initState();
    _lots = widget.item.lots.isEmpty
        ? [const ReceiptLotDraft()]
        : List.from(widget.item.lots);
  }

  void _addNewLot() {
    setState(() {
      _lots.add(const ReceiptLotDraft());
    });
  }

  void _updateLot(int index, ReceiptLotDraft updated) {
    setState(() {
      _lots[index] = updated;
    });
  }

  void _deleteLot(int index) {
    if (_lots.length > 1) {
      setState(() {
        _lots.removeAt(index);
      });
    }
  }

  void _save() {
    final draft = widget.item.copyWith(lots: _lots);
    if (!validateReceiptItem(draft).isValid) {
      setState(() => _showErrors = true);
      return;
    }
    context.read<QuickReceiptSessionCubit>().saveItem(draft);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final item = widget.item;
    final draft = item.copyWith(lots: _lots);
    final validation = validateReceiptItem(draft);
    final readOnly = widget.readOnly;

    final cubit = readOnly ? null : context.read<QuickReceiptSessionCubit>();
    final existingIndex =
        cubit?.indexOf(item.productId, item.unitId) ?? -1;
    final unit = item.unitName;

    return Scaffold(
      backgroundColor: colors.surfaceAlt,
      appBar: const VAppBar(
        title: 'Chi tiết hàng thực nhận',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(VSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VText(
              item.productName,
              style: VTypography.headingH4.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const VGap(VSpacing.space1),
            VText(
              '${item.productCode} · $unit',
              style: VTypography.bodySmall.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const VGap(VSpacing.space4),
            if (item.isLotTracked)
              VText(
                'Các lô thực nhận',
                style: VTypography.labelDefault.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            if (item.isLotTracked) const VGap(VSpacing.space2),
            for (var index = 0; index < _lots.length; index++) ...[
              if (index > 0) const VGap(VSpacing.space3),
              ReceiptLotEditorCard(
                lot: _lots[index],
                index: index,
                isLotTracked: item.isLotTracked,
                requiresExpiry: item.requiresExpiry,
                unitName: unit,
                readOnly: readOnly,
                issues: _showErrors && index < validation.lotIssues.length
                    ? validation.lotIssues[index]
                    : const {},
                onChanged: (updated) => _updateLot(index, updated),
                onDelete: _lots.length > 1 && !readOnly
                    ? () => _deleteLot(index)
                    : null,
              ),
            ],
            if (item.isLotTracked && !readOnly) ...[
              const VGap(VSpacing.space3),
              VButton(
                label: 'Thêm lô khác',
                leading: VIcons.add,
                variant: VButtonVariant.secondary,
                onPressed: _addNewLot,
              ),
            ],
            const VGap(VSpacing.space4),
            VCard(
              child: Padding(
                padding: const EdgeInsets.all(VSpacing.space4),
                child: Column(
                  children: [
                    ReceiptKeyValueRow(
                      label: 'Tổng kiểm nhận',
                      value: '${formatQuantity(draft.totalReceived)} $unit',
                    ),
                    ReceiptKeyValueRow(
                      label: 'Vào tồn vật lý',
                      value: '${formatQuantity(draft.totalPhysicalStock)} $unit',
                    ),
                  ],
                ),
              ),
            ),
            if (!readOnly && existingIndex >= 0) ...[
              const VGap(VSpacing.space4),
              Center(
                child: VButton(
                  label: 'Xóa khỏi lần nhận',
                  variant: VButtonVariant.link,
                  tone: VComponentTone.danger,
                  onPressed: () => showVConfirmDialog(
                    context: context,
                    title: 'Xóa khỏi lần nhận?',
                    message:
                        'Toàn bộ số lượng và thông tin lô của dòng hàng này sẽ bị xóa.',
                    cancelLabel: 'Giữ lại',
                    actionLabel: 'Xóa',
                    isDestructive: true,
                    onAction: () {
                      final session = context.read<QuickReceiptSessionCubit>();
                      session.removeItem(
                        session.indexOf(item.productId, item.unitId),
                      );
                      context.pop();
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: readOnly
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(VSpacing.space4),
                child: VButton(
                  label: 'Xong',
                  fullWidth: true,
                  size: VButtonSize.large,
                  onPressed: _save,
                ),
              ),
            ),
    );
  }
}
