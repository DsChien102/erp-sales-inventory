import 'package:erp/features/einvoice/data/models.dart';
import 'package:erp/features/einvoice/logic/order_einvoice_idempotency_key_factory.dart';
import 'package:erp/features/einvoice/logic/order_invoice_delivery_cubit.dart';
import 'package:erp/features/einvoice/presentation/pages/invoice_delivery_history_page.dart';
import 'package:erp/features/einvoice/presentation/support/order_invoice_delivery_copy.dart';
import 'package:erp/features/einvoice/presentation/widgets/resend_invoice_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';

import '../../support/fake_einvoice_repository.dart';

void main() {
  late FakeEInvoiceRepository repository;

  setUp(() {
    repository = FakeEInvoiceRepository();
  });

  testWidgets('page loads history and back pops to source', (tester) async {
    repository.history = InvoiceDeliveryHistoryDto(
      deliveries: [
        InvoiceDeliveryItemDto(
          deliveryId: 'del-1',
          deliveryNo: 1,
          kind: DeliveryKind.initial,
          triggerType: DeliveryTriggerType.automatic,
          recipientEmail: 'buyer@example.com',
          status: DeliveryStatus.succeeded,
          initiatedByActorType: DeliveryActorType.system,
          initiatedByActorId: null,
          startedAt: DateTime.utc(2026, 8, 1, 9),
          completedAt: DateTime.utc(2026, 8, 1, 9),
          failureCode: null,
        ),
      ],
      displayState: DeliveryDisplayState.sent,
      hasSecondaryAttention: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: VButton(
                label: 'Open',
                onPressed: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => InvoiceDeliveryHistoryPage(
                        salesOrderId: 'order-101',
                        repository: repository,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text(OrderInvoiceDeliveryCopy.historyPageTitle), findsOneWidget);
    expect(find.textContaining('buyer@example.com'), findsOneWidget);
    expect(
      repository.calls.where((c) => c == 'getDeliveryHistory'),
      hasLength(1),
    );

    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is VIcon &&
            (widget.icon == VIcons.chevronLeft || widget.icon == VIcons.arrowBack),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets(
    'pop history restores resend sheet with edited email intact',
    (tester) async {
      final sheetContext = SendInvoiceSheetContextDto(
        mode: SendInvoiceSheetMode.resend,
        suggestedEmail: 'original@example.com',
        suggestedEmailSource: DeliveryRecipientSource.lastInvoiceDelivery,
        history: [
          InvoiceDeliveryItemDto(
            deliveryId: 'del-1',
            deliveryNo: 1,
            kind: DeliveryKind.initial,
            triggerType: DeliveryTriggerType.manual,
            recipientEmail: 'original@example.com',
            status: DeliveryStatus.succeeded,
            initiatedByActorType: DeliveryActorType.user,
            initiatedByActorId: 'actor-test',
            startedAt: DateTime.utc(2026, 8, 5, 9, 20),
            completedAt: DateTime.utc(2026, 8, 5, 9, 20),
            failureCode: null,
          ),
        ],
        operationLocked: false,
        displayState: DeliveryDisplayState.sent,
      );

      repository.sendContext = sheetContext;
      repository.history = const InvoiceDeliveryHistoryDto(
        deliveries: [],
        displayState: DeliveryDisplayState.sent,
        hasSecondaryAttention: false,
      );

      final deliveryCubit = OrderInvoiceDeliveryCubit(
        salesOrderId: 'order-101',
        repository: repository,
        idempotencyKeyFactory: DeterministicOrderEInvoiceIdempotencyKeyFactory(
          const ['k1'],
        ),
      );
      addTearDown(deliveryCubit.close);
      await deliveryCubit.loadContext();

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: BlocProvider.value(
              value: deliveryCubit,
              child: OrderInvoiceResendSheet(
                sheetContext: sheetContext,
                onViewHistory: (sheetCtx) => Navigator.of(sheetCtx).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => InvoiceDeliveryHistoryPage(
                      salesOrderId: 'order-101',
                      repository: repository,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('field_recipient_email')),
        'edited@example.com',
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('action_view_delivery_history')));
      await tester.pumpAndSettle();
      expect(find.text(OrderInvoiceDeliveryCopy.historyPageTitle), findsOneWidget);

      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is VIcon &&
              (widget.icon == VIcons.chevronLeft || widget.icon == VIcons.arrowBack),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OrderInvoiceResendSheet), findsOneWidget);
      expect(find.text('edited@example.com'), findsOneWidget);
    },
  );
}
