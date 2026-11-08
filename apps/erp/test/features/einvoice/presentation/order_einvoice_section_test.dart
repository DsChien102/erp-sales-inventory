import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/features/einvoice/data/einvoice_errors.dart';
import 'package:erp/features/einvoice/data/models.dart';
import 'package:erp/features/einvoice/logic/einvoice_error_messages.dart';
import 'package:erp/features/einvoice/presentation/support/order_einvoice_copy.dart';
import 'package:erp/features/einvoice/presentation/widgets/issuance_failure_banner.dart';
import 'package:erp/features/einvoice/presentation/widgets/issue_invoice_confirmation_sheet.dart';
import 'package:erp/features/einvoice/presentation/widgets/order_einvoice_row.dart';
import 'package:erp/features/einvoice/presentation/widgets/pre_issue_einvoice_action_sheet.dart';
import 'package:erp/features/einvoice/logic/order_einvoice_cubit.dart';
import 'package:erp/features/einvoice/logic/order_einvoice_idempotency_key_factory.dart';
import 'package:erp/features/einvoice/logic/order_einvoice_state.dart';
import 'package:erp/features/einvoice/presentation/support/order_einvoice_post_issue_copy.dart';
import 'package:erp/features/einvoice/presentation/support/order_invoice_delivery_copy.dart';
import 'package:erp/features/einvoice/presentation/widgets/einvoice_action_item.dart';
import 'package:erp/features/einvoice/presentation/widgets/invoice_documents_action_sheet.dart';
import 'package:erp/features/einvoice/presentation/widgets/order_einvoice_section.dart';
import 'package:erp/features/einvoice/presentation/widgets/post_issue_einvoice_action_sheet.dart';
import 'package:erp/features/einvoice/presentation/widgets/resend_invoice_sheet.dart';
import 'package:erp/features/einvoice/presentation/widgets/send_invoice_sheet.dart';

import '../support/fake_einvoice_configuration_repository.dart';
import '../support/fake_einvoice_repository.dart';
import 'package:erp/features/einvoice/data/i_invoice_document_exporter.dart';

class RetryIssuanceCommand {
  const RetryIssuanceCommand({required this.salesOrderId, required this.expectedOrderVersion, required this.idempotencyKey});
  final String salesOrderId;
  final int expectedOrderVersion;
  final String idempotencyKey;
}

class GetSendInvoiceSheetContextQuery {
  const GetSendInvoiceSheetContextQuery({this.salesOrderId});
  final String? salesOrderId;
}

class SendElectronicInvoiceCommand {
  const SendElectronicInvoiceCommand({required this.salesOrderId, required this.recipientEmail, required this.idempotencyKey});
  final String salesOrderId;
  final String recipientEmail;
  final String idempotencyKey;
}

class GetOrderInvoiceProjectionQuery {
  const GetOrderInvoiceProjectionQuery({this.salesOrderId});
  final String? salesOrderId;
}

class StartAutoDeliveryCommand {
  const StartAutoDeliveryCommand();
}

final class _RecordingExporter implements IInvoiceDocumentExporter {
  _RecordingExporter();

  final bool result = true;
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

final class _TestMediator extends FakeEInvoiceRepository {
  _TestMediator(
    FakeEInvoiceScenario scenario, {
    this.officialViewGate,
    this.documentGate,
    this.previewGate,
    this.sendGate,
    SendInvoiceSheetContextDto? sheetContextOverride,
    OrderInvoiceProjectionDto? projectionOverride,
  }) : super() {
    final configured = FakeEInvoiceRepository.forScenario(scenario);
    projection = projectionOverride ?? configured.projection;
    readiness = configured.readiness;
    attemptStatus = configured.attemptStatus;
    requestPreviewResult = configured.requestPreviewResult;
    officialViewResult = configured.officialViewResult;
    documentResult = configured.documentResult;
    documentResults = List.of(configured.documentResults);
    previewResults = List.of(configured.previewResults);
    detailResults = List.of(configured.detailResults);
    issueResult = configured.issueResult;
    sendContext = sheetContextOverride ?? configured.sendContext;
    sendResult = configured.sendResult;
    history = configured.history;
    throwOn.addAll(configured.throwOn);
  }

  final Completer<void>? officialViewGate;
  final Completer<void>? documentGate;
  final Completer<void>? previewGate;
  final Completer<void>? sendGate;
  final List<dynamic> queries = [];
  final List<dynamic> commands = [];

  @override
  Future<OrderInvoiceProjectionDto> getProjection(String salesOrderId) async {
    queries.add(GetOrderInvoiceProjectionQuery(salesOrderId: salesOrderId));
    return super.getProjection(salesOrderId);
  }

