import 'dart:async';

import 'package:erp/features/einvoice/data/models.dart';
import 'package:erp/features/einvoice/logic/order_einvoice_idempotency_key_factory.dart';
import 'package:erp/features/einvoice/logic/order_invoice_delivery_cubit.dart';
import 'package:erp/features/einvoice/presentation/support/order_invoice_delivery_copy.dart';
import 'package:erp/features/einvoice/presentation/widgets/send_invoice_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';

import '../../support/fake_einvoice_repository.dart';

void main() {
  late FakeEInvoiceRepository repository;
  late DeterministicOrderEInvoiceIdempotencyKeyFactory keys;

  setUp(() {
    repository = FakeEInvoiceRepository();
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
    repository.sendContext = context;
    final cubit = OrderInvoiceDeliveryCubit(
      salesOrderId: 'order-101',
      repository: repository,
      idempotencyKeyFactory: keys,
    );
    await cubit.loadContext();
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

      expect(find.text('buyer@example.com'), findsOneWidget);
      expect(find.text(OrderInvoiceDeliveryCopy.recipientHelper), findsOneWidget);
      expect(find.text('Hồ sơ khách hàng'), findsOneWidget);
      expect(find.byKey(const Key('label_suggestion_source')), findsOneWidget);

      final send = tester.widget<VButton>(
        find.byKey(const Key('action_send_invoice')),
      );
      expect(send.onPressed, isNotNull);
      expect(send.isLoading, isFalse);
      expect(repository.sendCalls, isEmpty);
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

      final pending = Completer<void>();
      repository.holdOn['send'] = pending;

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

      repository.sendResult = const SendInvoiceResultDto(
        deliveryId: 'del-1',
        status: DeliveryStatus.processing,
      );
      pending.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('double tap while pending sends one command', (tester) async {
      final context = sheet();
      final cubit = await readyCubit(context);
      addTearDown(cubit.close);

      final pending = Completer<void>();
      repository.holdOn['send'] = pending;

      await pumpSheet(tester, cubit: cubit, sheetContext: context);

      await tester.tap(find.byKey(const Key('action_send_invoice')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('action_send_invoice')));
      await tester.pump();

      expect(repository.sendCalls, hasLength(1));

      repository.sendResult = const SendInvoiceResultDto(
        deliveryId: 'del-1',
        status: DeliveryStatus.processing,
      );
      pending.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('submit failure keeps sheet open and restores controls', (
      tester,
    ) async {
      final context = sheet();
      final cubit = await readyCubit(context);
      addTearDown(cubit.close);

      repository.throwOn['send'] = Exception('SEND_FAILED');

      await pumpSheet(tester, cubit: cubit, sheetContext: context);

      await tester.tap(find.byKey(const Key('action_send_invoice')));
      await tester.pumpAndSettle();

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
