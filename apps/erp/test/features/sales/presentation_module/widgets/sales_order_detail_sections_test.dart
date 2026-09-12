import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/features/sales/presentation.dart';
import 'package:erp/core/formatting/money_formatter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SalesOrderDetail S17–S18 section widgets', () {
    testWidgets('payment debt shows method amounts and due date from payment vm', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SalesOrderPaymentDebtPage(
            orderNumber: 'SO-2026-00125',
            customerName: 'Đại lý An Bình',
            payment: _paymentVm(),
          ),
        ),
      );

      expect(find.byKey(const Key('wgt_sg08_payment_debt_page')), findsOneWidget);
      expect(find.byKey(const Key('wgt_sg08_payment_debt_context')), findsOneWidget);
      expect(find.text('Tình trạng hiện tại'), findsOneWidget);
      expect(find.text('Tổng đơn'), findsWidgets);
      expect(find.text('Đã thanh toán (TM)'), findsOneWidget);
      expect(find.text(MoneyFormatter.formatMinor(400000)), findsWidgets);
      expect(find.text('Đã thanh toán (CK)'), findsOneWidget);
      expect(find.text(MoneyFormatter.formatMinor(600000)), findsWidgets);
      expect(find.text('Hẹn thanh toán'), findsOneWidget);
      expect(find.text('30/08/2026'), findsOneWidget);
      expect(find.textContaining('#DT-00018'), findsNothing);
    });

    testWidgets('payment debt cash-only omits CK row with zero bank amount', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SalesOrderPaymentDebtPage(
            orderNumber: 'SO-2026-00125',
            customerName: 'Đại lý An Bình',
            payment: _paymentVm(
              paidCashAmountMinor: 1000000,
              paidBankAmountMinor: 0,
              paidTotalMinor: 1000000,
              outstandingMinor: 250000,
            ),
          ),
        ),
      );

      expect(find.text('Đã thanh toán (TM)'), findsOneWidget);
      expect(find.text('Đã thanh toán (CK)'), findsNothing);
      expect(find.text(MoneyFormatter.formatMinor(0)), findsNothing);
    });

    testWidgets('payment debt hides post-return breakdown when dto omits it', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SalesOrderPaymentDebtPage(
            orderNumber: 'SO-2026-00125',
            customerName: 'Đại lý An Bình',
            payment: _paymentVm(),
          ),
        ),
      );

      expect(find.text('Từ đơn hàng gốc'), findsNothing);
      expect(find.textContaining('Từ phiếu đổi/trả'), findsNothing);
      expect(find.text('#DT-00018'), findsNothing);
    });

    testWidgets('cancellation card shows compact reason, actor and cancelled time', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SalesOrderDetailCancelReasonCard(
              status: SalesOrderDetailSectionStatus.loaded,
              cancellation: SalesOrderCancellationVm(
                cancellationId: 'cancel-1',
                reason: 'Khách không nhận hàng',
                statusLabel: 'Đã hủy',
                isProcessing: false,
                cancelledByActorId: 'aac53c36-94ce-4da1-810a-8988eb860ca9',
                cancelledByActorName: 'Minh Anh',
                cancelledAtFormatted: '22/07/2026 10:15',
                netConfirmedCollectionFormatted: '0đ',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Lý do hủy'), findsOneWidget);
      expect(find.text('Khách không nhận hàng'), findsOneWidget);
      expect(find.text('Minh Anh · 22/07/2026 10:15'), findsOneWidget);
      expect(find.textContaining('aac53c36-94ce-4da1-810a-8988eb860ca9'), findsNothing);
      expect(find.text('Đã hủy'), findsNothing);
      expect(find.textContaining('Thực thu tại thời điểm hủy'), findsNothing);
    });

    for (final reason in ['', '   ']) {
      testWidgets('cancellation card hides absent reason "$reason"', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SalesOrderDetailCancelReasonCard(
                status: SalesOrderDetailSectionStatus.loaded,
                cancellation: SalesOrderCancellationVm(
                  cancellationId: 'cancel-1',
                  reason: reason,
                  statusLabel: 'Đã hủy',
                  isProcessing: false,
                  cancelledByActorId: 'actor-1',
                  cancelledByActorName: 'Minh Anh',
                  cancelledAtFormatted: '22/07/2026 10:15',
                  netConfirmedCollectionFormatted: '0đ',
                ),
              ),
            ),
          ),
        );
        expect(find.byKey(const Key('card_sg08_cancellation')), findsNothing);
        expect(find.text('Lý do hủy'), findsNothing);
      });
    }

    testWidgets('payment debt shows post-return breakdown when dto provides it', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SalesOrderPaymentDebtPage(
            orderNumber: 'DH-000129',
            customerName: 'Nguyễn Văn An',
            payment: _paymentVmWithBreakdown(),
          ),
        ),
      );

      expect(find.text('Từ đơn hàng gốc'), findsOneWidget);
      expect(find.textContaining('Từ phiếu đổi/trả #DT-00018'), findsOneWidget);
      expect(find.text('Khách trả thêm'), findsOneWidget);
      expect(find.text('Đã thu thêm (CK)'), findsOneWidget);
    });

    testWidgets('history page renders authoritative timeline timestamps and actors', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SalesOrderHistoryPage(
            orderNumber: 'SO-2026-00125',
            customerName: 'Đại lý An Bình',
            history: _historyVm(),
          ),
        ),
      );

      expect(find.byKey(const Key('wgt_sg08_history_page')), findsOneWidget);
      expect(find.textContaining('Xác nhận đơn hàng'), findsOneWidget);
      expect(find.textContaining('Minh Anh'), findsOneWidget);
      expect(find.textContaining('12/08/2026 10:15'), findsOneWidget);
    });

    testWidgets('history page matches mobile header and localizes event codes', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SalesOrderHistoryPage(
            orderNumber: 'DH-000129',
            customerName: 'Nguyễn Văn An',
            history: _codedHistoryVm(),
          ),
        ),
      );

      expect(find.byKey(const Key('btn_sg08_history_back')), findsOneWidget);
      expect(find.byKey(const Key('wgt_sg08_history_context')), findsOneWidget);
      expect(find.text('DH-000129 · Nguyễn Văn An'), findsOneWidget);
      expect(find.text('ORDER_COMPLETED'), findsNothing);
      expect(find.text('PAYMENT_CASH_RECORDED'), findsNothing);
      expect(find.text('RECEIPT_PRINTED'), findsNothing);
      expect(find.text('RETURN_EXCHANGE_COMPLETED'), findsNothing);
      expect(find.text('Hoàn tất đơn hàng'), findsOneWidget);
      expect(find.text('Ghi nhận thanh toán tiền mặt'), findsOneWidget);
      expect(find.text('In phiếu bán hàng'), findsOneWidget);
      expect(find.text('Hoàn tất đổi/trả #DT-00018'), findsOneWidget);
    });

    testWidgets('history page localizes english descriptions and versioned event types', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SalesOrderHistoryPage(
            orderNumber: 'DH-000129',
            customerName: 'Nguyễn Văn An',
            history: _englishHistoryVm(),
          ),
        ),
      );

      expect(find.text('Sales order completed'), findsNothing);
      expect(find.text('sales_order_finalized.v1'), findsNothing);
      expect(find.textContaining('aac53c36-94ce-4da1-810a-8988eb860ca9'), findsNothing);
      expect(find.text('payment_cash_recorded.v1'), findsNothing);
      expect(find.text('receipt_printed.v1'), findsNothing);
      expect(find.text('return_exchange_completed.v1'), findsNothing);
      expect(find.text('Hoàn tất đơn hàng'), findsNWidgets(2));
      expect(find.textContaining('Nhân viên'), findsOneWidget);
      expect(find.text('Ghi nhận thanh toán tiền mặt'), findsOneWidget);
      expect(find.text('In phiếu bán hàng'), findsOneWidget);
      expect(find.text('Hoàn tất đổi/trả #DT-00019'), findsOneWidget);
    });

    testWidgets('history page localizes dotted cancellation event types', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SalesOrderHistoryPage(
            orderNumber: 'DH-202608170004',
            customerName: 'Bùi Thị Ích',
            history: _dottedCancellationHistoryVm(),
          ),
        ),
      );

      expect(find.text('sales.order.cancellation_confirmed'), findsNothing);
      expect(find.text('sales.order.pricing_reversal_requested'), findsNothing);
      expect(find.text('sales.order.reporting_cancellation_recorded'), findsNothing);
      expect(find.text('sales.order.cancelled'), findsNothing);
      expect(find.text('Xác nhận hủy đơn hàng'), findsOneWidget);
      expect(find.text('Yêu cầu hoàn tác giá bán'), findsOneWidget);
      expect(find.text('Ghi nhận báo cáo hủy đơn'), findsOneWidget);
      expect(find.text('Hủy đơn hàng'), findsOneWidget);
    });

    testWidgets('history page uses fallback actor name instead of uuid', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SalesOrderHistoryPage(
            orderNumber: 'DH-000129',
            customerName: 'Nguyễn Văn An',
            fallbackActorName: 'Minh Anh',
            history: _englishHistoryVm(),
          ),
        ),
      );

      expect(find.textContaining('aac53c36-94ce-4da1-810a-8988eb860ca9'), findsNothing);
      expect(find.textContaining('Minh Anh · 14/08/2026 05:02'), findsOneWidget);
      expect(find.textContaining('Nhân viên · 14/08/2026 05:02'), findsNothing);
    });

    testWidgets('history page localizes settlement changed and unknown actor fallback', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SalesOrderHistoryPage(
            orderNumber: 'DH202609100002',
            customerName: 'Khách lẻ',
            fallbackActorName: 'Đỗ Sỹ Chiến',
            history: const SalesOrderHistoryVm(
              timeline: [
                SalesOrderDetailTimelineVm(
                  title: 'sales_order_finalized.v1',
                  timestamp: '10/09/2026 11:58',
                  actorName: 'Đỗ Sỹ Chiến',
                ),
                SalesOrderDetailTimelineVm(
                  title: 'sales_settlement_changed.v1',
                  timestamp: '10/09/2026 11:58',
                  actorName: 'Không rõ',
                ),
              ],
              returns: [],
            ),
          ),
        ),
      );

      expect(find.text('sales_settlement_changed.v1'), findsNothing);
      expect(find.text('Không rõ · 10/09/2026 11:58'), findsNothing);
      expect(find.text('Hoàn tất đơn hàng'), findsOneWidget);
      expect(find.text('Cập nhật quyết toán'), findsOneWidget);
      expect(find.text('Đỗ Sỹ Chiến · 10/09/2026 11:58'), findsNWidgets(2));
    });

    testWidgets('return list uses real reference status difference and omits sample pdf', (
      tester,
    ) async {
      String? openedReturnId;
      await tester.pumpWidget(
        MaterialApp(
          home: SalesOrderReturnListPage(
            orderId: 'order-1',
            orderNumber: 'SO-2026-00125',
            customerName: 'Đại lý An Bình',
            returns: _historyVm().returns,
            onOpenReturnDetail: (returnExchangeId) {
              openedReturnId = returnExchangeId;
            },
          ),
        ),
      );

      expect(find.byKey(const Key('wgt_sg08_return_list_page')), findsOneWidget);
      expect(find.textContaining('DT-2026-00042'), findsOneWidget);
      expect(find.textContaining('Hoàn tất'), findsOneWidget);
      expect(find.textContaining('Khách trả thêm'), findsOneWidget);
      expect(find.textContaining('#DT-00018'), findsNothing);

      await tester.tap(find.textContaining('DT-2026-00042'));
      await tester.pumpAndSettle();
      expect(openedReturnId, 're-42');
      expect(find.text('In phiếu đổi/trả'), findsNothing);
    });

    testWidgets('payment summary card uses payment section amounts when loaded', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: SalesOrderDetailPaymentSummaryCard(
              data: const SalesOrderDetailPaymentDisplayData(
                paidMinor: 1000000,
                outstandingMinor: 250000,
                enabled: true,
              ),
              status: SalesOrderDetailSectionStatus.loaded,
              onTap: () {},
              onRetry: () {},
            ),
          ),
        ),
      );

      expect(find.text('Thanh toán & công nợ'), findsOneWidget);
      expect(find.textContaining(MoneyFormatter.formatMinor(1000000)), findsOneWidget);
      expect(find.textContaining(MoneyFormatter.formatMinor(250000)), findsOneWidget);
    });

    testWidgets('payment summary card shows section error instead of empty success', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: SalesOrderDetailPaymentSummaryCard(
              status: SalesOrderDetailSectionStatus.error,
              errorMessage: 'pay down',
              onTap: () {},
              onRetry: () {},
            ),
          ),
        ),
      );

      expect(find.text('Đã thanh toán ${MoneyFormatter.formatMinor(0)}'), findsNothing);
      expect(find.textContaining('pay down'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);
    });

    testWidgets('returns section shows projection pending retry instead of empty slips', (
      tester,
    ) async {
      var retried = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: SalesOrderDetailReturnsSection(
              slips: const [],
              status: SalesOrderDetailSectionStatus.projectionPending,
              onTap: () {},
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      expect(find.textContaining('0 phiếu'), findsNothing);
      expect(find.textContaining('đồng bộ'), findsOneWidget);
      await tester.tap(find.text('Thử lại'));
      expect(retried, isTrue);
    });

    testWidgets('returns section loaded uses entry row subtitle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: SalesOrderDetailReturnsSection(
              slips: _historyVm().returns,
              status: SalesOrderDetailSectionStatus.loaded,
              onTap: () {},
              onRetry: () {},
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('btn_sg08_returns_entry')), findsOneWidget);
      expect(find.textContaining('1 phiếu · Mới nhất'), findsOneWidget);
    });

    testWidgets('history entry navigates label matches Figma copy', (tester) async {
      var opened = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: SalesOrderDetailHistoryEntry(
              status: SalesOrderDetailSectionStatus.loaded,
              onTap: () => opened = true,
              onRetry: () {},
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('btn_sg08_history_entry')), findsOneWidget);
      expect(find.text('Xem thanh toán và các hoạt động của đơn'), findsOneWidget);
      await tester.tap(find.byKey(const Key('btn_sg08_history_entry')));
      expect(opened, isTrue);
    });

    testWidgets('products section uses grouped surface', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: SalesOrderDetailProductsSection(
              items: const [
                SalesOrderDetailItemVm(
                  lineId: 'line-1',
                  productName: 'Vaccine A',
                  unitName: 'Lọ',
                  quantity: 1,
                  unitPriceMinor: 100000,
                  totalAmountMinor: 100000,
                ),
                SalesOrderDetailItemVm(
                  lineId: 'line-2',
                  productName: 'Vaccine B',
                  unitName: 'Hộp',
                  quantity: 2,
                  unitPriceMinor: 50000,
                  totalAmountMinor: 100000,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('wgt_sg08_products_grouped')), findsOneWidget);
      expect(find.text('Vaccine A'), findsOneWidget);
      expect(find.text('Vaccine B'), findsOneWidget);
    });

    testWidgets('products section renders strikethrough original price when discounted', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: const Scaffold(
            body: SalesOrderDetailProductsSection(
              items: [
                SalesOrderDetailItemVm(
                  lineId: 'line-1',
                  productName: 'AD3EC 5L',
                  unitName: 'Can',
                  quantity: 2,
                  originalUnitPriceMinor: 2500000,
                  unitPriceMinor: 2350000,
                  totalAmountMinor: 4700000,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('2 Can × '), findsOneWidget);
      expect(find.text(MoneyFormatter.formatMinor(2500000)), findsOneWidget);
      expect(find.text(MoneyFormatter.formatMinor(2350000)), findsOneWidget);
      expect(find.text(MoneyFormatter.formatMinor(4700000)), findsOneWidget);
    });

    testWidgets('documents section uses grouped surface with hub rows', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: SalesOrderDetailDocumentsSection(
              isCancelled: false,
              eInvoiceStatus: SalesEInvoiceStatus.notIssued,
              historyStatus: SalesOrderDetailSectionStatus.loaded,
              returnSlips: _historyVm().returns,
              onOpenReceipt: () {},
              onOpenEInvoice: () {},
              onOpenReturnList: () {},
              onOpenHistory: () {},
              onRetryHistory: () {},
              showHistory: true,
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('wgt_sg08_documents_grouped')), findsOneWidget);
      expect(find.byKey(const Key('btn_sg08_receipt')), findsOneWidget);
      expect(find.byKey(const Key('btn_sg08_einvoice')), findsOneWidget);
      expect(find.byKey(const Key('btn_sg08_returns_entry')), findsOneWidget);
      expect(find.byKey(const Key('btn_sg08_history_entry')), findsOneWidget);
    });

    testWidgets('documents section cancelled shows only returns and history rows', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: SalesOrderDetailDocumentsSection(
              isCancelled: true,
              eInvoiceStatus: SalesEInvoiceStatus.notIssued,
              historyStatus: SalesOrderDetailSectionStatus.loaded,
              returnSlips: const [],
              onOpenReceipt: () {},
              onOpenEInvoice: () {},
              onOpenReturnList: () {},
              onOpenHistory: () {},
              onRetryHistory: () {},
              showHistory: true,
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('btn_sg08_receipt')), findsNothing);
      expect(find.byKey(const Key('btn_sg08_einvoice')), findsNothing);
      expect(find.byKey(const Key('btn_sg08_returns_entry')), findsNothing);
      expect(find.byKey(const Key('btn_sg08_history_entry')), findsOneWidget);
    });

    testWidgets('payment summary loaded key', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: SalesOrderDetailPaymentSummaryCard(
              data: const SalesOrderDetailPaymentDisplayData(
                paidMinor: 1000000,
                outstandingMinor: 250000,
                enabled: true,
              ),
              status: SalesOrderDetailSectionStatus.loaded,
              onTap: () {},
              onRetry: () {},
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('wgt_sg08_payment')), findsOneWidget);
    });

    testWidgets('payment summary disabled uses muted styling key', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: SalesOrderDetailPaymentSummaryCard(
              data: const SalesOrderDetailPaymentDisplayData(
                paidMinor: 1000000,
                outstandingMinor: 0,
                enabled: false,
              ),
              status: SalesOrderDetailSectionStatus.loaded,
              onTap: () {},
              onRetry: () {},
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('wgt_sg08_payment')), findsOneWidget);
    });

    testWidgets('history page renders timeline connector key', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SalesOrderHistoryPage(
            orderNumber: 'SO-2026-00125',
            customerName: 'Đại lý An Bình',
            history: _historyVm(),
          ),
        ),
      );

      expect(find.byKey(const Key('wgt_sg08_history_timeline')), findsOneWidget);
    });
  });
}