  @override
  Future<IssueInvoiceResultDto> retry({
    required String salesOrderId,
    required int expectedOrderVersion,
    required String idempotencyKey,
    bool? acknowledgeWarnings,
  }) async {
    commands.add(RetryIssuanceCommand(
      salesOrderId: salesOrderId,
      expectedOrderVersion: expectedOrderVersion,
      idempotencyKey: idempotencyKey,
    ));
    return super.retry(
      salesOrderId: salesOrderId,
      expectedOrderVersion: expectedOrderVersion,
      idempotencyKey: idempotencyKey,
      acknowledgeWarnings: acknowledgeWarnings,
    );
  }

  @override
  Future<OfficialInvoiceViewDto> requestOfficialView(String salesOrderId) async {
    if (officialViewGate != null) await officialViewGate!.future;
    return super.requestOfficialView(salesOrderId);
  }

  @override
  Future<InvoiceDocumentRetrievalDto> requestDocument({
    required String salesOrderId,
    required InvoiceDocumentType documentType,
  }) async {
    if (documentGate != null) await documentGate!.future;
    return super.requestDocument(salesOrderId: salesOrderId, documentType: documentType);
  }

  @override
  Future<InvoicePreviewResultDto> requestPreview({
    required String salesOrderId,
    required int expectedOrderVersion,
  }) async {
    if (previewGate != null) await previewGate!.future;
    return super.requestPreview(salesOrderId: salesOrderId, expectedOrderVersion: expectedOrderVersion);
  }

  @override
  Future<SendInvoiceSheetContextDto> getSendSheetContext(String salesOrderId) async {
    queries.add(GetSendInvoiceSheetContextQuery(salesOrderId: salesOrderId));
    return super.getSendSheetContext(salesOrderId);
  }

  @override
  Future<SendInvoiceResultDto> send({
    required String salesOrderId,
    required String recipientEmail,
    required String idempotencyKey,
  }) async {
    commands.add(SendElectronicInvoiceCommand(
      salesOrderId: salesOrderId,
      recipientEmail: recipientEmail,
      idempotencyKey: idempotencyKey,
    ));
    if (sendGate != null) await sendGate!.future;
    return super.send(salesOrderId: salesOrderId, recipientEmail: recipientEmail, idempotencyKey: idempotencyKey);
  }
}

final class _ProjectionOverrideMediator extends FakeEInvoiceRepository {
  _ProjectionOverrideMediator(this.delegate, {required this.projectionFn}) : super();

  final FakeEInvoiceRepository delegate;
  final OrderInvoiceProjectionDto Function() projectionFn;

  @override
  Future<OrderInvoiceProjectionDto> getProjection(String salesOrderId) async {
    return projectionFn();
  }
}

void main() {
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
    final mediator = _TestMediator(
      scenario,
      officialViewGate: officialViewGate,
      documentGate: documentGate,
      previewGate: previewGate,
      sendGate: sendGate,
      sheetContextOverride: sheetContextOverride,
      projectionOverride: projection,
    );
    onMediatorCreated?.call(mediator);
    final configurationRepository = FakeEInvoiceConfigurationRepository(
      scenario: scenario == FakeEInvoiceScenario.configReadinessBlocked
          ? FakeEInvoiceConfigurationScenario.configReadinessBlocked
          : FakeEInvoiceConfigurationScenario.connectionScreenOk,
    );

    return MaterialApp(
      theme: VTheme.lightTheme,
      home: Scaffold(
        body: OrderEInvoiceSection(
          salesOrderId: 'so-fake-001',
          orderCode: 'DH-001',
          orderVersion: 1,
          initialProjection: projection,
          hasLoadedInitialProjection: hasLoadedInitialProjection,
          isBuyerNotReady: isBuyerNotReady,
          repository: mediator,
          configurationRepository: configurationRepository,
          documentExporter: documentExporter,
          idempotencyKeyFactory: keyFactory,
          onCubitCreated: onCubitCreated,
        ),
      ),
    );
  }

