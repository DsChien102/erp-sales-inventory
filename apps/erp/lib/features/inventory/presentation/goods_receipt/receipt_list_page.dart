import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/core/formatting/money_formatter.dart';
import 'package:erp/features/inventory/data/goods_receipt/goods_receipt_models.dart';
import 'package:erp/features/inventory/logic/goods_receipt/receipt_list_cubit.dart';
import 'package:erp/features/inventory/logic/goods_receipt/receipt_list_state.dart';
import 'package:erp/features/inventory/presentation/goods_receipt/widgets/receipt_record_card.dart';

class ReceiptListPage extends StatelessWidget {
  const ReceiptListPage({
    super.key,
    required this.onOpenDetail,
    required this.onNewReceipt,
    this.onBack,
  });

  final ValueChanged<String> onOpenDetail;
  final VoidCallback onNewReceipt;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReceiptListCubit, ReceiptListState>(
      builder: (context, state) {
        final cubit = context.read<ReceiptListCubit>();
        final selectedSupplier = state.selectedSupplier;
        final subtitle = selectedSupplier != null
            ? 'Nhà cung cấp: ${selectedSupplier.name}'
            : null;

        return VPageScaffold(
          title: 'Phiếu nhận hàng',
          subtitle: subtitle,
          leading: onBack != null
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Quay về Kho',
                  onPressed: onBack,
                )
              : null,
          contentMaxWidth: const VResponsiveValue(
            mobile: double.infinity,
            tablet: 900,
            desktop: 1200,
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: VSpacing.space2),
              child: VButton(
                label: 'Nhận hàng',
                size: VButtonSize.small,
                onPressed: onNewReceipt,
              ),
            ),
          ],
          floatingActionButton: FloatingActionButton.extended(
            onPressed: onNewReceipt,
            label: const Text('Nhận hàng'),
            icon: const Icon(Icons.add),
          ),
          body: RefreshIndicator(
            onRefresh: cubit.refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(VSpacing.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Search & Supplier filter
                  Row(
                    children: [
                      Expanded(
                        child: VSearchBar(
                          hintText: 'Tìm theo số phiếu, chứng từ, NCC...',
                          onChanged: cubit.setQuery,
                        ),
                      ),
                      if (state.suppliers.isNotEmpty) ...[
                        const SizedBox(width: VSpacing.space2),
                        _buildSupplierDropdown(context, state, cubit),
                      ],
                    ],
                  ),
                  const SizedBox(height: VSpacing.space4),

                  // Content
                  switch (state.status) {
                    ReceiptListStatus.loading => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(VSpacing.space6),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ReceiptListStatus.loadError => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(VSpacing.space6),
                          child: Column(
                            children: [
                              const Text('Không tải được danh sách phiếu nhận.'),
                              const SizedBox(height: VSpacing.space2),
                              VButton(
                                label: 'Thử lại',
                                size: VButtonSize.small,
                                onPressed: cubit.refresh,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ReceiptListStatus.empty when state.all.isEmpty => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(VSpacing.space8),
                          child: Text('Chưa có phiếu nhận hàng nào.'),
                        ),
                      ),
                    _ when state.visible.isEmpty => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(VSpacing.space8),
                          child: Text('Không tìm thấy phiếu nhận phù hợp.'),
                        ),
                      ),
                    _ => _buildListOrTable(context, state.visible),
                  },
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSupplierDropdown(
    BuildContext context,
    ReceiptListState state,
    ReceiptListCubit cubit,
  ) {
    return DropdownButton<String?>(
      value: state.supplierId,
      hint: const Text('Tất cả NCC'),
      underline: const SizedBox.shrink(),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('Tất cả NCC'),
        ),
        for (final s in state.suppliers)
          DropdownMenuItem<String?>(
            value: s.id,
            child: Text(s.name),
          ),
      ],
      onChanged: cubit.setSupplier,
    );
  }

  Widget _buildListOrTable(BuildContext context, List<ReceiptListRow> rows) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWide = screenWidth >= 900;

    if (isWide) {
      const headers = [
        'Số phiếu',
        'Nhà cung cấp',
        'Dòng / Lô',
        'Tổng giá gốc',
        'Ngày nhận',
        'Người nhận',
      ];

      return Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: context.vColors.borderDefault)),
            ),
            children: [
              for (var i = 0; i < headers.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: VSpacing.space3,
                    horizontal: VSpacing.space2,
                  ),
                  child: Text(
                    headers[i],
                    style: VTypography.labelDefault.copyWith(
                      color: context.vColors.textSecondary,
                    ),
                    textAlign: i == 3 ? TextAlign.right : TextAlign.left,
                  ),
                ),
            ],
          ),
          for (final r in rows)
            TableRow(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: context.vColors.borderDefault)),
              ),
              children: [
                InkWell(
                  onTap: () => onOpenDetail(r.receiptId),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: VSpacing.space3,
                      horizontal: VSpacing.space2,
                    ),
                    child: Text(r.receiptNo, style: VTypography.labelDefault),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: VSpacing.space3,
                    horizontal: VSpacing.space2,
                  ),
                  child: Text(r.supplierName),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: VSpacing.space3,
                    horizontal: VSpacing.space2,
                  ),
                  child: Text('${r.lineCount} dòng / ${r.lotCount} lô'),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: VSpacing.space3,
                    horizontal: VSpacing.space2,
                  ),
                  child: Text(
                    '${MoneyFormatter.formatMinorPlain(r.landedTotalVnd)} đ',
                    textAlign: TextAlign.right,
                    style: VTypography.labelDefault.copyWith(
                      color: context.vColors.primary,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: VSpacing.space3,
                    horizontal: VSpacing.space2,
                  ),
                  child: Text(r.businessDate),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: VSpacing.space3,
                    horizontal: VSpacing.space2,
                  ),
                  child: Text(r.createdByName),
                ),
              ],
            ),
        ],
      );
    }

    return Column(
      children: [
        for (final row in rows) ...[
          ReceiptRecordCard(
            row: row,
            onTap: () => onOpenDetail(row.receiptId),
          ),
          const SizedBox(height: VSpacing.space2),
        ],
      ],
    );
  }
}