SalesOrderPaymentVm _paymentVm({
  int paidCashAmountMinor = 400000,
  int paidBankAmountMinor = 600000,
  int paidTotalMinor = 1000000,
  int outstandingMinor = 250000,
}) {
  return SalesOrderPaymentVm(
    orderTotalMinor: 1250000,
    paidTotalMinor: paidTotalMinor,
    outstandingMinor: outstandingMinor,
    paidCashAmountMinor: paidCashAmountMinor,
    paidBankAmountMinor: paidBankAmountMinor,
    dueDateFormatted: '30/08/2026',
    settlementStatus: SalesSettlementStatus.partiallyPaid,
    transactions: [
      if (paidCashAmountMinor > 0)
        SalesOrderPaymentTransactionVm(
          transactionId: 'tx-1',
          methodLabel: 'Tiền mặt',
          amountMinor: paidCashAmountMinor,
          recordedAtFormatted: '12/08/2026 03:20',
        ),
      if (paidBankAmountMinor > 0)
        SalesOrderPaymentTransactionVm(
          transactionId: 'tx-2',
          methodLabel: 'Chuyển khoản',
          amountMinor: paidBankAmountMinor,
          recordedAtFormatted: '12/08/2026 03:21',
        ),
    ],
    hasMoreTransactions: false,
  );
}

