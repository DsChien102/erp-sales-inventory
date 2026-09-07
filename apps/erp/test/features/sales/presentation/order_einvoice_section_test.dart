import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_application/testing.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_einvoice_presentation/presentation.dart';
import 'package:erp/features/sales/presentation/bloc/order_einvoice_cubit.dart';
import 'package:erp/features/sales/presentation/support/order_einvoice_idempotency_key_factory.dart';
import 'package:erp/features/sales/presentation/widgets/order_einvoice_section.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

final class _TestMediator implements IModuleMediator {
  _TestMediator(this.module);

  final FakeEInvoiceModule module;

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    return module.executeCommandAsync(command);
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) {
    return module.executeQueryAsync(query);
  }
}

void main() {
  late FakeExecutionContext executionContext;

  setUp(() {
    executionContext = FakeExecutionContext(
      tenantId: 'tenant-fake',
      userId: 'actor-fake',
    );
  });

  Widget buildSubject({
    required FakeEInvoiceScenario scenario,
    required OrderInvoiceProjectionDto projection,
    bool isBuyerNotReady = false,
    OrderEInvoiceIdempotencyKeyFactory? keyFactory,
    void Function(OrderEInvoiceCubit)? onCubitCreated,
  }) {
    final module = FakeEInvoiceModule(scenario: scenario);
    final mediator = _TestMediator(module);

    return MaterialApp(
      theme: VTheme.lightTheme,
      home: Scaffold(
        body: OrderEInvoiceSection(
          salesOrderId: 'so-fake-001',
          orderCode: 'DH-001',
          orderVersion: 1,
          initialProjection: projection,
          isBuyerNotReady: isBuyerNotReady,
          mediator: mediator,
          executionContext: executionContext,
          idempotencyKeyFactory: keyFactory,
          onCubitCreated: onCubitCreated,
        ),
      ),
    );
  }

  testWidgets('open action sheet follows delivery updates without reopening', (tester) async {
    late OrderEInvoiceCubit cubit;
    await tester.pumpWidget(
      buildSubject(
        scenario: FakeEInvoiceScenario.retryAfterFailOk,
        projection: const OrderInvoiceProjectionDto(
          salesOrderId: 'so-fake-001',
          issuanceDisplayState: IssuanceDisplayState.issued,
          deliveryDisplayState: DeliveryDisplayState.sending,
          actions: [],
        ),
        onCubitCreated: (value) => cubit = value,
      ),
    );
    await tester.tap(find.byType(OrderEInvoiceRow));
    await tester.pumpAndSettle();
    expect(find.text(OrderEInvoiceCopy.deliverySending), findsOneWidget);
    cubit.emit(
      cubit.state.copyWith(
        projection: const OrderInvoiceProjectionDto(
          salesOrderId: 'so-fake-001',
          issuanceDisplayState: IssuanceDisplayState.issued,
          deliveryDisplayState: DeliveryDisplayState.sent,
          actions: [],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(OrderEInvoiceCopy.deliverySent), findsOneWidget);
    cubit.emit(cubit.state.copyWith(projection: const OrderInvoiceProjectionDto(
      salesOrderId: 'so-fake-001', issuanceDisplayState: IssuanceDisplayState.issued,
      deliveryDisplayState: DeliveryDisplayState.failed, actions: [],
    )));
    await tester.pumpAndSettle();
    expect(find.text(OrderEInvoiceCopy.deliverySendFailed), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  group('OrderEInvoiceSection Integration Tests', () {
    testWidgets('wgt_e02_u05_fr02_01 failed row keeps normal issue label', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          scenario: FakeEInvoiceScenario.retryAfterFailOk,
          projection: const OrderInvoiceProjectionDto(
            salesOrderId: 'so-fake-001',
            issuanceDisplayState: IssuanceDisplayState.failed,
            actions: [OrderInvoiceAction.issue],
          ),
        ),
      );

      await tester.tap(find.byType(OrderEInvoiceRow));
      await tester.pumpAndSettle();

      expect(find.byType(PreIssueEInvoiceActionSheet), findsOneWidget);
      expect(find.text(OrderEInvoiceCopy.issueTitle), findsOneWidget);
      expect(find.text('Thử lại'), findsNothing);
    });

    testWidgets('failed + failureCode COMMAND_INTEGRITY displays safe message and allows retry', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(
          scenario: FakeEInvoiceScenario.retryAfterFailOk,
          projection: const OrderInvoiceProjectionDto(
            salesOrderId: 'so-fake-001',
            issuanceDisplayState: IssuanceDisplayState.failed,
            actions: [OrderInvoiceAction.issue],
          ),
          onCubitCreated: (c) {
            c.emit(c.state.copyWith(failureCode: 'COMMAND_INTEGRITY'));
          },
        ),
      );

      await tester.tap(find.byType(OrderEInvoiceRow));
      await tester.pumpAndSettle();

      expect(find.byType(PreIssueEInvoiceActionSheet), findsOneWidget);
      expect(find.byType(IssuanceFailureBanner), findsOneWidget);
      expect(find.text(OrderEInvoiceCopy.failureBannerIntegrityMessage), findsOneWidget);
      expect(find.text(OrderEInvoiceCopy.issueTitle), findsOneWidget);
    });

    testWidgets('processing/reconciling row ignores tap and does not show pre-issue sheet', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(
          scenario: FakeEInvoiceScenario.retryWhileReconciling,
          projection: const OrderInvoiceProjectionDto(
            salesOrderId: 'so-fake-001',
            issuanceDisplayState: IssuanceDisplayState.processing,
            actions: [],
          ),
        ),
      );

      await tester.tap(find.byType(OrderEInvoiceRow));
      await tester.pumpAndSettle();

      expect(find.byType(PreIssueEInvoiceActionSheet), findsNothing);
    });

    testWidgets(
      'retry confirmation step triggers RetryIssuanceCommand and transitions immediately to processing',
      (tester) async {
        OrderEInvoiceCubit? capturedCubit;
        final keyFactory = DeterministicOrderEInvoiceIdempotencyKeyFactory(['key-retry-1']);

        await tester.pumpWidget(
          buildSubject(
            scenario: FakeEInvoiceScenario.retryAfterFailOk,
            projection: const OrderInvoiceProjectionDto(
              salesOrderId: 'so-fake-001',
              issuanceDisplayState: IssuanceDisplayState.failed,
              actions: [OrderInvoiceAction.issue],
            ),
            keyFactory: keyFactory,
            onCubitCreated: (c) => capturedCubit = c,
          ),
        );

        // Open sheet
        await tester.tap(find.byType(OrderEInvoiceRow));
        await tester.pumpAndSettle();

        // Tap issue action
        await tester.tap(find.byKey(const Key('action_issue')));
        await tester.pumpAndSettle();

        // Confirmation sheet appears
        expect(find.byType(IssueInvoiceConfirmationSheet), findsOneWidget);
        expect(find.text(OrderEInvoiceCopy.issueConfirmationTitle), findsOneWidget);

        // Confirm issue
        await tester.tap(find.byKey(const Key('action_confirm_issue')));
        await tester.pumpAndSettle();

        // State is immediately processing
        expect(
          capturedCubit?.state.projection.issuanceDisplayState,
          IssuanceDisplayState.processing,
        );
        expect(find.text(OrderEInvoiceCopy.badgeProcessing), findsOneWidget);
      },
    );
  });
}
