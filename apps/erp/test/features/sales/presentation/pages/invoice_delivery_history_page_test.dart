import 'dart:async';

import 'package:erp/features/sales/presentation/pages/invoice_delivery_history_page.dart';
import 'package:erp/features/sales/presentation/support/order_invoice_delivery_copy.dart';
import 'package:erp/features/sales/presentation/widgets/einvoice/resend_invoice_sheet.dart';
import 'package:erp/features/sales/presentation/bloc/order_invoice_delivery_cubit.dart';
import 'package:erp/features/sales/presentation/support/order_einvoice_idempotency_key_factory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

final class _RecordingMediator implements IModuleMediator {
  final List<dynamic> queries = [];
  Object? historyResult;
  Object? sheetContextResult;
  Completer<Object?>? historyGate;

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    throw UnimplementedError();
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    queries.add(query);
    if (query is GetInvoiceDeliveryHistoryQuery) {
      if (historyGate != null) {
        return (await historyGate!.future) as TResult;
      }
      if (historyResult != null) return historyResult as TResult;
    }
    if (query is GetSendInvoiceSheetContextQuery && sheetContextResult != null) {
      return sheetContextResult as TResult;
    }
    return null as TResult;
  }
}

void main() {
  late FakeExecutionContext executionContext;
  late _RecordingMediator mediator;

  setUp(() {
    executionContext = FakeExecutionContext(
      tenantId: 'tenant-test',
      userId: 'actor-test',
    );
    mediator = _RecordingMediator();
  });

  testWidgets('page loads history and back pops to source', (tester) async {
    mediator.historyResult = InvoiceDeliveryHistoryDto(
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
                        mediator: mediator,
                        executionContext: executionContext,
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
      mediator.queries.whereType<GetInvoiceDeliveryHistoryQuery>(),
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

      mediator.sheetContextResult = sheetContext;
      mediator.historyResult = const InvoiceDeliveryHistoryDto(
        deliveries: [],
        displayState: DeliveryDisplayState.sent,
        hasSecondaryAttention: false,
      );

      final deliveryCubit = OrderInvoiceDeliveryCubit(
        salesOrderId: 'order-101',
        executionContext: executionContext,
        mediator: mediator,
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
                      mediator: mediator,
                      executionContext: executionContext,
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
