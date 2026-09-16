import 'package:erp/features/sales/presentation/bloc/invoice_delivery_history_state.dart';
import 'package:erp/features/sales/presentation/models/invoice_delivery_history_vm.dart';
import 'package:erp/features/sales/presentation/support/order_invoice_delivery_copy.dart';
import 'package:erp/features/sales/presentation/widgets/einvoice/invoice_delivery_history_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_einvoice_domain/domain.dart';

void main() {
  Widget buildSubject(InvoiceDeliveryHistoryState state, {VoidCallback? onRetry}) {
    return MaterialApp(
      theme: VTheme.lightTheme,
      home: Scaffold(
        body: InvoiceDeliveryHistoryView(
          state: state,
          onRetry: onRetry ?? () {},
        ),
      ),
    );
  }

  InvoiceDeliveryHistoryRowVm row({
    required int no,
    required String statusLabel,
    required VComponentTone tone,
    required String actorLabel,
    String email = 'buyer@example.com',
  }) {
    return InvoiceDeliveryHistoryRowVm(
      deliveryId: 'del-$no',
      deliveryNo: no,
      statusLabel: statusLabel,
      recipientEmail: email,
      occurredAt: DateTime(2026, 8, no, 16, 20),
      actorLabel: actorLabel,
      tone: tone,
    );
  }

  group('InvoiceDeliveryHistoryView', () {
    testWidgets('loading shows VLoading', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          const InvoiceDeliveryHistoryState(
            status: InvoiceDeliveryHistoryStatus.loading,
          ),
        ),
      );
      expect(find.byType(VLoading), findsOneWidget);
    });

    testWidgets('empty shows empty copy', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          const InvoiceDeliveryHistoryState(
            status: InvoiceDeliveryHistoryStatus.loaded,
          ),
        ),
      );
      expect(find.text(OrderInvoiceDeliveryCopy.historyEmpty), findsOneWidget);
    });

    testWidgets('loaded shows newest first with actor labels', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          InvoiceDeliveryHistoryState(
            status: InvoiceDeliveryHistoryStatus.loaded,
            displayState: DeliveryDisplayState.sent,
            rows: [
              row(
                no: 3,
                statusLabel: 'Đã gửi',
                tone: VComponentTone.success,
                actorLabel: 'Người dùng',
                email: 'latest@example.com',
              ),
              row(
                no: 1,
                statusLabel: 'Đã gửi',
                tone: VComponentTone.success,
                actorLabel: 'Tự động',
                email: 'first@example.com',
              ),
            ],
          ),
        ),
      );

      expect(find.text(OrderInvoiceDeliveryCopy.historySectionTitle), findsOneWidget);
      expect(find.text('Đã gửi · latest@example.com'), findsOneWidget);
      expect(find.textContaining('Tự động'), findsOneWidget);
      expect(find.textContaining('Người dùng'), findsOneWidget);
      expect(find.textContaining('PROVIDER'), findsNothing);
      expect(find.textContaining('failure'), findsNothing);
      expect(find.textContaining('Kiểm tra'), findsNothing);

      final texts = tester
          .widgetList<VText>(find.byType(VText))
          .map((w) => w.data)
          .whereType<String>()
          .toList();
      final latestIndex = texts.indexWhere((t) => t.contains('latest@example.com'));
      final firstIndex = texts.indexWhere((t) => t.contains('first@example.com'));
      expect(latestIndex, lessThan(firstIndex));
    });

    testWidgets('failure shows retry CTA', (tester) async {
      var retried = 0;
      await tester.pumpWidget(
        buildSubject(
          const InvoiceDeliveryHistoryState(
            status: InvoiceDeliveryHistoryStatus.failure,
            errorMessage: 'Không thể tải lịch sử gửi hóa đơn.',
          ),
          onRetry: () => retried++,
        ),
      );

      expect(find.text(OrderInvoiceDeliveryCopy.historyRetry), findsOneWidget);
      await tester.tap(find.byKey(const Key('action_retry_history')));
      await tester.pump();
      expect(retried, 1);
    });
  });
}