SalesOrderPaymentVm _paymentVmWithBreakdown() {
  return SalesOrderPaymentVm(
    orderTotalMinor: 4700000,
    paidTotalMinor: 3372619,
    outstandingMinor: 1327381,
    paidCashAmountMinor: 2000000,
    paidBankAmountMinor: 1372619,
    dueDateFormatted: '30/07/2026',
    settlementStatus: SalesSettlementStatus.partiallyPaid,
    transactions: const [],
    hasMoreTransactions: false,
    originalOrderBreakdown: const SalesOrderPaymentOriginalBreakdownVm(
      orderTotalMinor: 4445238,
      paidCashMinor: 2000000,
      paidBankMinor: 1222619,
      outstandingMinor: 1222619,
    ),
    returnSlipBreakdowns: const [
      SalesOrderPaymentReturnSlipBreakdownVm(
        slipNumber: 'DT-00018',
        customerPaysExtraMinor: 254762,
        paidBankExtraMinor: 150000,
      ),
    ],
  );
}

SalesOrderHistoryVm _historyVm() {
  return const SalesOrderHistoryVm(
    timeline: [
      SalesOrderDetailTimelineVm(
        title: 'Xác nhận đơn hàng',
        timestamp: '12/08/2026 10:15',
        actorName: 'Minh Anh',
        description: 'Xác nhận đơn hàng',
        amountMinor: 1250000,
      ),
    ],
    returns: [
      SalesReturnExchangeSlipItemVm(
        returnExchangeId: 're-42',
        slipNumber: 'DT-2026-00042',
        typeText: 'Đổi/trả',
        dateFormatted: '14/08/2026 09:30',
        statusText: 'Hoàn tất',
        diffText: 'Khách trả thêm 150.000đ',
      ),
    ],
  );
}

