import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/core/formatting/money_formatter.dart';
import 'package:erp/features/inventory/data/goods_receipt/goods_receipt_models.dart';
import 'package:erp/features/inventory/data/goods_receipt/goods_receipt_repository.dart';

class ReceiptHistorySection extends StatefulWidget {
  const ReceiptHistorySection({
    super.key,
    required this.supplierId,
    required this.repository,
    required this.onViewAll,
    required this.onOpenReceipt,
  });

  final String supplierId;
  final GoodsReceiptRepository repository;
  final VoidCallback onViewAll;
  final ValueChanged<String> onOpenReceipt;

  @override
  State<ReceiptHistorySection> createState() => _ReceiptHistorySectionState();
}

class _ReceiptHistorySectionState extends State<ReceiptHistorySection> {
  bool _loading = true;
  List<ReceiptListRow> _rows = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await widget.repository.list(
        supplierId: widget.supplierId,
        limit: 5,
      );
      if (mounted) {
        setState(() {
          _rows = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(VSpacing.space4),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_rows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(VSpacing.space2),
        child: Text('Chưa có lịch sử nhập hàng từ nhà cung cấp này.'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Lịch sử nhập hàng', style: VTypography.headingH4),
            VButton(
              label: 'Xem tất cả',
              variant: VButtonVariant.link,
              onPressed: widget.onViewAll,
            ),
          ],
        ),
        const SizedBox(height: VSpacing.space2),
        for (final row in _rows) ...[
          VCard(
            onTap: () => widget.onOpenReceipt(row.receiptId),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(row.receiptNo, style: VTypography.labelDefault),
                      const SizedBox(height: VSpacing.space1),
                      Text(
                        '${row.businessDate} · ${row.lineCount} dòng (${row.lotCount} lô)',
                        style: VTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${MoneyFormatter.formatMinorPlain(row.landedTotalVnd)} đ',
                  style: VTypography.labelDefault.copyWith(
                    color: context.vColors.primary,
                  ),
                ),
                const SizedBox(width: VSpacing.space1),
                const Icon(Icons.chevron_right, size: 20),
              ],
            ),
          ),
          const SizedBox(height: VSpacing.space1),
        ],
      ],
    );
  }
}

