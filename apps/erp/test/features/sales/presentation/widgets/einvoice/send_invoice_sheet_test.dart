import 'dart:async';

import 'package:erp/features/sales/presentation/bloc/order_invoice_delivery_cubit.dart';
import 'package:erp/features/sales/presentation/support/order_einvoice_idempotency_key_factory.dart';
import 'package:erp/features/sales/presentation/support/order_invoice_delivery_copy.dart';
import 'package:erp/features/sales/presentation/widgets/einvoice/send_invoice_sheet.dart';
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

  SendInvoiceSheetContextDto sheet({
    String? suggestedEmail = 'buyer@example.com',
    DeliveryRecipientSource? source = DeliveryRecipientSource.currentPartnerProfile,
    bool operationLocked = false,
  }) {
    return SendInvoiceSheetContextDto(
      mode: SendInvoiceSheetMode.send,
      suggestedEmail: suggestedEmail,
      suggestedEmailSource: source,
      history: const [],
      operationLocked: operationLocked,
      displayState: DeliveryDisplayState.notSent,
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
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: Scaffold(
          body: BlocProvider.value(
            value: cubit,
            child: OrderInvoiceSendSheet(sheetContext: sheetContext),
          ),
        ),
      ),
    );
  }

  group('OrderInvoiceSendSheet SG07-O01', () {
    testWidgets('O01-A fills suggestion without creating command', (
      tester,
    ) async {
      final context = sheet();
      final cubit = await readyCubit(context);
      addTearDown(cubit.close);

      await pumpSheet(tester, cubit: cubit, sheetContext: context);

      expect(find.text(OrderInvoiceDeliveryCopy.sendTitle), findsOneWidget);
      expect(find.text('buyer@example.com'), findsOneWidget);
      expect(find.text(OrderInvoiceDeliveryCopy.recipientHelper), findsOneWidget);
      expect(find.text('Hồ sơ khách hàng'), findsOneWidget);
      expect(find.byKey(const Key('label_suggestion_source')), findsOneWidget);

      final send = tester.widget<VButton>(
        find.byKey(const Key('action_send_invoice')),
      );
      expect(send.onPressed, isNotNull);
      expect(send.isLoading, isFalse);
      expect(mediator.commands, isEmpty);
    });

    testWidgets('O01-B empty email disables submit', (tester) async {
      final context = sheet(suggestedEmail: null, source: null);
      final cubit = await readyCubit(context);
      addTearDown(cubit.close);

      await pumpSheet(tester, cubit: cubit, sheetContext: context);

      final send = tester.widget<VButton>(
        find.byKey(const Key('action_send_invoice')),
      );
      expect(send.onPressed, isNull);
      expect(find.text(OrderInvoiceDeliveryCopy.recipientHelper), findsOneWidget);
    });

    testWidgets('O01-C invalid email shows error helper then recovers', (
      tester,
    ) async {
      final context = sheet(suggestedEmail: null, source: null);
      final cubit = await readyCubit(context);
      addTearDown(cubit.close);

      await pumpSheet(tester, cubit: cubit, sheetContext: context);

      await tester.enterText(
        find.byKey(const Key('field_recipient_email')),
        'bad',
      );
      await tester.pump();

      expect(find.text(OrderInvoiceDeliveryCopy.recipientInvalid), findsOneWidget);
      expect(
        tester.widget<VButton>(find.byKey(const Key('action_send_invoice'))).onPressed,
        isNull,
      );

      await tester.enterText(
        find.byKey(const Key('field_recipient_email')),
        'ok@example.com',
      );
      await tester.pump();

      expect(find.text(OrderInvoiceDeliveryCopy.recipientHelper), findsOneWidget);
      expect(find.text(OrderInvoiceDeliveryCopy.recipientInvalid), findsNothing);
      expect(
        tester.widget<VButton>(find.byKey(const Key('action_send_invoice'))).onPressed,
        isNotNull,
      );
    });

    testWidgets('O01-D submitting locks field/cancel and shows spinner', (
      tester,
    ) async {
      final context = sheet();
      final cubit = await readyCubit(context);
      addTearDown(cubit.close);

      final pending = Completer<Object?>();
      mediator.commandResultFuture = pending.future;

      await pumpSheet(tester, cubit: cubit, sheetContext: context);

      await tester.tap(find.byKey(const Key('action_send_invoice')));
      await tester.pump();

      expect(
        tester.widget<VTextField>(find.byKey(const Key('field_recipient_email'))).enabled,
        isFalse,
      );
      final action = tester.widget<VButton>(
        find.byKey(const Key('action_send_invoice')),
      );
      expect(action.isLoading, isTrue);
      expect(find.text(OrderInvoiceDeliveryCopy.sendAction), findsOneWidget);
      expect(find.text(OrderInvoiceDeliveryCopy.recipientHelper), findsOneWidget);
      expect(find.text('buyer@example.com'), findsOneWidget);
      expect(
        tester.widget<VButton>(find.byKey(const Key('action_cancel_send'))).onPressed,
        isNull,
      );

      pending.complete(
        const SendInvoiceResultDto(
          deliveryId: 'del-1',
          status: DeliveryStatus.processing,
        ),
      );
      await tester.pumpAndSettle();
    });

    testWidgets('double tap while pending sends one command', (tester) async {
      final context = sheet();
      final cubit = await readyCubit(context);
      addTearDown(cubit.close);

      final pending = Completer<Object?>();
      mediator.commandResultFuture = pending.future;

      await pumpSheet(tester, cubit: cubit, sheetContext: context);

      await tester.tap(find.byKey(const Key('action_send_invoice')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('action_send_invoice')));
      await tester.pump();

      expect(mediator.commands, hasLength(1));

      pending.complete(
        const SendInvoiceResultDto(
          deliveryId: 'del-1',
          status: DeliveryStatus.processing,
        ),
      );
      await tester.pumpAndSettle();
    });

    testWidgets('submit failure keeps sheet open and restores controls', (
      tester,
    ) async {
      final context = sheet();
      final cubit = await readyCubit(context);
      addTearDown(cubit.close);

      mediator.errorToThrow = Exception('SEND_FAILED');

      await pumpSheet(tester, cubit: cubit, sheetContext: context);

      await tester.tap(find.byKey(const Key('action_send_invoice')));
      await tester.pumpAndSettle();

      expect(find.text(OrderInvoiceDeliveryCopy.sendTitle), findsOneWidget);
      expect(find.text('buyer@example.com'), findsOneWidget);
      expect(
        tester.widget<VTextField>(find.byKey(const Key('field_recipient_email'))).enabled,
        isTrue,
      );
      expect(
        tester.widget<VButton>(find.byKey(const Key('action_send_invoice'))).onPressed,
        isNotNull,
      );
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