  Widget buildCorrectionSubject({String? buyerPartnerId}) {
    final mediator = _TestMediator(FakeEInvoiceScenario.previewOk);
    final configurationRepository = FakeEInvoiceConfigurationRepository();
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: OrderEInvoiceSection(
              salesOrderId: 'so-fake-001',
              orderCode: 'DH-001',
              orderVersion: 1,
              initialProjection: const OrderInvoiceProjectionDto(
                salesOrderId: 'so-fake-001',
                issuanceDisplayState: IssuanceDisplayState.failed,
                actions: [OrderInvoiceAction.issue],
              ),
              isBuyerNotReady: true,
              buyerPartnerId: buyerPartnerId,
              repository: mediator,
              configurationRepository: configurationRepository,
            ),
          ),
        ),
        GoRoute(
          path: '/partner/:partnerId/edit',
          builder: (context, state) => Scaffold(
            body: Text('edit-${state.pathParameters['partnerId']}'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    return MaterialApp.router(
      theme: VTheme.lightTheme,
      routerConfig: router,
    );
  }

  testWidgets('open action sheet follows delivery updates without reopening', (tester) async {
    var liveProjection = const OrderInvoiceProjectionDto(
      salesOrderId: 'so-fake-001',
      issuanceDisplayState: IssuanceDisplayState.issued,
      deliveryDisplayState: DeliveryDisplayState.sending,
      actions: [],
    );
    final mediator = _TestMediator(FakeEInvoiceScenario.retryAfterFailOk);
    final configurationRepository = FakeEInvoiceConfigurationRepository();
    final cubit = OrderEInvoiceCubit(
      salesOrderId: 'so-fake-001',
      orderVersion: 1,
      initialProjection: liveProjection,
      repository: _ProjectionOverrideMediator(
        mediator,
        projectionFn: () => liveProjection,
      ),
      configurationRepository: configurationRepository,
    );
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: Scaffold(
          body: OrderEInvoiceSection(
            salesOrderId: 'so-fake-001',
            orderCode: 'DH-001',
            orderVersion: 1,
            initialProjection: liveProjection,
            repository: mediator,
            configurationRepository: configurationRepository,
            cubit: cubit,
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
            .widget<EInvoiceActionItem>(
              find.byKey(const Key('action_view_official')),
            )
            .loading,
        isTrue,
      );
      expect(
        tester
            .widget<EInvoiceActionItem>(
              find.byKey(const Key('action_documents')),
            )
            .enabled,
        isFalse,
      );
      expect(
        tester
            .widget<EInvoiceActionItem>(
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
            .widget<EInvoiceActionItem>(
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
          .widget<EInvoiceActionItem>(
            find.byKey(const Key('action_save_pdf')),
          )
          .loading,
      isTrue,
    );
    expect(
      tester
          .widget<EInvoiceActionItem>(
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
            .widget<EInvoiceActionItem>(
              find.byKey(const Key('action_save_xml')),
            )
            .enabled,
        isTrue,
      );
      expect(
        tester
            .widget<EInvoiceActionItem>(
              find.byKey(const Key('action_save_pdf')),
            )
            .enabled,
        isTrue,
      );
      expect(
        tester
            .widget<EInvoiceActionItem>(
              find.byKey(const Key('action_save_pdf')),
            )
            .loading,
        isFalse,
      );
      expect(find.text(OrderEInvoiceCopy.badgeIssued), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('issue without a saved template shows the template toast', (tester) async {
    await tester.pumpWidget(
      buildSubject(
        scenario: FakeEInvoiceScenario.configReadinessBlocked,
        projection: const OrderInvoiceProjectionDto(
          salesOrderId: 'so-fake-001',
          issuanceDisplayState: IssuanceDisplayState.failed,
          actions: [OrderInvoiceAction.issue],
        ),
      ),
    );
    await tester.tap(find.byType(OrderEInvoiceRow));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('action_issue')));
    await tester.pumpAndSettle();

    expect(find.byType(IssueInvoiceConfirmationSheet), findsNothing);
    expect(
      find.text('Chưa chọn mẫu hóa đơn. Vui lòng cập nhật cấu hình phát hành.'),
      findsOneWidget,
    );
  });

  testWidgets('preview failure closes the sheet and shows a toast', (tester) async {
    await tester.pumpWidget(
      buildSubject(
        scenario: FakeEInvoiceScenario.previewConfigNotReady,
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

    await tester.tap(find.byKey(const Key('action_preview')));
    await tester.pumpAndSettle();

    expect(find.byType(PreIssueEInvoiceActionSheet), findsNothing);
    expect(
      find.text('Chưa chọn mẫu hóa đơn. Vui lòng cập nhật cấu hình phát hành.'),
      findsOneWidget,
    );
  });

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

  testWidgets('buyer correction opens the customer edit screen', (tester) async {
    await tester.pumpWidget(buildCorrectionSubject(buyerPartnerId: 'customer-1'));
    await tester.tap(find.byType(OrderEInvoiceRow));
    await tester.pumpAndSettle();

    expect(find.text(OrderEInvoiceCopy.buyerWarningTitle), findsOneWidget);
    await tester.tap(find.text(OrderEInvoiceCopy.buyerCorrectionAction));
    await tester.pumpAndSettle();

    expect(find.text('edit-customer-1'), findsOneWidget);
  });

  testWidgets('buyer correction link stays hidden without a partner', (tester) async {
    await tester.pumpWidget(buildCorrectionSubject());
    await tester.tap(find.byType(OrderEInvoiceRow));
    await tester.pumpAndSettle();

    expect(find.text(OrderEInvoiceCopy.buyerWarningTitle), findsOneWidget);
    expect(find.text(OrderEInvoiceCopy.buyerCorrectionAction), findsNothing);
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
    testWidgets('provider not connected disables issue and keeps preview enabled', (
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
          onCubitCreated: (cubit) {
            cubit.emit(
              cubit.state.copyWith(
                readiness: const IssuanceReadinessDto(
                  level: IssuanceReadinessLevel.notReady,
                  blockers: [
                    ReadinessBlockerDto(
                      code: EInvoiceErrorCodes.providerNotConnected,
                      message: 'Chưa kết nối nhà cung cấp',
                    ),
                  ],
                  warnings: [],
                  buyerCompletionState: BuyerCompletionStatus.locked,
                ),
              ),
            );
          },
        ),
      );

      await tester.tap(find.byType(OrderEInvoiceRow));
      await tester.pumpAndSettle();

      expect(
        tester.widget<EInvoiceActionItem>(find.byKey(const Key('action_issue'))).enabled,
        isFalse,
      );
      expect(
        tester.widget<EInvoiceActionItem>(find.byKey(const Key('action_preview'))).enabled,
        isTrue,
      );
    });

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
        final mediator = _GatedProjectionMediator(gate);
        final configurationRepository = FakeEInvoiceConfigurationRepository();
        OrderEInvoiceCubit? cubit;

        await tester.pumpWidget(
          MaterialApp(
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
                repository: mediator,
                configurationRepository: configurationRepository,
                onCubitCreated: (value) => cubit = value,
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
      },
    );

    testWidgets(
      'auto progress lands on safe failure and retry returns to processing',
      (tester) async {
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
          find.text(einvoiceDeliveryFallbackMessage),
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
            .widget<EInvoiceActionItem>(
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

final class _GatedProjectionMediator extends FakeEInvoiceRepository {
  _GatedProjectionMediator(this.gate) : super();

  final Completer<void> gate;
  final List<dynamic> commands = [];

  @override
  Future<OrderInvoiceProjectionDto> getProjection(String salesOrderId) async {
    await gate.future;
    return const OrderInvoiceProjectionDto(
      salesOrderId: 'so-fake-001',
      issuanceDisplayState: IssuanceDisplayState.notIssued,
      actions: [OrderInvoiceAction.issue],
    );
  }

  @override
  Future<IssuanceReadinessDto> getReadiness(String salesOrderId) async {
    await gate.future;
    return const IssuanceReadinessDto(
      level: IssuanceReadinessLevel.ready,
      blockers: [],
      warnings: [],
      buyerCompletionState: BuyerCompletionStatus.open,
    );
  }
}

final class _SequencedProjectionMediator extends FakeEInvoiceRepository {
  _SequencedProjectionMediator(this.projections, this.failure) : super();

  final List<OrderInvoiceProjectionDto> projections;
  final IssuanceAttemptStatusDto failure;
  final List<dynamic> commands = [];
  int projectionIndex = 0;

  @override
  Future<OrderInvoiceProjectionDto> getProjection(String salesOrderId) async {
    final index = projectionIndex < projections.length ? projectionIndex : projections.length - 1;
    projectionIndex++;
    return projections[index];
  }

  @override
  Future<IssuanceReadinessDto> getReadiness(String salesOrderId) async {
    return const IssuanceReadinessDto(
      level: IssuanceReadinessLevel.ready,
      blockers: [],
      warnings: [],
      buyerCompletionState: BuyerCompletionStatus.open,
    );
  }

  @override
  Future<IssuanceAttemptStatusDto> getAttemptStatus(String salesOrderId) async {
    return failure;
  }

  @override
  Future<IssueInvoiceResultDto> retry({
    required String salesOrderId,
    required int expectedOrderVersion,
    required String idempotencyKey,
    bool? acknowledgeWarnings,
  }) async {
    commands.add(RetryIssuanceCommand(
      salesOrderId: salesOrderId,
      expectedOrderVersion: expectedOrderVersion,
      idempotencyKey: idempotencyKey,
    ));
    return const IssueInvoiceResultDto(
      issuanceId: 'issuance-1',
      attemptId: 'attempt-2',
      status: IssuanceAttemptStatus.preparing,
    );
  }
}

Widget _buildSequencedSubject(
  _SequencedProjectionMediator mediator, {
  void Function(OrderEInvoiceCubit)? onCubitCreated,
}) {
  return MaterialApp(
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
        repository: mediator,
        configurationRepository: FakeEInvoiceConfigurationRepository(),
        onCubitCreated: onCubitCreated,
      ),
    ),
  );
}
