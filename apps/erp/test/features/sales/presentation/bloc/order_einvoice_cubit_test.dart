import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:erp/features/sales/presentation/bloc/order_einvoice_cubit.dart';
import 'package:erp/features/sales/presentation/bloc/order_einvoice_state.dart';
import 'package:erp/features/sales/presentation/services/i_invoice_document_exporter.dart';
import 'package:erp/features/sales/presentation/services/i_invoice_viewer_launcher.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

final class _RecordingLauncher implements IInvoiceViewerLauncher {
  final List<String> launchedUrls = [];

  @override
  Future<bool> launch(String url) async {
    launchedUrls.add(url);
    return true;
  }
}

final class _RecordingExporter implements IInvoiceDocumentExporter {
  final List<({String filename, InvoiceDocumentType type, String? url})> exported = [];

  @override
  Future<bool> exportDocument({
    required String filename,
    required InvoiceDocumentType type,
    String? url,
    List<int>? bytes,
  }) async {
    exported.add((filename: filename, type: type, url: url));
    return true;
  }
}

final class _ConfigurableMediator implements IModuleMediator {
  final List<dynamic> executedCommands = [];
  final List<dynamic> executedQueries = [];

  Object? commandResult;
  Future<Object?>? commandResultFuture;
  Object? Function(ICommand<dynamic> command)? commandResultBuilder;
  Object? queryResult;
  Object? Function(IQuery<dynamic> query)? queryResultBuilder;
  Exception? errorToThrow;

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) async {
    executedCommands.add(command);
    if (errorToThrow != null) throw errorToThrow!;
    if (commandResultBuilder != null) {
      return commandResultBuilder!(command) as TResult;
    }
    if (commandResultFuture != null) {
      return (await commandResultFuture) as TResult;
    }
    if (commandResult != null) return commandResult as TResult;
    if (command is IssueInvoiceCommand) {
      return const IssueInvoiceResultDto(
            issuanceId: 'iss-1',
            attemptId: 'att-1',
            status: IssuanceAttemptStatus.preparing,
          )
          as TResult;
    }
    return null as TResult;
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    executedQueries.add(query);
    if (errorToThrow != null) throw errorToThrow!;
    if (query is GetIssuanceReadinessQuery) {
      return const IssuanceReadinessDto(
            level: IssuanceReadinessLevel.ready,
            blockers: [],
            warnings: [],
            buyerCompletionState: BuyerCompletionStatus.open,
          )
          as TResult;
    }
    if (queryResultBuilder != null) {
      return queryResultBuilder!(query) as TResult;
    }
    if (query is GetIssuanceProfileQuery) {
      return const IssuanceProfileDto(
            profileVersion: 1,
            templateId: 'tpl-live',
            signingMethod: SigningMethod.hsm,
            compatibilityWarnings: [],
          )
          as TResult;
    }
    if (query is ListProviderTemplatesQuery) {
      return const [
            ProviderTemplateDto(
              templateId: 'tpl-live',
              name: 'Hóa đơn GTGT',
              serial: '1/001',
              symbol: '1C26TYY',
            ),
          ]
          as TResult;
    }
    return (queryResult as TResult?) ?? (null as TResult);
  }
}

