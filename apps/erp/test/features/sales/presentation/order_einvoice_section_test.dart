import 'dart:async';

import 'package:async_query/async_query.dart';
import 'package:async_query_flutter/async_query_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_application/testing.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_einvoice_presentation/presentation.dart'
    hide InvoiceDocumentsActionSheet, PostIssueEInvoiceActionSheet;
import 'package:erp/features/sales/presentation/bloc/order_einvoice_cubit.dart';
import 'package:erp/features/sales/presentation/bloc/order_einvoice_state.dart';
import 'package:erp/features/sales/presentation/services/i_invoice_document_exporter.dart';
import 'package:erp/features/sales/presentation/support/order_einvoice_idempotency_key_factory.dart';
import 'package:erp/features/sales/presentation/support/order_einvoice_post_issue_copy.dart';
import 'package:erp/features/sales/presentation/support/order_invoice_delivery_copy.dart';
import 'package:erp/features/sales/presentation/support/order_invoice_delivery_error_message.dart';
import 'package:erp/features/sales/presentation/widgets/einvoice/einvoice_action_item.dart'
    as app_ei;
import 'package:erp/features/sales/presentation/widgets/einvoice/invoice_documents_action_sheet.dart';
import 'package:erp/features/sales/presentation/widgets/einvoice/post_issue_einvoice_action_sheet.dart';
import 'package:erp/features/sales/presentation/widgets/einvoice/resend_invoice_sheet.dart';
import 'package:erp/features/sales/presentation/widgets/einvoice/send_invoice_sheet.dart';
import 'package:erp/features/sales/presentation/widgets/order_einvoice_section.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

final class _RecordingExporter implements IInvoiceDocumentExporter {
  _RecordingExporter({this.result = true});

  final bool result;
  final List<
    ({
      String filename,
      InvoiceDocumentType type,
      String? url,
      String? expectedSha256,
    })
  >
  exported = [];

  @override
  Future<bool> exportDocument({
    required String filename,
    required InvoiceDocumentType type,
    String? url,
    List<int>? bytes,
    String? expectedSha256,
  }) async {
    exported.add((
      filename: filename,
      type: type,
      url: url,
      expectedSha256: expectedSha256,
    ));
    return result;
  }
}

final class _TestMediator implements IModuleMediator {
  _TestMediator(
    this.module, {
    this.officialViewGate,
    this.documentGate,
    this.previewGate,
    this.sendGate,
    this.sheetContextOverride,
  });

  final FakeEInvoiceModule module;
  final Completer<void>? officialViewGate;
  final Completer<void>? documentGate;
  final Completer<void>? previewGate;
  final Completer<void>? sendGate;
  final SendInvoiceSheetContextDto? sheetContextOverride;
  final List<dynamic> queries = [];
  final List<dynamic> commands = [];

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) async {
    commands.add(command);
    if (command is RequestOfficialInvoiceViewCommand && officialViewGate != null) {
      await officialViewGate!.future;
    }
    if (command is RequestInvoiceDocumentCommand && documentGate != null) {
      await documentGate!.future;
    }
    if (command is RequestInvoicePreviewCommand && previewGate != null) {
      await previewGate!.future;
    }
    if (command is SendElectronicInvoiceCommand && sendGate != null) {
      await sendGate!.future;
    }
    return module.executeCommandAsync(command);
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    queries.add(query);
    if (query is GetSendInvoiceSheetContextQuery && sheetContextOverride != null) {
      return sheetContextOverride as TResult;
    }
    return module.executeQueryAsync(query);
  }
}

final class _ProjectionOverrideMediator implements IModuleMediator {
  _ProjectionOverrideMediator(this.delegate, {required this.projectionFn});

  final IModuleMediator delegate;
  final OrderInvoiceProjectionDto Function() projectionFn;

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    return delegate.executeCommandAsync(command);
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    if (query is GetOrderInvoiceProjectionQuery) {
      return projectionFn() as TResult;
    }
    return delegate.executeQueryAsync(query);
  }
}

