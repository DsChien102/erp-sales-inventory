import 'dart:async';

import 'package:erp/features/einvoice/data/models.dart';
import 'package:erp/features/einvoice/logic/order_einvoice_idempotency_key_factory.dart';
import 'package:erp/features/einvoice/logic/order_invoice_delivery_cubit.dart';
import 'package:erp/features/einvoice/presentation/support/order_invoice_delivery_copy.dart';
import 'package:erp/features/einvoice/presentation/widgets/resend_invoice_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

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

  InvoiceDeliveryItemDto delivery({
    required String email,
    required int no,
    DateTime? startedAt,
    DeliveryStatus status = DeliveryStatus.succeeded,
  }) {
    final at = startedAt ?? DateTime.utc(2026, 8, 5, 9, 20);
    return InvoiceDeliveryItemDto(
      deliveryId: 'del-$no',
      deliveryNo: no,
      kind: no == 1 ? DeliveryKind.initial : DeliveryKind.resend,
      triggerType: DeliveryTriggerType.manual,
      recipientEmail: email,
      status: status,
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

  group('OrderInvoiceResendSheet KI-08 / HD-12 layout', () {
    Future<void> pumpWith(
      WidgetTester tester,
      SendInvoiceSheetContextDto ctx,
    ) async {
      final cubit = await readyCubit(ctx);
      addTearDown(cubit.close);
      await pumpSheet(
        tester,
        cubit: cubit,
        sheetContext: ctx,
        onViewHistory: (_) async {},
      );
    }

    testWidgets('summary uses last successful delivery', (tester) async {
      await pumpWith(
        tester,
        sheet(history: [
          delivery(email: 'a@x.vn', no: 1),
          delivery(email: 'b@x.vn', no: 2, status: DeliveryStatus.failed),
        ]),
      );
      expect(find.textContaining('Đã gửi gần nhất đến a@x.vn'), findsOneWidget);
      expect(find.textContaining('b@x.vn ·'), findsNothing);
    });

    testWidgets('summary hidden without successful delivery', (tester) async {
      await pumpWith(
        tester,
        sheet(history: [
          delivery(email: 'a@x.vn', no: 1, status: DeliveryStatus.failed),
          delivery(email: 'b@x.vn', no: 2, status: DeliveryStatus.processing),
        ]),
      );
      expect(find.textContaining('Đã gửi gần nhất'), findsNothing);
    });

    testWidgets('summary hidden when history empty', (tester) async {
      await pumpWith(tester, sheet(history: const []));
      expect(find.textContaining('Đã gửi gần nhất'), findsNothing);
    });

    testWidgets('source label shown for last invoice delivery', (tester) async {
      await pumpWith(tester, sheet());
      expect(find.byKey(const Key('label_suggestion_source')), findsOneWidget);
      expect(find.text('Lần gửi gần nhất của hóa đơn này'), findsOneWidget);
    });

    testWidgets('summary sits between email field and history link', (tester) async {
      await pumpWith(tester, sheet());
      final field = tester.getTopLeft(find.byKey(const Key('field_recipient_email'))).dy;
      final summary =
          tester.getTopLeft(find.textContaining('Đã gửi gần nhất đến')).dy;
      final link =
          tester.getTopLeft(find.byKey(const Key('action_view_delivery_history'))).dy;
      expect(field, lessThan(summary));
      expect(summary, lessThan(link));
    });

    test('latestSuccessfulDelivery picks last succeeded', () {
      expect(latestSuccessfulDelivery(const []), isNull);
      final s1 = delivery(email: 's1@x.vn', no: 1);
      final f2 = delivery(email: 'f2@x.vn', no: 2, status: DeliveryStatus.failed);
      final s3 = delivery(email: 's3@x.vn', no: 3);
      final u4 = delivery(email: 'u4@x.vn', no: 4, status: DeliveryStatus.processing);
      expect(latestSuccessfulDelivery([s1, f2, s3, u4]), s3);
    });
  });

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

      final pending = Completer<void>();
      repository.holdOn['send'] = pending;

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

      repository.sendResult = const SendInvoiceResultDto(
        deliveryId: 'del-3',
        status: DeliveryStatus.processing,
      );
      pending.complete();
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
        expect(repository.sendCalls, isEmpty);
      },
    );
  });
}
