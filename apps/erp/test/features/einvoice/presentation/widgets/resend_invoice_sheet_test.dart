import 'dart:async';

import 'package:erp/features/einvoice/logic/order_einvoice_idempotency_key_factory.dart';
import 'package:erp/features/einvoice/logic/order_invoice_delivery_cubit.dart';
import 'package:erp/features/einvoice/presentation/support/order_invoice_delivery_copy.dart';
import 'package:erp/features/einvoice/presentation/widgets/resend_invoice_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

final class _RecordingMediator implements IModuleMediator {
  final List<dynamic> commands = [];
  final List<dynamic> queries = [];

  Object? commandResult;
  Future<Object?>? commandResultFuture;
  Object? queryResult;
  Exception? errorToThrow;

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) async {
    commands.add(command);
    if (errorToThrow != null) throw errorToThrow!;
    if (commandResultFuture != null) {
      return (await commandResultFuture) as TResult;
    }
    if (commandResult != null) return commandResult as TResult;
    return null as TResult;
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    queries.add(query);
    if (errorToThrow != null) throw errorToThrow!;
    if (queryResult != null) return queryResult as TResult;
    return null as TResult;
  }
}

void main() {
  late FakeExecutionContext executionContext;
  late _RecordingMediator mediator;
  late DeterministicOrderEInvoiceIdempotencyKeyFactory keys;

  setUp(() {
    executionContext = FakeExecutionContext(
      tenantId: 'tenant-test',
      userId: 'actor-test',
    );
    mediator = _RecordingMediator();
    keys = DeterministicOrderEInvoiceIdempotencyKeyFactory(const [
      'key-1',
      'key-2',
      'key-3',
    ]);
  });

  InvoiceDeliveryItemDto delivery({
    required String email,
    required int no,
    DateTime? startedAt,
  }) {
    final at = startedAt ?? DateTime.utc(2026, 8, 5, 9, 20);
    return InvoiceDeliveryItemDto(
      deliveryId: 'del-$no',
      deliveryNo: no,
      kind: no == 1 ? DeliveryKind.initial : DeliveryKind.resend,
      triggerType: DeliveryTriggerType.manual,
      recipientEmail: email,
      status: DeliveryStatus.succeeded,
      initiatedByActorType: DeliveryActorType.user,
      initiatedByActorId: 'actor-test',
      startedAt: at,
      completedAt: at,
      failureCode: null,
    );
  }

  SendInvoiceSheetContextDto sheet({
    String? suggestedEmail = 'accounting@company.com',
    bool operationLocked = false,
    List<InvoiceDeliveryItemDto>? history,
  }) {
    return SendInvoiceSheetContextDto(
      mode: SendInvoiceSheetMode.resend,
      suggestedEmail: suggestedEmail,
      suggestedEmailSource: DeliveryRecipientSource.lastInvoiceDelivery,
      history:
          history ??
          [
            delivery(email: 'old@example.com', no: 1),
            delivery(
              email: 'accounting@company.com',
              no: 2,
              startedAt: DateTime.utc(2026, 8, 5, 9, 20),
            ),
          ],
      operationLocked: operationLocked,
      displayState: DeliveryDisplayState.sent,
    );
  }

  Future<OrderInvoiceDeliveryCubit> readyCubit(
    SendInvoiceSheetContextDto context,
  ) async {
    mediator.queryResult = context;
    final cubit = OrderInvoiceDeliveryCubit(
      salesOrderId: 'order-101',
      executionContext: executionContext,
      mediator: mediator,
      idempotencyKeyFactory: keys,
    );
    await cubit.loadContext();
    mediator.errorToThrow = null;
    return cubit;
  }

  Future<void> pumpSheet(
    WidgetTester tester, {
    required OrderInvoiceDeliveryCubit cubit,
    required SendInvoiceSheetContextDto sheetContext,
    required Future<void> Function(BuildContext) onViewHistory,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: Scaffold(
          body: BlocProvider.value(
            value: cubit,
            child: OrderInvoiceResendSheet(
              sheetContext: sheetContext,
              onViewHistory: onViewHistory,
            ),
          ),
        ),
      ),
    );
  }

  group('OrderInvoiceResendSheet SG07-O02', () {
    testWidgets('fills latest email and exposes history link', (tester) async {
      final context = sheet();
      final cubit = await readyCubit(context);
      addTearDown(cubit.close);

      var historyOpened = 0;
      await pumpSheet(
        tester,
        cubit: cubit,
        sheetContext: context,
        onViewHistory: (_) async {
          historyOpened++;
        },
      );

      expect(find.text(OrderInvoiceDeliveryCopy.resendTitle), findsOneWidget);
      expect(find.text('accounting@company.com'), findsWidgets);
      expect(
        find.textContaining('Đã gửi gần nhất đến accounting@company.com'),
        findsOneWidget,
      );
      expect(find.text(OrderInvoiceDeliveryCopy.viewHistory), findsOneWidget);
      expect(find.text('CC'), findsNothing);
      expect(find.text('BCC'), findsNothing);
      expect(find.textContaining('Lưu email'), findsNothing);

      await tester.tap(find.byKey(const Key('action_view_delivery_history')));
      await tester.pump();
      expect(historyOpened, 1);
    });

    testWidgets('loading keeps copy/email and disables history link', (
      tester,
    ) async {
      final context = sheet();
      final cubit = await readyCubit(context);
      addTearDown(cubit.close);

      final pending = Completer<Object?>();
      mediator.commandResultFuture = pending.future;

      await pumpSheet(
        tester,
        cubit: cubit,
        sheetContext: context,
        onViewHistory: (_) async {},
      );

      await tester.tap(find.byKey(const Key('action_send_invoice')));
      await tester.pump();

      expect(find.text(OrderInvoiceDeliveryCopy.resendAction), findsOneWidget);
      expect(find.text('accounting@company.com'), findsWidgets);
      expect(
        tester.widget<VTextField>(find.byKey(const Key('field_recipient_email'))).enabled,
        isFalse,
      );
      expect(
        tester.widget<VButton>(find.byKey(const Key('action_send_invoice'))).isLoading,
        isTrue,
      );
      expect(
        tester
            .widget<VButton>(
              find.byKey(const Key('action_view_delivery_history')),
            )
            .onPressed,
        isNull,
      );

      pending.complete(
        const SendInvoiceResultDto(
          deliveryId: 'del-3',
          status: DeliveryStatus.processing,
        ),
      );
      await tester.pumpAndSettle();
    });

    testWidgets(
      'operationLocked locks field/CTA but history remains enabled',
      (tester) async {
        final context = sheet(operationLocked: true);
        final cubit = await readyCubit(context);
        addTearDown(cubit.close);

        var historyOpened = 0;
        await pumpSheet(
          tester,
          cubit: cubit,
          sheetContext: context,
          onViewHistory: (_) async {
            historyOpened++;
          },
        );

        expect(
          tester
              .widget<VTextField>(
                find.byKey(const Key('field_recipient_email')),
              )
              .enabled,
          isFalse,
        );
        expect(
          tester.widget<VButton>(find.byKey(const Key('action_send_invoice'))).onPressed,
          isNull,
        );
        expect(
          tester
              .widget<VButton>(
                find.byKey(const Key('action_view_delivery_history')),
              )
              .onPressed,
          isNotNull,
        );

        await tester.tap(find.byKey(const Key('action_view_delivery_history')));
        await tester.pump();
        expect(historyOpened, 1);
        expect(mediator.commands, isEmpty);
      },
    );
  });
}