SalesOrderHistoryVm _codedHistoryVm() {
  return const SalesOrderHistoryVm(
    timeline: [
      SalesOrderDetailTimelineVm(
        title: 'ORDER_COMPLETED',
        timestamp: '22/07/2026 09:41',
        actorName: 'Minh Anh',
        description: 'ORDER_COMPLETED',
      ),
      SalesOrderDetailTimelineVm(
        title: 'PAYMENT_CASH_RECORDED',
        timestamp: '22/07/2026 09:41',
        actorName: 'Minh Anh',
        description: 'PAYMENT_CASH_RECORDED',
      ),
      SalesOrderDetailTimelineVm(
        title: 'RECEIPT_PRINTED',
        timestamp: '22/07/2026 09:45',
        actorName: 'Minh Anh',
        description: 'RECEIPT_PRINTED',
      ),
      SalesOrderDetailTimelineVm(
        title: 'RETURN_EXCHANGE_COMPLETED',
        timestamp: '22/07/2026 10:18',
        actorName: 'Minh Anh',
        description: '#DT-00018',
      ),
    ],
    returns: [],
  );
}

SalesOrderHistoryVm _dottedCancellationHistoryVm() {
  return const SalesOrderHistoryVm(
    timeline: [
      SalesOrderDetailTimelineVm(
        title: 'sales.order.cancellation_confirmed',
        timestamp: '17/08/2026 07:43',
        actorName: 'Đỗ Sỹ Chiến',
      ),
      SalesOrderDetailTimelineVm(
        title: 'sales.order.pricing_reversal_requested',
        timestamp: '17/08/2026 07:43',
        actorName: 'Đỗ Sỹ Chiến',
      ),
      SalesOrderDetailTimelineVm(
        title: 'sales.order.reporting_cancellation_recorded',
        timestamp: '17/08/2026 07:43',
        actorName: 'Đỗ Sỹ Chiến',
      ),
      SalesOrderDetailTimelineVm(
        title: 'sales.order.cancelled',
        timestamp: '17/08/2026 07:43',
        actorName: 'Đỗ Sỹ Chiến',
      ),
    ],
    returns: [],
  );
}

SalesOrderHistoryVm _englishHistoryVm() {
  return const SalesOrderHistoryVm(
    timeline: [
      SalesOrderDetailTimelineVm(
        title: 'sales_order_finalized.v1',
        timestamp: '14/08/2026 05:02',
        actorName: 'aac53c36-94ce-4da1-810a-8988eb860ca9',
      ),
      SalesOrderDetailTimelineVm(
        title: 'Sales order completed',
        timestamp: '22/07/2026 09:41',
        actorName: 'Minh Anh',
        description: 'Sales order completed',
      ),
      SalesOrderDetailTimelineVm(
        title: 'payment_cash_recorded.v1',
        timestamp: '22/07/2026 09:41',
        actorName: 'Minh Anh',
        description: 'Payment cash recorded',
      ),
      SalesOrderDetailTimelineVm(
        title: 'receipt_printed.v1',
        timestamp: '22/07/2026 09:45',
        actorName: 'Minh Anh',
        description: 'Receipt printed',
      ),
      SalesOrderDetailTimelineVm(
        title: 'return_exchange_completed.v1',
        timestamp: '22/07/2026 10:18',
        actorName: 'Minh Anh',
        description: '#DT-00019',
      ),
    ],
    returns: [],
  );
}
