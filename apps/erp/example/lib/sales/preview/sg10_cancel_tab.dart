import 'package:flutter/material.dart';
import 'package:erp/features/sales/presentation.dart';

import 'fixtures.dart';
import 'preview_helpers.dart';
import 'preview_section.dart';

class SalesSg10CancelTab extends StatelessWidget {
  const SalesSg10CancelTab({super.key});

  @override
  Widget build(BuildContext context) {
    return previewList([
      PreviewSection(
        title: 'SalesOrderDetailCancelReasonCard',
        child: Column(
          children: [
            PreviewStateRow(
              label: 'Loading',
              child: SalesOrderDetailCancelReasonCard(
                cancellation: null,
                status: SalesOrderDetailSectionStatus.loading,
              ),
            ),
            PreviewStateRow(
              label: 'Loaded',
              child: SalesOrderDetailCancelReasonCard(
                cancellation: SalesPreviewFixtures.cancellation,
                status: SalesOrderDetailSectionStatus.loaded,
              ),
            ),
            PreviewStateRow(
              label: 'Error',
              child: SalesOrderDetailCancelReasonCard(
                cancellation: null,
                status: SalesOrderDetailSectionStatus.error,
                errorMessage: 'Không tải được lý do hủy',
                onRetry: () {},
              ),
            ),
          ],
        ),
      ),
      PreviewSection(
        title: 'SalesOrderCancelSheet',
        description: 'SG-10 không có ERP page — hủy từ chi tiết đơn.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PreviewActionButton(
              label: 'Mở sheet hủy đơn',
              onPressed: () => showSalesOrderCancelSheet(
                context,
                vm: SalesPreviewFixtures.orderDetail,
                onConfirmCancel: (reason, note) async => true,
              ),
            ),
            PreviewStateRow(
              label: 'Embedded sheet body',
              child: PreviewEmbedFrame(
                height: 360,
                child: SingleChildScrollView(
                  child: SalesOrderCancelSheet(
                    vm: SalesPreviewFixtures.orderDetail,
                    onConfirmCancel: (reason, note) async => true,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ]);
  }
}
