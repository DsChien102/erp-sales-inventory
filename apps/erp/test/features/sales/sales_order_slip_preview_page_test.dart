import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import 'package:erp/features/sales/data/models.dart';
import 'package:erp/features/sales/presentation.dart';

void main() {
  group('SalesOrderSlipPreviewPage', () {
    testWidgets('renders SalesOrderSlipPreviewPage with receipt preview', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SalesOrderSlipPreviewPage(
            orderId: 'order-1',
            receipt: _receipt(),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('wgt_sales_order_slip_preview_page')), findsOneWidget);
      expect(find.byType(PdfPreview), findsOneWidget);
      expect(find.byKey(const Key('btn_sales_receipt_preview_print')), findsOneWidget);
      expect(find.byKey(const Key('btn_sales_receipt_preview_share')), findsOneWidget);
      expect(find.text('Phiếu bán hàng'), findsWidgets);
    });

    testWidgets('missing typed receipt extra renders invalid-entry never demo content', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/sales/orders/order-1/preview',
        routes: [
          GoRoute(
            path: '/sales/orders/:orderId/preview',
            builder: (context, state) {
              final orderId = state.pathParameters['orderId']!;
              final extra = state.extra;
              if (extra is! SalesReceiptDto) {
                return SalesOrderSlipPreviewPage(orderId: orderId);
              }
              return SalesOrderSlipPreviewPage(orderId: orderId, receipt: extra);
            },
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('wgt_sales_order_slip_invalid_entry')), findsOneWidget);
      expect(find.byKey(const Key('wgt_sales_order_slip_preview_page')), findsNothing);
      expect(find.byType(PdfPreview), findsNothing);
      expect(find.textContaining('demo'), findsNothing);
      expect(find.textContaining('SO-demo'), findsNothing);
    });

    testWidgets('mismatched non-receipt extra renders invalid-entry', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SalesOrderSlipPreviewPage(
            orderId: 'order-1',
            receipt: null,
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('wgt_sales_order_slip_invalid_entry')), findsOneWidget);
      expect(find.byType(PdfPreview), findsNothing);
    });
  });
}

SalesReceiptDto _receipt() => SalesReceiptDto(
  receiptId: 'receipt-1',
  salesOrderId: 'order-1',
  version: 1,
  status: SalesReceiptStatus.generated,
  generatedAt: DateTime.utc(2026, 8, 12, 2, 41),
  document: SalesReceiptDocumentDto(
    receiptNumber: 'PBH-20260812-0001',
    orderNumber: 'SO-0001',
    soldAt: DateTime.utc(2026, 8, 12, 2, 41),
    store: const StoreSnapshotDto(
      storeId: 'store-1',
      storeCode: 'HCM-01',
      displayName: 'Chi nhánh Quận 1',
    ),
    seller: const ActorSnapshotDto(actorId: 'actor-1', displayName: 'Minh Anh'),
    lines: const <SalesReceiptLineDto>[],
    subtotal: const MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
    discountTotal: const MoneyDto(amountMinor: 0, currencyCode: 'VND'),
    orderTotal: const MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
    paidTotal: const MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
    outstandingTotal: const MoneyDto(amountMinor: 0, currencyCode: 'VND'),
    payments: const <PaymentIntentSummaryDto>[],
  ),
);