void main() {
  late FakeExecutionContext executionContext;
  late QueryClient queryClient;

  setUp(() {
    executionContext = FakeExecutionContext(
      tenantId: 'tenant-fake',
      userId: 'actor-fake',
    );
    queryClient = QueryClient(
      options: const QueryClientOptions(
        queries: QueryOptionsDefaults(retry: 0, staleTime: Duration.zero),
      ),
    );
  });

  tearDown(() => queryClient.dispose());

  Widget buildSubject({
    required FakeEInvoiceScenario scenario,
    required OrderInvoiceProjectionDto projection,
    bool isBuyerNotReady = false,
    bool hasLoadedInitialProjection = true,
    OrderEInvoiceIdempotencyKeyFactory? keyFactory,
    void Function(OrderEInvoiceCubit)? onCubitCreated,
    void Function(_TestMediator)? onMediatorCreated,
    Completer<void>? officialViewGate,
    Completer<void>? documentGate,
    Completer<void>? previewGate,
    Completer<void>? sendGate,
    SendInvoiceSheetContextDto? sheetContextOverride,
    IInvoiceDocumentExporter? documentExporter,
  }) {
    final module = FakeEInvoiceModule(scenario: scenario);
    final mediator = _TestMediator(
      module,
      officialViewGate: officialViewGate,
      documentGate: documentGate,
      previewGate: previewGate,
      sendGate: sendGate,
      sheetContextOverride: sheetContextOverride,
    );
    onMediatorCreated?.call(mediator);

    return QueryClientProvider(
      client: queryClient,
      child: MaterialApp(
        theme: VTheme.lightTheme,
        home: Scaffold(
          body: OrderEInvoiceSection(
            salesOrderId: 'so-fake-001',
            orderCode: 'DH-001',
            orderVersion: 1,
            initialProjection: projection,
            hasLoadedInitialProjection: hasLoadedInitialProjection,
            isBuyerNotReady: isBuyerNotReady,
            mediator: mediator,
            executionContext: executionContext,
            documentExporter: documentExporter,
            idempotencyKeyFactory: keyFactory,
            onCubitCreated: onCubitCreated,
          ),
        ),
      ),
    );
  }

  testWidgets('open action sheet follows delivery updates without reopening', (tester) async {
    var liveProjection = const OrderInvoiceProjectionDto(
      salesOrderId: 'so-fake-001',
      issuanceDisplayState: IssuanceDisplayState.issued,
      deliveryDisplayState: DeliveryDisplayState.sending,
      actions: [],
    );
    final module = FakeEInvoiceModule(scenario: FakeEInvoiceScenario.retryAfterFailOk);
    final mediator = _TestMediator(module);
    final cubit = OrderEInvoiceCubit(
      salesOrderId: 'so-fake-001',
      orderVersion: 1,
      initialProjection: liveProjection,
      executionContext: executionContext,
      mediator: _ProjectionOverrideMediator(
        mediator,
        projectionFn: () => liveProjection,
      ),
      queryClient: queryClient,
    );
    addTearDown(cubit.close);

    await tester.pumpWidget(
      QueryClientProvider(
        client: queryClient,
        child: MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: OrderEInvoiceSection(
              salesOrderId: 'so-fake-001',
              orderCode: 'DH-001',
              orderVersion: 1,
              initialProjection: liveProjection,
              mediator: mediator,
              executionContext: executionContext,
              cubit: cubit,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(OrderEInvoiceRow));
    await tester.pumpAndSettle();
    expect(find.text(OrderEInvoiceCopy.deliverySending), findsOneWidget);

    liveProjection = const OrderInvoiceProjectionDto(
      salesOrderId: 'so-fake-001',
      issuanceDisplayState: IssuanceDisplayState.issued,
      deliveryDisplayState: DeliveryDisplayState.sent,
      actions: [],
    );
    cubit.emit(cubit.state.copyWith(projection: liveProjection));
    await tester.pumpAndSettle();
    expect(find.text(OrderEInvoiceCopy.deliverySent), findsOneWidget);

    liveProjection = const OrderInvoiceProjectionDto(
      salesOrderId: 'so-fake-001',
      issuanceDisplayState: IssuanceDisplayState.issued,
      deliveryDisplayState: DeliveryDisplayState.failed,
      actions: [],
    );
    cubit.emit(cubit.state.copyWith(projection: liveProjection));
    await tester.pumpAndSettle();
    expect(find.text(OrderEInvoiceCopy.deliverySendFailed), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'th08_wgt_e03_u01_fr01_01 official action alone shows loading and stable copy',
    (tester) async {
      final officialViewGate = Completer<void>();
      await tester.pumpWidget(
        buildSubject(
          scenario: FakeEInvoiceScenario.officialViewOk,
          projection: const OrderInvoiceProjectionDto(
            salesOrderId: 'so-fake-001',
            issuanceDisplayState: IssuanceDisplayState.issued,
            deliveryDisplayState: DeliveryDisplayState.notSent,
            actions: [OrderInvoiceAction.view],
          ),
          officialViewGate: officialViewGate,
        ),
      );
      await tester.tap(find.byType(OrderEInvoiceRow));
      await tester.pumpAndSettle();
      expect(find.byType(PostIssueEInvoiceActionSheet), findsOneWidget);

      await tester.tap(find.byKey(const Key('action_view_official')));
      await tester.pump();

      expect(find.byType(PostIssueEInvoiceActionSheet), findsOneWidget);
      expect(
        find.text(OrderEInvoicePostIssueCopy.viewOfficialTitle),
        findsOneWidget,
      );
      expect(
        find.text(OrderEInvoicePostIssueCopy.viewOfficialSupporting),
        findsOneWidget,
      );
      expect(
        tester
            .widget<app_ei.EInvoiceActionItem>(
              find.byKey(const Key('action_view_official')),
            )
            .loading,
        isTrue,
      );
      expect(
        tester
            .widget<app_ei.EInvoiceActionItem>(
              find.byKey(const Key('action_documents')),
            )
            .enabled,
        isFalse,
      );
      expect(
        tester
            .widget<app_ei.EInvoiceActionItem>(
              find.byKey(const Key('action_send')),
            )
            .enabled,
        isFalse,
      );

      officialViewGate.complete();
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'submitting without isOpeningOfficialView does not load official action',
    (tester) async {
      late OrderEInvoiceCubit cubit;
      await tester.pumpWidget(
        buildSubject(
          scenario: FakeEInvoiceScenario.officialViewOk,
          projection: const OrderInvoiceProjectionDto(
            salesOrderId: 'so-fake-001',
            issuanceDisplayState: IssuanceDisplayState.issued,
            deliveryDisplayState: DeliveryDisplayState.notSent,
            actions: [OrderInvoiceAction.view],
          ),
          onCubitCreated: (created) => cubit = created,
        ),
      );
      await tester.tap(find.byType(OrderEInvoiceRow));
      await tester.pumpAndSettle();

      cubit.emit(
        cubit.state.copyWith(
          status: OrderEInvoiceStatus.submitting,
          isOpeningOfficialView: false,
        ),
      );
      await tester.pump();

      expect(
        tester
            .widget<app_ei.EInvoiceActionItem>(
              find.byKey(const Key('action_view_official')),
            )
            .loading,
        isFalse,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('save pdf keeps documents sheet open and disables xml', (tester) async {
    final documentGate = Completer<void>();
    final exporter = _RecordingExporter();
    await tester.pumpWidget(
      buildSubject(
        scenario: FakeEInvoiceScenario.downloadPdfOk,
        projection: const OrderInvoiceProjectionDto(
          salesOrderId: 'so-fake-001',
          issuanceDisplayState: IssuanceDisplayState.issued,
          deliveryDisplayState: DeliveryDisplayState.notSent,
          actions: [OrderInvoiceAction.view],
        ),
        documentGate: documentGate,
        documentExporter: exporter,
      ),
    );
    await tester.tap(find.byType(OrderEInvoiceRow));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('action_documents')));
    await tester.pumpAndSettle();
    expect(find.byType(InvoiceDocumentsActionSheet), findsOneWidget);

    await tester.tap(find.byKey(const Key('action_save_pdf')));
    await tester.pump();

    expect(find.byType(InvoiceDocumentsActionSheet), findsOneWidget);
    expect(
      tester
          .widget<app_ei.EInvoiceActionItem>(
            find.byKey(const Key('action_save_pdf')),
          )
          .loading,
      isTrue,
    );
    expect(
      tester
          .widget<app_ei.EInvoiceActionItem>(
            find.byKey(const Key('action_save_xml')),
          )
          .enabled,
      isFalse,
    );
    expect(exporter.exported, isEmpty);

    documentGate.complete();
    await tester.pump(); // command returns PENDING and schedules poll delay
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    expect(exporter.exported, hasLength(1));
    expect(find.byType(InvoiceDocumentsActionSheet), findsNothing);
    expect(find.byType(OrderEInvoiceRow), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'th08_wgt_e03_u01_fr08_01 official view failure shows safe message and keeps issued row',
    (tester) async {
      await tester.pumpWidget(
        buildSubject(
          scenario: FakeEInvoiceScenario.officialViewProviderDown,
          projection: const OrderInvoiceProjectionDto(
            salesOrderId: 'so-fake-001',
            issuanceDisplayState: IssuanceDisplayState.issued,
            deliveryDisplayState: DeliveryDisplayState.notSent,
            actions: [OrderInvoiceAction.view],
          ),
        ),
      );
      await tester.tap(find.byType(OrderEInvoiceRow));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('action_view_official')));
      await tester.pump(); // start loading
      await tester.pumpAndSettle();

      const safeMessage = 'Cổng kết nối hóa đơn tạm thời không khả dụng. Vui lòng thử lại.';
      expect(find.text(safeMessage), findsOneWidget);
      expect(find.textContaining('Exception'), findsNothing);
      expect(find.textContaining('CHECK_REQUIRED'), findsNothing);
      expect(find.textContaining('FAILED'), findsNothing);
      expect(find.textContaining('postgres'), findsNothing);
      expect(find.text(OrderEInvoiceCopy.badgeIssued), findsOneWidget);
      expect(find.byType(PostIssueEInvoiceActionSheet), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'th08_wgt_e03_u02_fr08_01 document failure shows safe message and keeps sheet open',
    (tester) async {
      await tester.pumpWidget(
        buildSubject(
          scenario: FakeEInvoiceScenario.downloadUnavailable,
          projection: const OrderInvoiceProjectionDto(
            salesOrderId: 'so-fake-001',
            issuanceDisplayState: IssuanceDisplayState.issued,
            deliveryDisplayState: DeliveryDisplayState.notSent,
            actions: [OrderInvoiceAction.view],
          ),
        ),
      );
      await tester.tap(find.byType(OrderEInvoiceRow));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('action_documents')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('action_save_pdf')));
      await tester.pump();
      await tester.pumpAndSettle();

      const safeMessage = 'Không thể tải tài liệu hóa đơn lúc này. Vui lòng thử lại.';
      expect(find.text(safeMessage), findsOneWidget);
      expect(find.textContaining('Exception'), findsNothing);
      expect(find.textContaining('FAILED'), findsNothing);
      expect(find.textContaining('CHECK_REQUIRED'), findsNothing);
      expect(find.textContaining('postgres'), findsNothing);
      expect(find.byType(InvoiceDocumentsActionSheet), findsOneWidget);
      expect(
        tester
            .widget<app_ei.EInvoiceActionItem>(
              find.byKey(const Key('action_save_xml')),
            )
            .enabled,
        isTrue,
      );
      expect(
        tester
            .widget<app_ei.EInvoiceActionItem>(
              find.byKey(const Key('action_save_pdf')),
            )
            .enabled,
        isTrue,
      );
      expect(
        tester
            .widget<app_ei.EInvoiceActionItem>(
              find.byKey(const Key('action_save_pdf')),
            )
            .loading,
        isFalse,
      );
      expect(find.text(OrderEInvoiceCopy.badgeIssued), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('preview keeps pre-issue sheet open and disables issue', (tester) async {
    final previewGate = Completer<void>();
    await tester.pumpWidget(
      buildSubject(
        scenario: FakeEInvoiceScenario.previewOk,
        projection: const OrderInvoiceProjectionDto(
          salesOrderId: 'so-fake-001',
          issuanceDisplayState: IssuanceDisplayState.failed,
          actions: [OrderInvoiceAction.issue],
        ),
        previewGate: previewGate,
      ),
    );
    await tester.tap(find.byType(OrderEInvoiceRow));
    await tester.pumpAndSettle();
    expect(find.byType(PreIssueEInvoiceActionSheet), findsOneWidget);

    await tester.tap(find.byKey(const Key('action_preview')));
    await tester.pump();

    expect(find.byType(PreIssueEInvoiceActionSheet), findsOneWidget);
    expect(
      tester.widget<EInvoiceActionItem>(find.byKey(const Key('action_preview'))).loading,
      isTrue,
    );
    expect(
      tester.widget<EInvoiceActionItem>(find.byKey(const Key('action_issue'))).enabled,
      isFalse,
    );

    previewGate.complete();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('dismissing pre-issue sheet while previewing cancels preview', (tester) async {
    final previewGate = Completer<void>();
    late OrderEInvoiceCubit cubit;
    await tester.pumpWidget(
      buildSubject(
        scenario: FakeEInvoiceScenario.previewOk,
        projection: const OrderInvoiceProjectionDto(
          salesOrderId: 'so-fake-001',
          issuanceDisplayState: IssuanceDisplayState.failed,
          actions: [OrderInvoiceAction.issue],
        ),
        previewGate: previewGate,
        onCubitCreated: (value) => cubit = value,
      ),
    );
    await tester.tap(find.byType(OrderEInvoiceRow));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('action_preview')));
    await tester.pump();
    expect(cubit.state.status, OrderEInvoiceStatus.previewing);

    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();

    expect(find.byType(PreIssueEInvoiceActionSheet), findsNothing);
    expect(cubit.state.status, OrderEInvoiceStatus.idle);
    expect(cubit.state.errorMessage, isNull);

    previewGate.complete();
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

    testWidgets(
      'failed without retry action ignores tap',
      (tester) async {
        await tester.pumpWidget(
          buildSubject(
            scenario: FakeEInvoiceScenario.retryAfterFailOk,
            projection: const OrderInvoiceProjectionDto(
              salesOrderId: 'so-fake-001',
              issuanceDisplayState: IssuanceDisplayState.failed,
              actions: [],
            ),
          ),
        );

        await tester.tap(find.byType(OrderEInvoiceRow));
        await tester.pumpAndSettle();

        expect(find.byType(PreIssueEInvoiceActionSheet), findsNothing);
      },
    );

    testWidgets(
      'placeholder projection blocks tap until authoritative snapshot',
      (tester) async {
        final gate = Completer<void>();
        final module = FakeEInvoiceModule(
          scenario: FakeEInvoiceScenario.retryAfterFailOk,
        );
        final mediator = _GatedProjectionMediator(module, gate);
        OrderEInvoiceCubit? cubit;

        await tester.pumpWidget(
          QueryClientProvider(
            client: queryClient,
            child: MaterialApp(
              theme: VTheme.lightTheme,
              home: Scaffold(
                body: OrderEInvoiceSection(
                  salesOrderId: 'so-fake-001',
                  orderCode: 'DH-001',
                  orderVersion: 1,
                  hasLoadedInitialProjection: false,
                  initialProjection: const OrderInvoiceProjectionDto(
                    salesOrderId: 'so-fake-001',
                    issuanceDisplayState: IssuanceDisplayState.notIssued,
                    actions: [OrderInvoiceAction.issue],
                  ),
                  mediator: mediator,
                  executionContext: executionContext,
                  onCubitCreated: (value) => cubit = value,
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(cubit?.state.hasLoadedProjection, isFalse);
        await tester.tap(find.byType(OrderEInvoiceRow));
        await tester.pumpAndSettle();
        expect(find.byType(PreIssueEInvoiceActionSheet), findsNothing);
        expect(mediator.commands, isEmpty);

        gate.complete();
        await tester.pump();
        await tester.pump(const Duration(seconds: 5));
        expect(cubit?.state.hasLoadedProjection, isTrue);
        expect(cubit?.state.readiness, isNotNull);

        await tester.tap(find.byType(OrderEInvoiceRow));
        await tester.pumpAndSettle();
        expect(find.byType(PreIssueEInvoiceActionSheet), findsOneWidget);

        queryClient.clear();
      },
    );

    testWidgets(
      'auto progress lands on safe failure and retry returns to processing',
      (tester) async {
        final sequencedClient = QueryClient(
          options: const QueryClientOptions(
            queries: QueryOptionsDefaults(retry: 0, staleTime: Duration.zero),
          ),
        );
        addTearDown(sequencedClient.dispose);
        final mediator = _SequencedProjectionMediator(
          const [
            OrderInvoiceProjectionDto(
              salesOrderId: 'so-fake-001',
              issuanceDisplayState: IssuanceDisplayState.processing,
              actions: [],
            ),
            OrderInvoiceProjectionDto(
              salesOrderId: 'so-fake-001',
              issuanceDisplayState: IssuanceDisplayState.failed,
              actions: [OrderInvoiceAction.issue],
            ),
            OrderInvoiceProjectionDto(
              salesOrderId: 'so-fake-001',
              issuanceDisplayState: IssuanceDisplayState.processing,
              actions: [],
            ),
          ],
          const IssuanceAttemptStatusDto(
            attemptId: 'attempt-1',
            status: IssuanceAttemptStatus.failed,
            internalFinalizationStatus: InternalFinalizationStatus.pending,
            hasElectronicInvoice: false,
            hasActiveOperation: false,
            failureCode: 'PROVIDER_REJECTED',
            lastErrorMessage: 'Nhà cung cấp từ chối hóa đơn',
          ),
        );
        late OrderEInvoiceCubit cubit;

        await tester.pumpWidget(
          _buildSequencedSubject(
            mediator,
            sequencedClient,
            onCubitCreated: (value) => cubit = value,
          ),
        );
        await tester.pump();
        expect(find.text(OrderEInvoiceCopy.badgeProcessing), findsOneWidget);

        await tester.pump(const Duration(seconds: 5));
        expect(find.text(OrderEInvoiceCopy.badgeIssueFailed), findsOneWidget);

        await tester.tap(find.byType(OrderEInvoiceRow));
        await tester.pumpAndSettle();
        expect(find.byType(IssuanceFailureBanner), findsOneWidget);
        expect(find.text('Thử lại'), findsNothing);

        await tester.tap(find.byKey(const Key('action_issue')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('action_confirm_issue')));
        await tester.pumpAndSettle();

        expect(mediator.commands.single, isA<RetryIssuanceCommand>());
        expect(
          cubit.state.projection.issuanceDisplayState,
          IssuanceDisplayState.processing,
        );
        expect(find.text(OrderEInvoiceCopy.badgeProcessing), findsOneWidget);
      },
    );
  });

  group('TH-08 Slice 5 SG-07 delivery from OrderEInvoiceSection', () {
    const issuedProjection = OrderInvoiceProjectionDto(
      salesOrderId: 'so-fake-001',
      issuanceDisplayState: IssuanceDisplayState.issued,
      deliveryDisplayState: DeliveryDisplayState.notSent,
      actions: [OrderInvoiceAction.view],
    );

    Future<void> openSendFlow(WidgetTester tester) async {
      await tester.tap(find.byType(OrderEInvoiceRow));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('action_send')));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'th08_e2e_e04_u02_sc01_01 send sheet submits inside sheet then refreshes',
      (tester) async {
        late _TestMediator mediator;
        late OrderEInvoiceCubit cubit;
        final sendGate = Completer<void>();

        await tester.pumpWidget(
          buildSubject(
            scenario: FakeEInvoiceScenario.sendSheetInitial,
            projection: issuedProjection,
            sendGate: sendGate,
            onMediatorCreated: (value) => mediator = value,
            onCubitCreated: (value) => cubit = value,
          ),
        );

        await openSendFlow(tester);

        expect(
          mediator.queries.whereType<GetSendInvoiceSheetContextQuery>(),
          hasLength(1),
        );
        expect(find.byType(OrderInvoiceSendSheet), findsOneWidget);
        expect(find.text('buyer@fake.test'), findsOneWidget);
        expect(
          find.text(OrderInvoiceDeliveryCopy.recipientHelper),
          findsOneWidget,
        );
        expect(mediator.commands.whereType<SendElectronicInvoiceCommand>(), isEmpty);

        final projectionBefore = mediator.queries
            .whereType<GetOrderInvoiceProjectionQuery>()
            .length;

        await tester.tap(find.byKey(const Key('action_send_invoice')));
        await tester.pump();

        expect(find.byType(OrderInvoiceSendSheet), findsOneWidget);
        expect(
          tester.widget<VTextField>(find.byKey(const Key('field_recipient_email'))).enabled,
          isFalse,
        );
        expect(
          tester.widget<VButton>(find.byKey(const Key('action_send_invoice'))).isLoading,
          isTrue,
        );
        expect(find.text('buyer@fake.test'), findsOneWidget);
        expect(
          find.text(OrderInvoiceDeliveryCopy.sendAction),
          findsOneWidget,
        );
        expect(
          mediator.commands.whereType<SendElectronicInvoiceCommand>(),
          hasLength(1),
        );

        sendGate.complete();
        await tester.pumpAndSettle();

        expect(find.byType(OrderInvoiceSendSheet), findsNothing);
        expect(
          mediator.queries.whereType<GetOrderInvoiceProjectionQuery>().length,
          greaterThan(projectionBefore),
        );
        expect(cubit.state.salesOrderId, 'so-fake-001');
      },
    );

    testWidgets('resend mode opens OrderInvoiceResendSheet', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          scenario: FakeEInvoiceScenario.sendSheetResend,
          projection: const OrderInvoiceProjectionDto(
            salesOrderId: 'so-fake-001',
            issuanceDisplayState: IssuanceDisplayState.issued,
            deliveryDisplayState: DeliveryDisplayState.sent,
            actions: [OrderInvoiceAction.view],
          ),
        ),
      );

      await openSendFlow(tester);

      expect(find.byType(OrderInvoiceResendSheet), findsOneWidget);
      expect(find.text(OrderInvoiceDeliveryCopy.resendTitle), findsOneWidget);
      expect(find.text(OrderInvoiceDeliveryCopy.viewHistory), findsOneWidget);
    });

    testWidgets('cancel before submit does not send command', (tester) async {
      late _TestMediator mediator;
      await tester.pumpWidget(
        buildSubject(
          scenario: FakeEInvoiceScenario.sendSheetInitial,
          projection: issuedProjection,
          onMediatorCreated: (value) => mediator = value,
        ),
      );

      await openSendFlow(tester);
      await tester.tap(find.byKey(const Key('action_cancel_send')));
      await tester.pumpAndSettle();

      expect(find.byType(OrderInvoiceSendSheet), findsNothing);
      expect(mediator.commands.whereType<SendElectronicInvoiceCommand>(), isEmpty);
    });

    testWidgets(
      'send failure keeps sheet and shows safe SnackBar without raw code',
      (tester) async {
        await tester.pumpWidget(
          buildSubject(
            scenario: FakeEInvoiceScenario.sendInvalidEmail,
            projection: issuedProjection,
          ),
        );

        await openSendFlow(tester);
        await tester.tap(find.byKey(const Key('action_send_invoice')));
        await tester.pumpAndSettle();

        expect(find.byType(OrderInvoiceSendSheet), findsOneWidget);
        expect(find.text('buyer@fake.test'), findsOneWidget);
        expect(find.byType(SnackBar), findsOneWidget);
        expect(
          find.text(OrderInvoiceDeliveryErrorMessage.fallback),
          findsOneWidget,
        );
        expect(find.textContaining('Invalid email'), findsNothing);
        expect(find.textContaining('VALIDATION'), findsNothing);
      },
    );

    testWidgets('operationLocked opens locked sheet and blocks send', (
      tester,
    ) async {
      late _TestMediator mediator;
      await tester.pumpWidget(
        buildSubject(
          scenario: FakeEInvoiceScenario.sendSheetInitial,
          projection: issuedProjection,
          sheetContextOverride: const SendInvoiceSheetContextDto(
            mode: SendInvoiceSheetMode.send,
            suggestedEmail: 'buyer@fake.test',
            suggestedEmailSource: DeliveryRecipientSource.currentPartnerProfile,
            history: [],
            operationLocked: true,
            displayState: DeliveryDisplayState.sending,
          ),
          onMediatorCreated: (value) => mediator = value,
        ),
      );

      await openSendFlow(tester);

      expect(find.byType(OrderInvoiceSendSheet), findsOneWidget);
      expect(
        tester.widget<VTextField>(find.byKey(const Key('field_recipient_email'))).enabled,
        isFalse,
      );
      expect(
        tester.widget<VButton>(find.byKey(const Key('action_send_invoice'))).onPressed,
        isNull,
      );
      expect(mediator.commands.whereType<SendElectronicInvoiceCommand>(), isEmpty);
    });

    testWidgets('deliveryPending locks send on post-issue sheet', (
      tester,
    ) async {
      late OrderEInvoiceCubit cubit;
      const pendingProjection = OrderInvoiceProjectionDto(
        salesOrderId: 'so-fake-001',
        issuanceDisplayState: IssuanceDisplayState.issued,
        deliveryDisplayState: DeliveryDisplayState.sending,
        deliveryPending: true,
        actions: [OrderInvoiceAction.view],
      );

      await tester.pumpWidget(
        buildSubject(
          scenario: FakeEInvoiceScenario.sendSheetInitial,
          projection: pendingProjection,
          onCubitCreated: (value) => cubit = value,
        ),
      );
      cubit.emit(cubit.state.copyWith(projection: pendingProjection));
      await tester.pump();

      await tester.tap(find.byType(OrderEInvoiceRow));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<app_ei.EInvoiceActionItem>(
              find.byKey(const Key('action_send')),
            )
            .enabled,
        isFalse,
      );
      expect(find.byType(OrderInvoiceSendSheet), findsNothing);
    });

    testWidgets('double tap send CTA creates one command', (tester) async {
      late _TestMediator mediator;
      final sendGate = Completer<void>();

      await tester.pumpWidget(
        buildSubject(
          scenario: FakeEInvoiceScenario.sendSheetInitial,
          projection: issuedProjection,
          sendGate: sendGate,
          onMediatorCreated: (value) => mediator = value,
        ),
      );

      await openSendFlow(tester);
      await tester.tap(find.byKey(const Key('action_send_invoice')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('action_send_invoice')));
      await tester.pump();

      expect(
        mediator.commands.whereType<SendElectronicInvoiceCommand>(),
        hasLength(1),
      );

      sendGate.complete();
      await tester.pumpAndSettle();
    });

    testWidgets(
      'secondary attention from projection keeps sent badge on post-issue',
      (tester) async {
        late OrderEInvoiceCubit cubit;
        const secondaryProjection = OrderInvoiceProjectionDto(
          salesOrderId: 'so-fake-001',
          issuanceDisplayState: IssuanceDisplayState.issued,
          deliveryDisplayState: DeliveryDisplayState.sent,
          hasSecondaryAttention: true,
          deliveryPending: false,
          actions: [OrderInvoiceAction.view],
        );

        await tester.pumpWidget(
          buildSubject(
            scenario: FakeEInvoiceScenario.sendSheetResend,
            projection: secondaryProjection,
            onCubitCreated: (value) => cubit = value,
          ),
        );
        cubit.emit(cubit.state.copyWith(projection: secondaryProjection));
        await tester.pump();

        await tester.tap(find.byType(OrderEInvoiceRow));
        await tester.pumpAndSettle();

        expect(find.text(OrderEInvoiceCopy.badgeIssued), findsOneWidget);
        expect(
          find.text(OrderEInvoicePostIssueCopy.deliverySent),
          findsOneWidget,
        );
        expect(
          find.text(OrderEInvoicePostIssueCopy.deliverySecondaryAttention),
          findsOneWidget,
        );
        expect(
          find.text(OrderEInvoicePostIssueCopy.deliverySendFailed),
          findsNothing,
        );
      },
    );

    testWidgets(
      'unknown latest delivery unlocks resend and allows new send command',
      (tester) async {
        late _TestMediator mediator;
        await tester.pumpWidget(
          buildSubject(
            scenario: FakeEInvoiceScenario.sendSheetUnknown,
            projection: const OrderInvoiceProjectionDto(
              salesOrderId: 'so-fake-001',
              issuanceDisplayState: IssuanceDisplayState.issued,
              deliveryDisplayState: DeliveryDisplayState.unknown,
              actions: [OrderInvoiceAction.view],
            ),
            onMediatorCreated: (value) => mediator = value,
          ),
        );

        await openSendFlow(tester);

        expect(find.byType(OrderInvoiceResendSheet), findsOneWidget);
        expect(find.byType(AlertDialog), findsNothing);
        expect(find.textContaining('WARNING'), findsNothing);

        await tester.tap(find.byKey(const Key('action_send_invoice')));
        await tester.pumpAndSettle();

        expect(
          mediator.commands.whereType<SendElectronicInvoiceCommand>(),
          hasLength(1),
        );
        expect(find.byType(OrderInvoiceResendSheet), findsNothing);
      },
    );

    testWidgets(
      'section never issues StartAutoDeliveryCommand from UI',
      (tester) async {
        late _TestMediator mediator;
        await tester.pumpWidget(
          buildSubject(
            scenario: FakeEInvoiceScenario.sendSheetInitial,
            projection: issuedProjection,
            onMediatorCreated: (value) => mediator = value,
          ),
        );

        await openSendFlow(tester);
        await tester.tap(find.byKey(const Key('action_cancel_send')));
        await tester.pumpAndSettle();

        expect(
          mediator.commands.whereType<StartAutoDeliveryCommand>(),
          isEmpty,
        );
      },
    );
  });
}

final class _GatedProjectionMediator implements IModuleMediator {
  _GatedProjectionMediator(this.delegate, this.gate);

  final IModuleMediator delegate;
  final Completer<void> gate;
  final List<ICommand<dynamic>> commands = [];

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    if (query is GetOrderInvoiceProjectionQuery) {
      await gate.future;
      return const OrderInvoiceProjectionDto(
            salesOrderId: 'so-fake-001',
            issuanceDisplayState: IssuanceDisplayState.notIssued,
            actions: [OrderInvoiceAction.issue],
          )
          as TResult;
    }
    if (query is GetIssuanceReadinessQuery) {
      await gate.future;
      return const IssuanceReadinessDto(
            level: IssuanceReadinessLevel.ready,
            blockers: [],
            warnings: [],
            buyerCompletionState: BuyerCompletionStatus.open,
          )
          as TResult;
    }
    return delegate.executeQueryAsync(query);
  }

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    commands.add(command);
    return delegate.executeCommandAsync(command);
  }
}

final class _SequencedProjectionMediator implements IModuleMediator {
  _SequencedProjectionMediator(this.projections, this.failure);

  final List<OrderInvoiceProjectionDto> projections;
  final IssuanceAttemptStatusDto failure;
  final List<ICommand<dynamic>> commands = [];
  int projectionIndex = 0;

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    if (query is GetOrderInvoiceProjectionQuery) {
      final index = projectionIndex < projections.length ? projectionIndex : projections.length - 1;
      projectionIndex++;
      return projections[index] as TResult;
    }
    if (query is GetIssuanceReadinessQuery) {
      return const IssuanceReadinessDto(
            level: IssuanceReadinessLevel.ready,
            blockers: [],
            warnings: [],
            buyerCompletionState: BuyerCompletionStatus.open,
          )
          as TResult;
    }
    if (query is GetIssuanceAttemptStatusQuery) return failure as TResult;
    if (query is GetIssuanceProfileQuery || query is ListProviderTemplatesQuery) {
      throw UnsupportedError('optional template query');
    }
    throw UnsupportedError('Unexpected query $query');
  }

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) async {
    commands.add(command);
    if (command is RetryIssuanceCommand) {
      return const IssueInvoiceResultDto(
            issuanceId: 'issuance-1',
            attemptId: 'attempt-2',
            status: IssuanceAttemptStatus.preparing,
          )
          as TResult;
    }
    throw UnsupportedError('Unexpected command $command');
  }
}

Widget _buildSequencedSubject(
  _SequencedProjectionMediator mediator,
  QueryClient queryClient, {
  void Function(OrderEInvoiceCubit)? onCubitCreated,
}) {
  return QueryClientProvider(
    client: queryClient,
    child: MaterialApp(
      theme: VTheme.lightTheme,
      home: Scaffold(
        body: OrderEInvoiceSection(
          salesOrderId: 'so-fake-001',
          orderCode: 'DH-001',
          orderVersion: 1,
          initialProjection: const OrderInvoiceProjectionDto(
            salesOrderId: 'so-fake-001',
            issuanceDisplayState: IssuanceDisplayState.processing,
            actions: [],
          ),
          mediator: mediator,
          executionContext: FakeExecutionContext(
            tenantId: 'tenant-fake',
            userId: 'actor-fake',
          ),
          onCubitCreated: onCubitCreated,
        ),
      ),
    ),
  );
}
