import 'package:flutter/material.dart';
import 'package:erp/features/sales/presentation.dart';

import 'fixtures.dart';
import 'preview_helpers.dart';
import 'preview_section.dart';
import 'sales_return_exchange_settlement_preview_section.dart';

class SalesSg12SettlementTab extends StatelessWidget {
  const SalesSg12SettlementTab({super.key});

  @override
  Widget build(BuildContext context) {
    return previewList([
      const SalesReturnExchangeSettlementPreviewSection(),
      PreviewSection(
        title: 'showSalesReturnConfirmSettlementSheet',
        child: PreviewActionButton(
          label: 'Xác nhận quyết toán (refund)',
          onPressed: () => showSalesReturnConfirmSettlementSheet(
            context,
            vm: SalesPreviewFixtures.settlementRefund,
          ),
        ),
      ),
    ]);
  }
}
