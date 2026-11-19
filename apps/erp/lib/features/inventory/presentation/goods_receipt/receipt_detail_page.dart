import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/di/injection.dart';
import 'package:erp/core/formatting/money_formatter.dart';
import 'package:erp/features/inventory/data/goods_receipt/goods_receipt_models.dart';
import 'package:erp/features/inventory/data/goods_receipt/goods_receipt_repository.dart';
import 'package:erp/features/inventory/logic/goods_receipt/receipt_detail_cubit.dart';
import 'package:erp/features/inventory/logic/goods_receipt/receipt_detail_state.dart';

class ReceiptDetailPage extends StatelessWidget {
  const ReceiptDetailPage({
    super.key,
    required this.receiptId,
    this.repository,
  });

  final String receiptId;
  final GoodsReceiptRepository? repository;

  GoodsReceiptRepository _resolveRepo(BuildContext context) {
    if (repository != null) return repository!;
    try {
      return context.read<GoodsReceiptRepository>();
    } catch (_) {
      return getIt<GoodsReceiptRepository>();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => ReceiptDetailCubit(
        repository: _resolveRepo(ctx),
      )..load(receiptId),
      child: const _ReceiptDetailView(),
    );
  }
}

class _ReceiptDetailView extends StatelessWidget {
  const _ReceiptDetailView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReceiptDetailCubit, ReceiptDetailState>(
      builder: (context, state) {
        return switch (state.status) {
          ReceiptDetailStatus.loading => const VPageScaffold(
              title: 'Phiếu nhận hàng',
              body: Center(child: CircularProgressIndicator()),
            ),
          ReceiptDetailStatus.notFound => const VPageScaffold(
              title: 'Phiếu nhận hàng',
              body: Center(
                child: Text('Không tìm thấy phiếu nhận hàng.'),
              ),
            ),
          ReceiptDetailStatus.loadError => const VPageScaffold(
              title: 'Phiếu nhận hàng',
              body: Center(
                child: Text('Đã có lỗi xảy ra khi tải phiếu nhận.'),
              ),
            ),
          ReceiptDetailStatus.ready when state.receipt != null =>
            _buildContent(context, state.receipt!),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }

  Widget _buildContent(BuildContext context, ReceiptDetail detail) {
    final colors = context.vColors;
    final header = detail.header;
    final docStr = header.supplierDocNo != null && header.supplierDocNo!.isNotEmpty
        ? ' · HĐ: ${header.supplierDocNo}'
        : '';
    final subtitle = '${header.supplierName}$docStr · ${header.businessDate}';

    return VPageScaffold(
      title: 'Phiếu nhận ${header.receiptNo}',
      subtitle: subtitle,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: 'Quay lại',
        onPressed: () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            context.go('/warehouse/receipts');
          }
        },
      ),
      contentMaxWidth: const VResponsiveValue(
        mobile: double.infinity,
        tablet: 900,
        desktop: 1200,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(VSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thông tin chung
            VCard(
              child: Column(
                children: [
                  VKeyValueRow(
                    label: 'Số phiếu',
                    value: header.receiptNo,
                    mono: true,
                  ),
                  VKeyValueRow(
                    label: 'Nhà cung cấp',
                    value: header.supplierName,
                  ),
                  if (header.supplierDocNo != null && header.supplierDocNo!.isNotEmpty)
                    VKeyValueRow(
                      label: 'Số chứng từ NCC',
                      value: header.supplierDocNo!,
                    ),
                  VKeyValueRow(
                    label: 'Kho nhập',
                    value: header.warehouseName,
                  ),
                  VKeyValueRow(
                    label: 'Ngày nhập',
                    value: header.businessDate,
                  ),
                  VKeyValueRow(
                    label: 'Người nhận',
                    value: header.createdByName,
                  ),
                ],
              ),
            ),
            const SizedBox(height: VSpacing.space4),

            // Dải tóm tắt tài chính (giá trị đã lưu)
            VSummaryStrip(
              items: [
                VSummaryItem(
                  'Giá mua',
                  '${MoneyFormatter.formatMinorPlain(header.purchaseTotalVnd)} đ',
                ),
                VSummaryItem(
                  'Chi phí (+)',
                  '${MoneyFormatter.formatMinorPlain(header.freightCostVnd)} đ',
                ),
                VSummaryItem(
                  'Chiết khấu (-)',
                  '${MoneyFormatter.formatMinorPlain(header.tradeDiscountVnd)} đ',
                ),
                VSummaryItem(
                  'Giá gốc (=)',
                  '${MoneyFormatter.formatMinorPlain(header.landedTotalVnd)} đ',
                ),
              ],
            ),
            const SizedBox(height: VSpacing.space4),

            // Danh sách dòng hàng
            Text(
              'Danh sách hàng nhận (${detail.lines.length})',
              style: VTypography.headingH4,
            ),
            const SizedBox(height: VSpacing.space2),
            for (final line in detail.lines) ...[
              VCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${line.productName} (${line.unitName})',
                      style: VTypography.labelDefault,
                    ),
                    const SizedBox(height: VSpacing.space1),
                    VKeyValueRow(
                      label: 'Số lượng mua',
                      value: '${_formatNum(line.paidQty)} ${line.unitName}',
                    ),
                    if (line.freeQty > 0)
                      VKeyValueRow(
                        label: 'Số lượng tặng',
                        value: '${_formatNum(line.freeQty)} ${line.unitName}',
                      ),
                    VKeyValueRow(
                      label: 'Đơn giá mua',
                      value: '${MoneyFormatter.formatMinorPlain(line.unitPriceVnd)} đ',
                    ),
                    if (line.tierDiscountVnd > 0)
                      VKeyValueRow(
                        label: 'Giảm bậc',
                        value: '-${MoneyFormatter.formatMinorPlain(line.tierDiscountVnd)} đ',
                      ),
                    VKeyValueRow(
                      label: 'Thành tiền mua',
                      value: '${MoneyFormatter.formatMinorPlain(line.purchaseAmountVnd)} đ',
                    ),
                    VKeyValueRow(
                      label: 'Chi phí phân bổ',
                      value: '+${MoneyFormatter.formatMinorPlain(line.allocatedFreightVnd)} đ',
                    ),
                    VKeyValueRow(
                      label: 'Chiết khấu phân bổ',
                      value: '-${MoneyFormatter.formatMinorPlain(line.allocatedDiscountVnd)} đ',
                    ),
                    VKeyValueRow(
                      label: 'Giá gốc đã lưu',
                      value: '${MoneyFormatter.formatMinorPlain(line.landedAmountVnd)} đ',
                      emphasized: true,
                    ),
                    VKeyValueRow(
                      label: 'Đơn giá gốc',
                      value: '${MoneyFormatter.formatMinorPlain(line.landedUnitCost.round())} đ/${line.unitName}',
                    ),
                    if (line.lots.isNotEmpty) ...[
                      const SizedBox(height: VSpacing.space2),
                      const Divider(),
                      const SizedBox(height: VSpacing.space1),
                      Text('Các lô (${line.lots.length}):', style: VTypography.caption),
                      for (final lot in line.lots) ...[
                        const SizedBox(height: VSpacing.space1),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              lot.lotCode ?? '(Không mã lô)',
                              style: VTypography.bodySmall,
                            ),
                            Text(
                              '${_formatNum(lot.quantity)} ${line.unitName}',
                              style: VTypography.bodySmall,
                            ),
                            if (lot.allocatedLandedCostVnd != null)
                              Text(
                                '${MoneyFormatter.formatMinorPlain(lot.allocatedLandedCostVnd!)} đ',
                                style: VTypography.bodySmall.copyWith(color: colors.primary),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(height: VSpacing.space2),
            ],
          ],
        ),
      ),
    );
  }

  static String _formatNum(num n) {
    if (n % 1 == 0) return n.toInt().toString();
    return n.toString();
  }
}