void main() {
  group('OrderEInvoiceCubit', () {
    late FakeExecutionContext executionContext;
    late _ConfigurableMediator mediator;
    late _RecordingLauncher launcher;
    late _RecordingExporter exporter;

    setUp(() {
      executionContext = FakeExecutionContext(
        tenantId: 'tenant-test',
        userId: 'actor-test',
      );
      mediator = _ConfigurableMediator();
      launcher = _RecordingLauncher();
      exporter = _RecordingExporter();
    });

    OrderEInvoiceCubit createCubit({
      OrderInvoiceProjectionDto? initialProjection,
      IssuanceReadinessDto? initialReadiness,
      bool isBuyerNotReady = false,
    }) {
      return OrderEInvoiceCubit(
        salesOrderId: 'order-101',
        orderVersion: 1,
        initialProjection:
            initialProjection ??
            const OrderInvoiceProjectionDto(
              salesOrderId: 'order-101',
              issuanceDisplayState: IssuanceDisplayState.notIssued,
              actions: [OrderInvoiceAction.issue],
            ),
        initialReadiness: initialReadiness,
        isBuyerNotReady: isBuyerNotReady,
        executionContext: executionContext,
        mediator: mediator,
        viewerLauncher: launcher,
        documentExporter: exporter,
      );
    }

    test('manual refresh updates projection and readiness', () async {
      final cubit = createCubit();
      mediator.queryResult = const OrderInvoiceProjectionDto(
        salesOrderId: 'order-101',
        issuanceDisplayState: IssuanceDisplayState.issued,
        deliveryDisplayState: DeliveryDisplayState.sent,
        actions: [OrderInvoiceAction.view],
      );

      await cubit.refresh();

      expect(
        cubit.state.projection.issuanceDisplayState,
        IssuanceDisplayState.issued,
      );
      expect(
        cubit.state.projection.deliveryDisplayState,
        DeliveryDisplayState.sent,
      );
      expect(mediator.executedQueries.length, 4); // projection + readiness + profile + templates
      expect(cubit.state.templateSymbol, '1C26TYY');
      expect(cubit.state.templateNumber, '1/001');
      expect(cubit.state.authorityMode, 'Có mã CQT');
    });

    test('refresh keeps persisted deliveryPending from projection', () async {
      final cubit = createCubit();
      mediator.queryResult = const OrderInvoiceProjectionDto(
        salesOrderId: 'order-101',
        issuanceDisplayState: IssuanceDisplayState.issued,
        deliveryDisplayState: DeliveryDisplayState.sent,
        deliveryPending: true,
        actions: [OrderInvoiceAction.view],
      );

      await cubit.refresh();

      expect(cubit.state.projection.deliveryPending, isTrue);
      expect(
        cubit.state.projection.deliveryDisplayState,
        DeliveryDisplayState.sent,
      );
    });

    test('issueNow invokes IssueInvoiceCommand and triggers refresh', () async {
      final cubit = createCubit();
      mediator.commandResult = null;
      mediator.queryResult = const OrderInvoiceProjectionDto(
        salesOrderId: 'order-101',
        issuanceDisplayState: IssuanceDisplayState.processing,
        actions: [],
      );

      await cubit.issueNow();

      expect(mediator.executedCommands.length, 1);
      final cmd = mediator.executedCommands.first as IssueInvoiceCommand;
      expect(cmd.salesOrderId, 'order-101');
      expect(cmd.sourceVersion, '1');
      expect(
        cubit.state.projection.issuanceDisplayState,
        IssuanceDisplayState.processing,
      );
    });

    test('requestPreview emits viewer URL and delegates to launcher', () async {
      final cubit = createCubit();
      mediator.commandResult = const InvoicePreviewResultDto(
        viewerRef: 'https://testapi.meinvoice.vn/viewer/preview-1',
        warnings: [],
      );

      final url = await cubit.requestPreview();

      expect(url, 'https://testapi.meinvoice.vn/viewer/preview-1');
      expect(
        cubit.state.previewViewerUrl,
        'https://testapi.meinvoice.vn/viewer/preview-1',
      );
      expect(launcher.launchedUrls, [
        'https://testapi.meinvoice.vn/viewer/preview-1',
      ]);
    });

    test('requestPreview polls until viewerRef is available', () async {
      final cubit = createCubit();
      var previewPolls = 0;
      mediator.commandResult = const InvoicePreviewResultDto(
        viewerRef: null,
        warnings: [],
      );
      mediator.queryResultBuilder = (query) {
        if (query is GetInvoicePreviewQuery) {
          previewPolls++;
          if (previewPolls >= 3) {
            return const InvoicePreviewResultDto(
              viewerRef: 'https://testapi.meinvoice.vn/viewer/polled',
              warnings: [],
            );
          }
          return const InvoicePreviewResultDto(
            viewerRef: null,
            warnings: [],
          );
        }
        return null;
      };

      final url = await cubit.requestPreview(
        maxPollAttempts: 5,
        pollDelay: Duration.zero,
      );

      expect(url, 'https://testapi.meinvoice.vn/viewer/polled');
      expect(previewPolls, 3);
      expect(
        cubit.state.previewViewerUrl,
        'https://testapi.meinvoice.vn/viewer/polled',
      );
      expect(launcher.launchedUrls, [
        'https://testapi.meinvoice.vn/viewer/polled',
      ]);
    });

    test('requestPreview ignores concurrent taps while previewing', () async {
      final cubit = createCubit();
      final gate = Completer<InvoicePreviewResultDto>();
      mediator.commandResultFuture = gate.future;

      final first = cubit.requestPreview(
        maxPollAttempts: 0,
        pollDelay: Duration.zero,
      );
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.status, OrderEInvoiceStatus.previewing);

      final second = await cubit.requestPreview(
        maxPollAttempts: 0,
        pollDelay: Duration.zero,
      );
      expect(second, isNull);
      expect(mediator.executedCommands.length, 1);

      gate.complete(
        const InvoicePreviewResultDto(
          viewerRef: 'https://testapi.meinvoice.vn/viewer/first',
          warnings: [],
        ),
      );
      final firstUrl = await first;
      expect(firstUrl, 'https://testapi.meinvoice.vn/viewer/first');
    });

    test('requestPreview keeps prior viewer URL when poll times out', () async {
      final cubit = createCubit();
      mediator.commandResult = const InvoicePreviewResultDto(
        viewerRef: 'https://testapi.meinvoice.vn/viewer/prior',
        warnings: [],
      );
      await cubit.requestPreview(maxPollAttempts: 0, pollDelay: Duration.zero);
      expect(
        cubit.state.previewViewerUrl,
        'https://testapi.meinvoice.vn/viewer/prior',
      );

      mediator.commandResult = const InvoicePreviewResultDto(
        viewerRef: null,
        warnings: [],
      );
      mediator.queryResult = const InvoicePreviewResultDto(
        viewerRef: null,
        warnings: [],
      );

      final url = await cubit.requestPreview(
        maxPollAttempts: 1,
        pollDelay: Duration.zero,
      );

      expect(url, isNull);
      expect(cubit.state.status, OrderEInvoiceStatus.error);
      expect(
        cubit.state.errorMessage,
        'Xem trước hóa đơn chưa sẵn sàng. Vui lòng thử lại sau ít giây.',
      );
      expect(
        cubit.state.previewViewerUrl,
        'https://testapi.meinvoice.vn/viewer/prior',
      );
    });

    test('openOfficialView delegates to launcher on valid URL', () async {
      final cubit = createCubit(
        initialProjection: const OrderInvoiceProjectionDto(
          salesOrderId: 'order-101',
          issuanceDisplayState: IssuanceDisplayState.issued,
          actions: [OrderInvoiceAction.view],
        ),
      );
      mediator.commandResult = const OfficialInvoiceViewDto(
        viewerUrl: 'https://testapi.meinvoice.vn/viewer/official-1',
        status: InvoiceDocumentStatus.available,
      );

      final ok = await cubit.openOfficialView();

      expect(ok, isTrue);
      expect(
        cubit.state.officialViewerUrl,
        'https://testapi.meinvoice.vn/viewer/official-1',
      );
      expect(launcher.launchedUrls, [
        'https://testapi.meinvoice.vn/viewer/official-1',
      ]);
    });

    test('openOfficialView polls detail without enqueueing another command', () async {
      final cubit = createCubit(
        initialProjection: const OrderInvoiceProjectionDto(
          salesOrderId: 'order-101',
          issuanceDisplayState: IssuanceDisplayState.issued,
          actions: [OrderInvoiceAction.view],
        ),
      );
      mediator.commandResult = const OfficialInvoiceViewDto(
        operationId: 'official-op-1',
        status: InvoiceDocumentStatus.pending,
      );
      var detailReads = 0;
      mediator.queryResultBuilder = (query) {
        if (query is GetElectronicInvoiceDetailQuery) {
          detailReads++;
          return ElectronicInvoiceDetailDto(
            electronicInvoiceId: 'invoice-1',
            salesOrderId: 'order-101',
            officialViewOperationId: 'official-op-1',
            officialViewStatus: detailReads < 2
                ? InvoiceDocumentStatus.pending
                : InvoiceDocumentStatus.available,
            officialViewerUrl: detailReads < 2
                ? null
                : 'https://testapi.meinvoice.vn/viewer/official-poll',
          );
        }
        return null;
      };

      final ok = await cubit.openOfficialView(pollDelay: Duration.zero);

      expect(ok, isTrue);
      expect(
        mediator.executedCommands.whereType<RequestOfficialInvoiceViewCommand>(),
        hasLength(1),
      );
      expect(detailReads, 2);
      expect(launcher.launchedUrls, [
        'https://testapi.meinvoice.vn/viewer/official-poll',
      ]);
    });

    test('openOfficialView aborts polling when cubit is closed', () async {
      final cubit = createCubit(
        initialProjection: const OrderInvoiceProjectionDto(
          salesOrderId: 'order-101',
          issuanceDisplayState: IssuanceDisplayState.issued,
          actions: [OrderInvoiceAction.view],
        ),
      );
      mediator.commandResult = const OfficialInvoiceViewDto(
        operationId: 'official-op-1',
        status: InvoiceDocumentStatus.pending,
      );
      var detailReads = 0;
      mediator.queryResultBuilder = (query) {
        if (query is GetElectronicInvoiceDetailQuery) {
          detailReads++;
          cubit.close();
          return const ElectronicInvoiceDetailDto(
            electronicInvoiceId: 'invoice-1',
            salesOrderId: 'order-101',
            officialViewOperationId: 'official-op-1',
            officialViewStatus: InvoiceDocumentStatus.pending,
          );
        }
        return null;
      };

      final ok = await cubit.openOfficialView(pollDelay: Duration.zero);

      expect(ok, isFalse);
      expect(detailReads, 1);
    });

    test('downloadDocument pdf delegates to document exporter', () async {
      final cubit = createCubit(
        initialProjection: const OrderInvoiceProjectionDto(
          salesOrderId: 'order-101',
          issuanceDisplayState: IssuanceDisplayState.issued,
          actions: [OrderInvoiceAction.downloadPdf],
        ),
      );
      mediator.commandResult = const InvoiceDocumentRetrievalDto(
        downloadUrl: 'https://storage.example.com/invoice-101.pdf',
        status: InvoiceDocumentStatus.available,
      );

      final ok = await cubit.downloadDocument(InvoiceDocumentType.pdf);

      expect(ok, isTrue);
      expect(exporter.exported.length, 1);
      expect(exporter.exported.first.type, InvoiceDocumentType.pdf);
      expect(
        exporter.exported.first.url,
        'https://storage.example.com/invoice-101.pdf',
      );
      expect(exporter.exported.first.filename, 'invoice_order-101.pdf');
    });

    test('downloadDocument polls GetInvoiceDocumentsQuery until document is available', () async {
      final cubit = createCubit(
        initialProjection: const OrderInvoiceProjectionDto(
          salesOrderId: 'order-101',
          issuanceDisplayState: IssuanceDisplayState.issued,
          actions: [OrderInvoiceAction.downloadPdf],
        ),
      );
      mediator.commandResult = const InvoiceDocumentRetrievalDto(
        operationId: 'doc-op-1',
        status: InvoiceDocumentStatus.pending,
      );
      var documentReads = 0;
      mediator.queryResultBuilder = (query) {
        if (query is GetInvoiceDocumentsQuery) {
          documentReads++;
          return InvoiceDocumentsDto(
            pdfAvailable: documentReads >= 2,
            xmlAvailable: false,
            retrievalStatus: documentReads < 2
                ? InvoiceDocumentStatus.pending
                : InvoiceDocumentStatus.available,
            pdf: InvoiceDocumentItemDto(
              documentType: InvoiceDocumentType.pdf,
              status: documentReads < 2
                  ? InvoiceDocumentStatus.pending
                  : InvoiceDocumentStatus.available,
              downloadUrl: documentReads < 2
                  ? null
                  : 'https://storage.example.com/invoice-poll.pdf',
            ),
          );
        }
        return null;
      };

      final ok = await cubit.downloadDocument(
        InvoiceDocumentType.pdf,
        pollDelay: Duration.zero,
      );

      expect(ok, isTrue);
      expect(
        mediator.executedCommands.whereType<RequestInvoiceDocumentCommand>(),
        hasLength(1),
      );
      expect(documentReads, 2);
      expect(exporter.exported.length, 1);
      expect(
        exporter.exported.first.url,
        'https://storage.example.com/invoice-poll.pdf',
      );
    });

    test('downloadDocument pending timeout surfaces error', () async {
      final cubit = createCubit(
        initialProjection: const OrderInvoiceProjectionDto(
          salesOrderId: 'order-101',
          issuanceDisplayState: IssuanceDisplayState.issued,
          actions: [OrderInvoiceAction.downloadPdf],
        ),
      );
      mediator.commandResult = const InvoiceDocumentRetrievalDto(
        operationId: 'doc-op-1',
        status: InvoiceDocumentStatus.pending,
      );
      mediator.queryResultBuilder = (query) {
        if (query is GetInvoiceDocumentsQuery) {
          return const InvoiceDocumentsDto(
            pdfAvailable: false,
            xmlAvailable: false,
            retrievalStatus: InvoiceDocumentStatus.pending,
          );
        }
        return null;
      };

      final ok = await cubit.downloadDocument(
        InvoiceDocumentType.pdf,
        maxPollAttempts: 2,
        pollDelay: Duration.zero,
      );

      expect(ok, isFalse);
      expect(cubit.state.status, OrderEInvoiceStatus.error);
      expect(
        cubit.state.errorMessage,
        'Đang chuẩn bị tài liệu hóa đơn. Vui lòng thử lại sau giây lát.',
      );
    });

    test('permission error surfaces human-friendly message', () async {
      final cubit = createCubit();
      mediator.errorToThrow = Exception('RPC error: NO_PERMISSION');

      await cubit.issueNow();

      expect(cubit.state.status, OrderEInvoiceStatus.error);
      expect(
        cubit.state.errorMessage,
        'Bạn không có quyền thực hiện thao tác này.',
      );
    });

    test('auto-refresh pauses when page inactive', () async {
      final cubit = createCubit();
      cubit.setPageActive(false);

      await cubit.refresh();

      expect(mediator.executedQueries, isEmpty);
    });

    test('getSendSheetContext queries mediator with correct parameters', () async {
      final cubit = createCubit();
      mediator.queryResult = const SendInvoiceSheetContextDto(
        mode: SendInvoiceSheetMode.send,
        suggestedEmail: 'customer@example.com',
        suggestedEmailSource: DeliveryRecipientSource.currentPartnerProfile,
        history: [],
        operationLocked: false,
        displayState: DeliveryDisplayState.notSent,
      );

      final result = await cubit.getSendSheetContext();

      expect(result, isNotNull);
      expect(result?.suggestedEmail, 'customer@example.com');
      expect(mediator.executedQueries.whereType<GetSendInvoiceSheetContextQuery>(), hasLength(1));
    });

    test('sendInvoiceEmail dispatches SendElectronicInvoiceCommand and triggers refresh', () async {
      final cubit = createCubit();
      mediator.commandResult = const SendInvoiceResultDto(
        deliveryId: 'del-1',
        status: DeliveryStatus.processing,
      );

      final ok = await cubit.sendInvoiceEmail('accounting@example.com');

      expect(ok, isTrue);
      final sendCommands = mediator.executedCommands.whereType<SendElectronicInvoiceCommand>();
      expect(sendCommands, hasLength(1));
      expect(sendCommands.first.recipientEmail, 'accounting@example.com');
      expect(sendCommands.first.salesOrderId, 'order-101');
    });

    test('sendInvoiceEmail returns false on empty email without executing command', () async {
      final cubit = createCubit();

      final ok = await cubit.sendInvoiceEmail('   ');

      expect(ok, isFalse);
      expect(mediator.executedCommands.whereType<SendElectronicInvoiceCommand>(), isEmpty);
    });

    test('sendInvoiceEmail surfaces human-friendly error on DELIVERY_NOT_SUPPORTED', () async {
      final cubit = createCubit();
      mediator.errorToThrow = Exception('RPC error: DELIVERY_NOT_SUPPORTED');

      final ok = await cubit.sendInvoiceEmail('test@example.com');

      expect(ok, isFalse);
      expect(cubit.state.status, OrderEInvoiceStatus.error);
      expect(
        cubit.state.errorMessage,
        'Cổng kết nối hóa đơn chưa hỗ trợ tính năng gửi email.',
      );
    });
  });
}
