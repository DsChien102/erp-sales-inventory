import 'package:flutter/material.dart';
import 'package:vet45_sales_application/application.dart'
    hide SalesSettlementStatus, SalesOrderLifecycleStatus;
import 'package:erp/features/sales/presentation.dart'
    hide SalesOrderLifecycleStatus;

import 'fixtures.dart';
import 'preview_helpers.dart';
import 'preview_section.dart';
import 'sales_return_exchange_detail_preview_section.dart';

class SalesSg13ReturnResultTab extends StatelessWidget {
  const SalesSg13ReturnResultTab({super.key});

  @override
  Widget build(BuildContext context) {
    final detail = SalesPreviewFixtures.returnDetail();
    final returnLines = detail.lines
        .where((line) => line.kind == ReturnExchangeLineKind.returnLine)
        .toList();
    final exchangeLines = detail.lines
        .where((line) => line.kind == ReturnExchangeLineKind.exchangeLine)
        .toList();

    return previewList([
      const SalesReturnExchangeDetailPreviewSection(),
      PreviewSection(
        title: 'SalesReturnExchangeDetailHeaderCard',
        child: SalesReturnExchangeDetailHeaderCard(
          detail: detail,
          customerDisplayName: 'Nguyễn Văn An',
          customerPhone: '0903000111',
        ),
      ),
      PreviewSection(
        title: 'SalesReturnExchangeSourceOrderCard',
        child: SalesReturnExchangeSourceOrderCard(
          orderNumber: 'DH-000129',
          onTap: () {},
        ),
      ),
      PreviewSection(
        title: 'SalesReturnExchangeDetailLinesSection',
        child: SalesReturnExchangeDetailLinesSection(
          returnLines: returnLines,
          exchangeLines: exchangeLines,
        ),
      ),
      PreviewSection(
        title: 'SalesReturnExchangeDetailSummaryCard',
        child: SalesReturnExchangeDetailSummaryCard(detail: detail),
      ),
      PreviewSection(
        title: 'SalesReturnResultActionBar',
        child: SalesReturnResultActionBar(
          onGoHome: () {},
          onViewOrderDetail: () {},
        ),
      ),
    ]);
  }
}
