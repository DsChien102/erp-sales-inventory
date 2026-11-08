import 'dart:async';

import 'package:erp/core/errors/app_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp/features/einvoice/data/models.dart';
import 'package:erp/features/einvoice/logic/einvoice_error_messages.dart';
import 'package:erp/features/einvoice/logic/order_einvoice_cubit.dart';
import 'package:erp/features/einvoice/logic/order_einvoice_state.dart';

import '../support/fake_einvoice_configuration_repository.dart';
import '../support/fake_einvoice_repository.dart';
import 'package:erp/features/einvoice/data/i_invoice_viewer_launcher.dart';
import 'package:erp/features/einvoice/data/i_invoice_document_exporter.dart';

class IssueInvoiceCommand {
  const IssueInvoiceCommand({required this.salesOrderId, required this.sourceVersion, required this.idempotencyKey});
  final String salesOrderId;
  final String sourceVersion;
  final String idempotencyKey;
}

class RetryIssuanceCommand {
  const RetryIssuanceCommand({required this.salesOrderId, required this.expectedOrderVersion, required this.idempotencyKey});
  final String salesOrderId;
  final int expectedOrderVersion;
  final String idempotencyKey;
}

class RequestOfficialInvoiceViewCommand {
  const RequestOfficialInvoiceViewCommand({required this.salesOrderId});
  final String salesOrderId;
}

class RequestInvoiceDocumentCommand {
  const RequestInvoiceDocumentCommand({required this.salesOrderId, required this.documentType});
  final String salesOrderId;
  final InvoiceDocumentType documentType;
}

class RequestInvoicePreviewCommand {
  const RequestInvoicePreviewCommand({required this.salesOrderId, required this.expectedOrderVersion});
  final String salesOrderId;
  final int expectedOrderVersion;
}

class GetElectronicInvoiceDetailQuery {
  const GetElectronicInvoiceDetailQuery({required this.salesOrderId});
  final String salesOrderId;
}

class GetInvoiceDocumentsQuery {
  const GetInvoiceDocumentsQuery({required this.salesOrderId});
  final String salesOrderId;
}

class GetInvoicePreviewQuery {
  const GetInvoicePreviewQuery({this.salesOrderId});
  final String? salesOrderId;
}

class GetOrderInvoiceProjectionQuery {
  const GetOrderInvoiceProjectionQuery({this.salesOrderId});
  final String? salesOrderId;
}

class GetIssuanceReadinessQuery {
  const GetIssuanceReadinessQuery({this.salesOrderId});
  final String? salesOrderId;
}

class GetIssuanceAttemptStatusQuery {
  const GetIssuanceAttemptStatusQuery({this.salesOrderId});
  final String? salesOrderId;
}

class GetIssuanceProfileQuery {
  const GetIssuanceProfileQuery();
}

class ListProviderTemplatesQuery {
  const ListProviderTemplatesQuery();
}

final class _RecordingLauncher implements IInvoiceViewerLauncher {
  final List<String> launchedUrls = [];

  @override
  Future<bool> launch(String url) async {
    launchedUrls.add(url);
    return true;
  }
}

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

final class _ConfigurableRepository extends FakeEInvoiceRepository {
  _ConfigurableRepository() : super();

  final List<dynamic> executedCommands = [];
  final List<dynamic> executedQueries = [];

  Object? commandResult;
  Future<Object?>? commandResultFuture;
  Object? Function(dynamic command)? commandResultBuilder;
  Object? queryResult;
  Object? Function(dynamic query)? queryResultBuilder;
  Exception? errorToThrow;

  @override
  Future<OrderInvoiceProjectionDto> getProjection(String salesOrderId) async {
    final query = GetOrderInvoiceProjectionQuery(salesOrderId: salesOrderId);
    executedQueries.add(query);
    if (errorToThrow != null) throw errorToThrow!;
    if (queryResultBuilder != null) {
      final res = queryResultBuilder!(query);
      if (res is OrderInvoiceProjectionDto) return res;
      if (res is Future) return (await res) as OrderInvoiceProjectionDto;
    }
    if (queryResult is OrderInvoiceProjectionDto) return queryResult as OrderInvoiceProjectionDto;
    return projection;
  }

  @override
  Future<IssuanceReadinessDto> getReadiness(String salesOrderId) async {
    final query = GetIssuanceReadinessQuery(salesOrderId: salesOrderId);
    executedQueries.add(query);
    if (errorToThrow != null) throw errorToThrow!;
    if (queryResultBuilder != null) {
      final res = queryResultBuilder!(query);
      if (res is IssuanceReadinessDto) return res;
    }
    if (queryResult is IssuanceReadinessDto) return queryResult as IssuanceReadinessDto;
    return readiness ??
        const IssuanceReadinessDto(
          level: IssuanceReadinessLevel.ready,
          blockers: [],
          warnings: [],
          buyerCompletionState: BuyerCompletionStatus.open,
        );
  }

  @override
  Future<IssuanceAttemptStatusDto> getAttemptStatus(String salesOrderId) async {
    final query = GetIssuanceAttemptStatusQuery(salesOrderId: salesOrderId);
    executedQueries.add(query);
    if (errorToThrow != null) throw errorToThrow!;
    if (queryResultBuilder != null) {
      final res = queryResultBuilder!(query);
      if (res is IssuanceAttemptStatusDto) return res;
    }
    if (queryResult is IssuanceAttemptStatusDto) return queryResult as IssuanceAttemptStatusDto;
    return attemptStatus ??
        const IssuanceAttemptStatusDto(
          attemptId: 'att-1',
          status: IssuanceAttemptStatus.submitted,
          internalFinalizationStatus: InternalFinalizationStatus.pending,
          hasElectronicInvoice: false,
          hasActiveOperation: false,
        );
  }

  @override
  Future<IssueInvoiceResultDto> issue({
    required String salesOrderId,
    required String sourceVersion,
    required String idempotencyKey,
    bool? acknowledgeWarnings,
  }) async {
    final cmd = IssueInvoiceCommand(
      salesOrderId: salesOrderId,
      sourceVersion: sourceVersion,
      idempotencyKey: idempotencyKey,
    );
    executedCommands.add(cmd);
    if (errorToThrow != null) throw errorToThrow!;
    if (commandResultBuilder != null) {
      final res = commandResultBuilder!(cmd);
      if (res is IssueInvoiceResultDto) return res;
    }
    if (commandResultFuture != null) {
      return (await commandResultFuture) as IssueInvoiceResultDto;
    }
    if (commandResult is IssueInvoiceResultDto) return commandResult as IssueInvoiceResultDto;
    return const IssueInvoiceResultDto(
      issuanceId: 'iss-1',
      attemptId: 'att-1',
      status: IssuanceAttemptStatus.preparing,
    );
  }

  @override
  Future<IssueInvoiceResultDto> retry({
    required String salesOrderId,
    required int expectedOrderVersion,
    required String idempotencyKey,
    bool? acknowledgeWarnings,
  }) async {
    final cmd = RetryIssuanceCommand(
      salesOrderId: salesOrderId,
      expectedOrderVersion: expectedOrderVersion,
      idempotencyKey: idempotencyKey,
    );
    executedCommands.add(cmd);
    if (errorToThrow != null) throw errorToThrow!;
    if (commandResultBuilder != null) {
      final res = commandResultBuilder!(cmd);
      if (res is IssueInvoiceResultDto) return res;
    }
    if (commandResultFuture != null) {
      return (await commandResultFuture) as IssueInvoiceResultDto;
    }
    if (commandResult is IssueInvoiceResultDto) return commandResult as IssueInvoiceResultDto;
    return const IssueInvoiceResultDto(
      issuanceId: 'iss-1',
      attemptId: 'att-1',
      status: IssuanceAttemptStatus.preparing,
    );
  }

  @override
  Future<InvoicePreviewResultDto> requestPreview({
    required String salesOrderId,
    required int expectedOrderVersion,
  }) async {
    final cmd = RequestInvoicePreviewCommand(
      salesOrderId: salesOrderId,
      expectedOrderVersion: expectedOrderVersion,
    );
    executedCommands.add(cmd);
    if (errorToThrow != null) throw errorToThrow!;
    if (commandResultBuilder != null) {
      final res = commandResultBuilder!(cmd);
      if (res is InvoicePreviewResultDto) return res;
    }
    if (commandResultFuture != null) {
      return (await commandResultFuture) as InvoicePreviewResultDto;
    }
    if (commandResult is InvoicePreviewResultDto) return commandResult as InvoicePreviewResultDto;
    return requestPreviewResult;
  }

  @override
  Future<InvoicePreviewResultDto> getPreview(String salesOrderId) async {
    final query = GetInvoicePreviewQuery(salesOrderId: salesOrderId);
    executedQueries.add(query);
    if (errorToThrow != null) throw errorToThrow!;
    if (queryResultBuilder != null) {
      final res = queryResultBuilder!(query);
      if (res is InvoicePreviewResultDto) return res;
    }
    if (queryResult is InvoicePreviewResultDto) return queryResult as InvoicePreviewResultDto;
    return super.getPreview(salesOrderId);
  }

  @override
  Future<OfficialInvoiceViewDto> requestOfficialView(String salesOrderId) async {
    final cmd = RequestOfficialInvoiceViewCommand(salesOrderId: salesOrderId);
    executedCommands.add(cmd);
    if (errorToThrow != null) throw errorToThrow!;
    if (commandResultBuilder != null) {
      final res = commandResultBuilder!(cmd);
      if (res is OfficialInvoiceViewDto) return res;
    }
    if (commandResultFuture != null) {
      return (await commandResultFuture) as OfficialInvoiceViewDto;
    }
    if (commandResult is OfficialInvoiceViewDto) return commandResult as OfficialInvoiceViewDto;
    return officialViewResult;
  }

  @override
  Future<ElectronicInvoiceDetailDto> getDetail(String salesOrderId) async {
    final query = GetElectronicInvoiceDetailQuery(salesOrderId: salesOrderId);
    executedQueries.add(query);
    if (errorToThrow != null) throw errorToThrow!;
    if (queryResultBuilder != null) {
      final res = queryResultBuilder!(query);
      if (res is ElectronicInvoiceDetailDto) return res;
    }
    if (queryResult is ElectronicInvoiceDetailDto) return queryResult as ElectronicInvoiceDetailDto;
    return super.getDetail(salesOrderId);
  }

  @override
  Future<InvoiceDocumentRetrievalDto> requestDocument({
    required String salesOrderId,
    required InvoiceDocumentType documentType,
  }) async {
    final cmd = RequestInvoiceDocumentCommand(
      salesOrderId: salesOrderId,
      documentType: documentType,
    );
    executedCommands.add(cmd);
    if (errorToThrow != null) throw errorToThrow!;
    if (commandResultBuilder != null) {
      final res = commandResultBuilder!(cmd);
      if (res is InvoiceDocumentRetrievalDto) return res;
    }
    if (commandResultFuture != null) {
      return (await commandResultFuture) as InvoiceDocumentRetrievalDto;
    }
    if (commandResult is InvoiceDocumentRetrievalDto) return commandResult as InvoiceDocumentRetrievalDto;
    return documentResult;
  }

  @override
  Future<InvoiceDocumentsDto> getDocuments(String salesOrderId) async {
    final query = GetInvoiceDocumentsQuery(salesOrderId: salesOrderId);
    executedQueries.add(query);
    if (errorToThrow != null) throw errorToThrow!;
    if (queryResultBuilder != null) {
      final res = queryResultBuilder!(query);
      if (res is InvoiceDocumentsDto) return res;
    }
    if (queryResult is InvoiceDocumentsDto) return queryResult as InvoiceDocumentsDto;
    return super.getDocuments(salesOrderId);
  }
}

final class _ConfigurableConfigurationRepository extends FakeEInvoiceConfigurationRepository {
  _ConfigurableConfigurationRepository(this.repository);
  final _ConfigurableRepository repository;

  @override
  Future<IssuanceProfileDto> getIssuanceProfile() async {
    repository.executedQueries.add(const GetIssuanceProfileQuery());
    return super.getIssuanceProfile();
  }

  @override
  Future<List<ProviderTemplateDto>> listTemplates({bool? invoiceWithCode, int? year}) async {
    repository.executedQueries.add(const ListProviderTemplatesQuery());
    return super.listTemplates(invoiceWithCode: invoiceWithCode, year: year);
  }
}

void main() {
  group('OrderEInvoiceCubit', () {
    late _ConfigurableRepository mediator;
    late _ConfigurableConfigurationRepository configurationRepository;
    late _RecordingLauncher launcher;
    late _RecordingExporter exporter;

    setUp(() {
      mediator = _ConfigurableRepository();
      configurationRepository = _ConfigurableConfigurationRepository(mediator);
      launcher = _RecordingLauncher();
      exporter = _RecordingExporter();
    });

    const issuedState = OrderEInvoiceState(
      salesOrderId: 'order-101',
      orderVersion: 1,
      projection: OrderInvoiceProjectionDto(
        salesOrderId: 'order-101',
        issuanceDisplayState: IssuanceDisplayState.issued,
        actions: [OrderInvoiceAction.view],
      ),
    );

    test('send operation does not mark official viewer as loading', () {
      final state = issuedState.copyWith(
        status: OrderEInvoiceStatus.submitting,
      );

      expect(state.isOpeningOfficialView, isFalse);
    });

    test('unknown technical error is never exposed verbatim', () {
      final message = einvoiceErrorMessage(
        Exception('MISA_TOKEN=secret; postgres detail'),
      );

      expect(message, isNot(contains('MISA_TOKEN')));
      expect(message, isNot(contains('postgres')));
    });

    OrderEInvoiceCubit createCubit({
      OrderInvoiceProjectionDto? initialProjection,
      IssuanceReadinessDto? initialReadiness,
      bool isBuyerNotReady = false,
      Duration pollInterval = const Duration(seconds: 5),
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
        repository: mediator,
        configurationRepository: configurationRepository,
        viewerLauncher: launcher,
        documentExporter: exporter,
        pollInterval: pollInterval,
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
      expect(mediator.executedQueries.length, 2); // projection + readiness
      expect(
        mediator.executedQueries.whereType<GetIssuanceProfileQuery>(),
        isEmpty,
      );
      expect(
        mediator.executedQueries.whereType<ListProviderTemplatesQuery>(),
        isEmpty,
      );
    });

    test('refresh reads safe attempt failure metadata for definite failure', () async {
      final cubit = createCubit();
      mediator.queryResultBuilder = (query) => switch (query) {
        GetOrderInvoiceProjectionQuery() => const OrderInvoiceProjectionDto(
          salesOrderId: 'order-101',
          issuanceDisplayState: IssuanceDisplayState.failed,
          actions: [OrderInvoiceAction.issue],
        ),
        GetIssuanceAttemptStatusQuery() => const IssuanceAttemptStatusDto(
          attemptId: 'attempt-9',
          status: IssuanceAttemptStatus.failed,
          internalFinalizationStatus: InternalFinalizationStatus.pending,
          hasElectronicInvoice: false,
          hasActiveOperation: false,
          failureCode: 'PROVIDER_REJECTED',
          lastErrorMessage: 'Nhà cung cấp từ chối hóa đơn',
        ),
        _ => null,
      };

      await cubit.refresh();

      expect(cubit.state.failureCode, 'PROVIDER_REJECTED');
      expect(cubit.state.lastFailureMessage, 'Nhà cung cấp từ chối hóa đơn');
      expect(cubit.state.isTerminal, isTrue);
      expect(cubit.state.shouldPoll, isFalse);
      expect(mediator.executedQueries.whereType<GetIssuanceProfileQuery>(), isEmpty);
      expect(mediator.executedQueries.whereType<ListProviderTemplatesQuery>(), isEmpty);
    });

    test('processing and pending delivery remain pollable', () {
      final processing = createCubit(
        initialProjection: const OrderInvoiceProjectionDto(
          salesOrderId: 'order-101',
          issuanceDisplayState: IssuanceDisplayState.processing,
          actions: [],
        ),
      );
      final deliveryPending = createCubit(
        initialProjection: const OrderInvoiceProjectionDto(
          salesOrderId: 'order-101',
          issuanceDisplayState: IssuanceDisplayState.issued,
          deliveryDisplayState: DeliveryDisplayState.sent,
          deliveryPending: true,
          actions: [OrderInvoiceAction.view],
        ),
      );

      expect(processing.state.shouldPoll, isTrue);
      expect(deliveryPending.state.shouldPoll, isTrue);
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

    test('cancelPreview aborts in-flight preview without error or launch', () async {
      final cubit = createCubit();
      final gate = Completer<InvoicePreviewResultDto>();
      mediator.commandResultFuture = gate.future;

      final pending = cubit.requestPreview(
        maxPollAttempts: 0,
        pollDelay: Duration.zero,
      );
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.status, OrderEInvoiceStatus.previewing);

      cubit.cancelPreview();
      expect(cubit.state.status, OrderEInvoiceStatus.idle);
      expect(cubit.state.errorMessage, isNull);

      gate.complete(
        const InvoicePreviewResultDto(
          viewerRef: 'https://testapi.meinvoice.vn/viewer/cancelled',
          warnings: [],
        ),
      );
      final url = await pending;
      expect(url, isNull);
      expect(launcher.launchedUrls, isEmpty);
      expect(cubit.state.status, OrderEInvoiceStatus.idle);
      expect(cubit.state.previewViewerUrl, isNull);
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

    test(
      'th08_scn_e03_u01_fr04_01 opens only the matching official operation',
      () async {
        final cubit = createCubit(
          initialProjection: const OrderInvoiceProjectionDto(
            salesOrderId: 'order-101',
            issuanceDisplayState: IssuanceDisplayState.issued,
            actions: [OrderInvoiceAction.view],
          ),
        );
        mediator.commandResult = const OfficialInvoiceViewDto(
          operationId: 'official-op-2',
          status: InvoiceDocumentStatus.pending,
        );
        var detailReads = 0;
        mediator.queryResultBuilder = (query) {
          if (query is! GetElectronicInvoiceDetailQuery) return null;
          detailReads++;
          if (detailReads == 1) {
            return const ElectronicInvoiceDetailDto(
              electronicInvoiceId: 'invoice-1',
              salesOrderId: 'order-101',
              officialViewOperationId: 'official-op-1',
              officialViewStatus: InvoiceDocumentStatus.available,
              officialViewerUrl: 'https://testapi.meinvoice.vn/viewer/stale',
            );
          }
          if (detailReads == 2) {
            return const ElectronicInvoiceDetailDto(
              electronicInvoiceId: 'invoice-1',
              salesOrderId: 'order-101',
              officialViewOperationId: 'official-op-2',
              officialViewStatus: InvoiceDocumentStatus.pending,
            );
          }
          return const ElectronicInvoiceDetailDto(
            electronicInvoiceId: 'invoice-1',
            salesOrderId: 'order-101',
            officialViewOperationId: 'official-op-2',
            officialViewStatus: InvoiceDocumentStatus.available,
            officialViewerUrl: 'https://testapi.meinvoice.vn/viewer/official-op-2',
          );
        };

        final ok = await cubit.openOfficialView(pollDelay: Duration.zero);

        expect(ok, isTrue);
        expect(launcher.launchedUrls, [
          'https://testapi.meinvoice.vn/viewer/official-op-2',
        ]);
        expect(
          mediator.executedCommands.whereType<RequestOfficialInvoiceViewCommand>(),
          hasLength(1),
        );
      },
    );

    test('official view ignores a concurrent repeated request', () async {
      final cubit = createCubit(
        initialProjection: const OrderInvoiceProjectionDto(
          salesOrderId: 'order-101',
          issuanceDisplayState: IssuanceDisplayState.issued,
          actions: [OrderInvoiceAction.view],
        ),
      );
      mediator.commandResultFuture = Future.delayed(
        const Duration(milliseconds: 20),
        () => const OfficialInvoiceViewDto(
          operationId: 'official-op-1',
          viewerUrl: 'https://testapi.meinvoice.vn/viewer/official-1',
          status: InvoiceDocumentStatus.available,
        ),
      );

      final first = cubit.openOfficialView(pollDelay: Duration.zero);
      final second = cubit.openOfficialView(pollDelay: Duration.zero);

      expect(await second, isFalse);
      expect(await first, isTrue);
      expect(
        mediator.executedCommands.whereType<RequestOfficialInvoiceViewCommand>(),
        hasLength(1),
      );
    });

    test(
      'official view keeps polling after one transient read failure',
      () async {
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
          if (query is! GetElectronicInvoiceDetailQuery) return null;
          detailReads++;
          if (detailReads == 1) {
            throw TimeoutException('transient detail timeout');
          }
          return const ElectronicInvoiceDetailDto(
            electronicInvoiceId: 'invoice-1',
            salesOrderId: 'order-101',
            officialViewOperationId: 'official-op-1',
            officialViewStatus: InvoiceDocumentStatus.available,
            officialViewerUrl: 'https://testapi.meinvoice.vn/viewer/after-timeout',
          );
        };

        final ok = await cubit.openOfficialView(pollDelay: Duration.zero);

        expect(ok, isTrue);
        expect(detailReads, 2);
        expect(launcher.launchedUrls, [
          'https://testapi.meinvoice.vn/viewer/after-timeout',
        ]);
      },
    );

    test(
      'official view check-required feedback contains no technical status',
      () async {
        final cubit = createCubit(
          initialProjection: const OrderInvoiceProjectionDto(
            salesOrderId: 'order-101',
            issuanceDisplayState: IssuanceDisplayState.issued,
            actions: [OrderInvoiceAction.view],
          ),
        );
        mediator.commandResult = const OfficialInvoiceViewDto(
          operationId: 'official-op-1',
          status: InvoiceDocumentStatus.checkRequired,
        );

        final ok = await cubit.openOfficialView(pollDelay: Duration.zero);

        expect(ok, isFalse);
        expect(
          cubit.state.projection.issuanceDisplayState,
          IssuanceDisplayState.issued,
        );
        expect(cubit.state.errorMessage, isNotNull);
        expect(cubit.state.errorMessage, isNot(contains('CHECK_REQUIRED')));
        expect(cubit.state.errorMessage, isNot(contains('checkRequired')));
        expect(
          mediator.executedQueries.whereType<GetElectronicInvoiceDetailQuery>(),
          isEmpty,
        );
      },
    );

    test(
      'th08_scn_e03_u01_fr04_02 resolves viewer URL when command is AVAILABLE without URL',
      () async {
        final cubit = createCubit(
          initialProjection: const OrderInvoiceProjectionDto(
            salesOrderId: 'order-101',
            issuanceDisplayState: IssuanceDisplayState.issued,
            actions: [OrderInvoiceAction.view],
          ),
        );
        mediator.commandResult = const OfficialInvoiceViewDto(
          operationId: 'official-op-1',
          status: InvoiceDocumentStatus.available,
          viewerUrl: null,
        );
        mediator.queryResultBuilder = (query) {
          if (query is GetElectronicInvoiceDetailQuery) {
            return const ElectronicInvoiceDetailDto(
              electronicInvoiceId: 'invoice-1',
              salesOrderId: 'order-101',
              officialViewOperationId: 'official-op-1',
              officialViewStatus: InvoiceDocumentStatus.available,
              officialViewerUrl: 'https://testapi.meinvoice.vn/viewer/signed-replay',
            );
          }
          return null;
        };

        final ok = await cubit.openOfficialView(pollDelay: Duration.zero);

        expect(ok, isTrue);
        expect(launcher.launchedUrls, [
          'https://testapi.meinvoice.vn/viewer/signed-replay',
        ]);
        expect(
          mediator.executedCommands.whereType<RequestOfficialInvoiceViewCommand>(),
          hasLength(1),
        );
      },
    );

    test(
      'terminal official-view command does not poll detail query',
      () async {
        for (final terminal in [
          InvoiceDocumentStatus.failed,
          InvoiceDocumentStatus.checkRequired,
        ]) {
          mediator = _ConfigurableRepository();
          configurationRepository = _ConfigurableConfigurationRepository(mediator);
          launcher = _RecordingLauncher();
          final cubit = createCubit(
            initialProjection: const OrderInvoiceProjectionDto(
              salesOrderId: 'order-101',
              issuanceDisplayState: IssuanceDisplayState.issued,
              actions: [OrderInvoiceAction.view],
            ),
          );
          mediator.commandResult = OfficialInvoiceViewDto(
            operationId: 'official-op-1',
            status: terminal,
          );

          final ok = await cubit.openOfficialView(pollDelay: Duration.zero);

          expect(ok, isFalse);
          expect(
            mediator.executedQueries.whereType<GetElectronicInvoiceDetailQuery>(),
            isEmpty,
          );
          expect(
            cubit.state.projection.issuanceDisplayState,
            IssuanceDisplayState.issued,
          );
          expect(cubit.state.errorMessage, isNotNull);
          expect(cubit.state.errorMessage, isNot(contains('FAILED')));
          expect(cubit.state.errorMessage, isNot(contains('CHECK_REQUIRED')));
          await cubit.close();
        }
      },
    );

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
        checksum: 'checksum-immediate',
      );

      final ok = await cubit.downloadDocument(InvoiceDocumentType.pdf);

      expect(ok, isTrue);
      expect(exporter.exported.length, 1);
      expect(exporter.exported.first.type, InvoiceDocumentType.pdf);
      expect(
        exporter.exported.first.url,
        'https://storage.example.com/invoice-101.pdf',
      );
      expect(exporter.exported.first.expectedSha256, 'checksum-immediate');
      expect(exporter.exported.first.filename, 'invoice_order-101.pdf');
    });

    test(
      'downloadDocument export failure uses save-to-device copy and keeps issued',
      () async {
        exporter = _RecordingExporter(result: false);
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
          checksum: 'checksum-immediate',
        );

        final result = await cubit.downloadDocument(InvoiceDocumentType.pdf);

        expect(result, isFalse);
        expect(cubit.state.status, OrderEInvoiceStatus.error);
        expect(
          cubit.state.errorMessage,
          'Không thể lưu tài liệu hóa đơn trên thiết bị. Vui lòng thử lại.',
        );
        expect(
          cubit.state.projection.issuanceDisplayState,
          IssuanceDisplayState.issued,
        );
        await cubit.close();
      },
    );

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
              operationId: 'doc-op-1',
              downloadUrl: documentReads < 2
                  ? null
                  : 'https://storage.example.com/invoice-poll.pdf',
              checksum: documentReads < 2 ? null : 'checksum-poll',
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
      expect(exporter.exported.first.expectedSha256, 'checksum-poll');
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

    test(
      'th08_scn_e03_u02_fr04_01 resolves URL when command is AVAILABLE without URL',
      () async {
        final cubit = createCubit(
          initialProjection: const OrderInvoiceProjectionDto(
            salesOrderId: 'order-101',
            issuanceDisplayState: IssuanceDisplayState.issued,
            actions: [OrderInvoiceAction.downloadPdf],
          ),
        );
        mediator.commandResult = const InvoiceDocumentRetrievalDto(
          operationId: 'doc-op-1',
          status: InvoiceDocumentStatus.available,
          fileRef: 'einvoice-documents/order-101.pdf',
          checksum: 'checksum-1',
        );
        mediator.queryResultBuilder = (query) {
          if (query is GetInvoiceDocumentsQuery) {
            return const InvoiceDocumentsDto(
              pdfAvailable: true,
              xmlAvailable: false,
              retrievalStatus: InvoiceDocumentStatus.available,
              pdf: InvoiceDocumentItemDto(
                documentType: InvoiceDocumentType.pdf,
                status: InvoiceDocumentStatus.available,
                operationId: 'doc-op-1',
                downloadUrl: 'https://storage.example.com/signed-replay.pdf',
                checksum: 'checksum-1',
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
        expect(exporter.exported, hasLength(1));
        expect(
          exporter.exported.first.url,
          'https://storage.example.com/signed-replay.pdf',
        );
        expect(exporter.exported.first.expectedSha256, 'checksum-1');
        expect(
          mediator.executedCommands.whereType<RequestInvoiceDocumentCommand>(),
          hasLength(1),
        );
      },
    );

    test(
      'AVAILABLE without checksum fails closed and skips exporter',
      () async {
        final cubit = createCubit(
          initialProjection: const OrderInvoiceProjectionDto(
            salesOrderId: 'order-101',
            issuanceDisplayState: IssuanceDisplayState.issued,
            actions: [OrderInvoiceAction.downloadPdf],
          ),
        );
        mediator.commandResult = const InvoiceDocumentRetrievalDto(
          operationId: 'doc-op-1',
          status: InvoiceDocumentStatus.available,
          fileRef: 'einvoice-documents/order-101.pdf',
        );
        mediator.queryResultBuilder = (query) {
          if (query is GetInvoiceDocumentsQuery) {
            return const InvoiceDocumentsDto(
              pdfAvailable: true,
              xmlAvailable: false,
              retrievalStatus: InvoiceDocumentStatus.available,
              pdf: InvoiceDocumentItemDto(
                documentType: InvoiceDocumentType.pdf,
                status: InvoiceDocumentStatus.available,
                operationId: 'doc-op-1',
                downloadUrl: 'https://storage.example.com/signed-replay.pdf',
              ),
            );
          }
          return null;
        };

        final ok = await cubit.downloadDocument(
          InvoiceDocumentType.pdf,
          pollDelay: Duration.zero,
        );

        expect(ok, isFalse);
        expect(exporter.exported, isEmpty);
        expect(cubit.state.status, OrderEInvoiceStatus.error);
        expect(cubit.state.errorMessage, isNot(contains('checksum')));
        expect(
          cubit.state.errorMessage,
          'Không thể tải tài liệu hóa đơn lúc này. Vui lòng thử lại.',
        );
      },
    );

    test(
      'document polling ignores stale available item from another operation',
      () async {
        final cubit = createCubit(
          initialProjection: const OrderInvoiceProjectionDto(
            salesOrderId: 'order-101',
            issuanceDisplayState: IssuanceDisplayState.issued,
            actions: [OrderInvoiceAction.downloadPdf],
          ),
        );
        mediator.commandResult = const InvoiceDocumentRetrievalDto(
          operationId: 'doc-op-2',
          status: InvoiceDocumentStatus.pending,
        );
        var documentReads = 0;
        mediator.queryResultBuilder = (query) {
          if (query is! GetInvoiceDocumentsQuery) return null;
          documentReads++;
          if (documentReads == 1) {
            return const InvoiceDocumentsDto(
              pdfAvailable: true,
              xmlAvailable: false,
              retrievalStatus: InvoiceDocumentStatus.available,
              pdf: InvoiceDocumentItemDto(
                documentType: InvoiceDocumentType.pdf,
                status: InvoiceDocumentStatus.available,
                operationId: 'doc-op-1',
                downloadUrl: 'https://storage.example.com/stale.pdf',
              ),
            );
          }
          return const InvoiceDocumentsDto(
            pdfAvailable: true,
            xmlAvailable: false,
            retrievalStatus: InvoiceDocumentStatus.available,
            pdf: InvoiceDocumentItemDto(
              documentType: InvoiceDocumentType.pdf,
              status: InvoiceDocumentStatus.available,
              operationId: 'doc-op-2',
              downloadUrl: 'https://storage.example.com/fresh.pdf',
              checksum: 'checksum-fresh',
            ),
          );
        };

        final ok = await cubit.downloadDocument(
          InvoiceDocumentType.pdf,
          pollDelay: Duration.zero,
        );

        expect(ok, isTrue);
        expect(exporter.exported.single.url, 'https://storage.example.com/fresh.pdf');
        expect(exporter.exported.single.expectedSha256, 'checksum-fresh');
        expect(documentReads, 2);
      },
    );

    test(
      'same document action cannot enqueue twice while foreground operation runs',
      () async {
        final cubit = createCubit(
          initialProjection: const OrderInvoiceProjectionDto(
            salesOrderId: 'order-101',
            issuanceDisplayState: IssuanceDisplayState.issued,
            actions: [OrderInvoiceAction.downloadPdf],
          ),
        );
        mediator.commandResultFuture = Future.delayed(
          const Duration(milliseconds: 20),
          () => const InvoiceDocumentRetrievalDto(
            operationId: 'doc-op-1',
            status: InvoiceDocumentStatus.available,
            downloadUrl: 'https://storage.example.com/invoice-101.pdf',
            checksum: 'checksum-dup',
          ),
        );

        final first = cubit.downloadDocument(
          InvoiceDocumentType.pdf,
          pollDelay: Duration.zero,
        );
        final second = cubit.downloadDocument(
          InvoiceDocumentType.pdf,
          pollDelay: Duration.zero,
        );

        expect(await second, isFalse);
        expect(await first, isTrue);
        expect(
          mediator.executedCommands.whereType<RequestInvoiceDocumentCommand>(),
          hasLength(1),
        );
      },
    );

    test('document poll survives one transient query failure', () async {
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
        if (query is! GetInvoiceDocumentsQuery) return null;
        documentReads++;
        if (documentReads == 1) {
          throw TimeoutException('transient documents timeout');
        }
        return const InvoiceDocumentsDto(
          pdfAvailable: true,
          xmlAvailable: false,
          retrievalStatus: InvoiceDocumentStatus.available,
          pdf: InvoiceDocumentItemDto(
            documentType: InvoiceDocumentType.pdf,
            status: InvoiceDocumentStatus.available,
            operationId: 'doc-op-1',
            downloadUrl: 'https://storage.example.com/after-timeout.pdf',
            checksum: 'checksum-after-timeout',
          ),
        );
      };

      final ok = await cubit.downloadDocument(
        InvoiceDocumentType.pdf,
        pollDelay: Duration.zero,
      );

      expect(ok, isTrue);
      expect(documentReads, 2);
      expect(
        exporter.exported.single.url,
        'https://storage.example.com/after-timeout.pdf',
      );
      expect(exporter.exported.single.expectedSha256, 'checksum-after-timeout');
    });

    test(
      'document failure keeps issued projection and hides technical status',
      () async {
        for (final terminal in [
          InvoiceDocumentStatus.failed,
          InvoiceDocumentStatus.checkRequired,
        ]) {
          mediator = _ConfigurableRepository();
          configurationRepository = _ConfigurableConfigurationRepository(mediator);
          exporter = _RecordingExporter();
          final cubit = createCubit(
            initialProjection: const OrderInvoiceProjectionDto(
              salesOrderId: 'order-101',
              issuanceDisplayState: IssuanceDisplayState.issued,
              actions: [OrderInvoiceAction.downloadPdf],
            ),
          );
          mediator.commandResult = InvoiceDocumentRetrievalDto(
            operationId: 'doc-op-1',
            status: terminal,
          );

          final ok = await cubit.downloadDocument(
            InvoiceDocumentType.pdf,
            pollDelay: Duration.zero,
          );

          expect(ok, isFalse);
          expect(
            cubit.state.projection.issuanceDisplayState,
            IssuanceDisplayState.issued,
          );
          expect(cubit.state.errorMessage, isNotNull);
          expect(cubit.state.errorMessage, isNot(contains('FAILED')));
          expect(cubit.state.errorMessage, isNot(contains('CHECK_REQUIRED')));
          expect(
            mediator.executedQueries.whereType<GetInvoiceDocumentsQuery>(),
            isEmpty,
          );
          await cubit.close();
        }
      },
    );

    test('permission error surfaces human-friendly message', () async {
      final cubit = createCubit();
      mediator.errorToThrow = const AppException('NO_PERMISSION');

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

    test('new cubit starts from initial projection', () {
      const initial = OrderInvoiceProjectionDto(
        salesOrderId: 'order-101',
        issuanceDisplayState: IssuanceDisplayState.processing,
        actions: [],
      );
      final cubit = createCubit(initialProjection: initial);
      addTearDown(cubit.close);

      expect(cubit.state.projection, initial);
      expect(cubit.state.projection.issuanceDisplayState, IssuanceDisplayState.processing);
    });

    test('poll error keeps error message', () async {
      final cubit = createCubit(
        initialProjection: const OrderInvoiceProjectionDto(
          salesOrderId: 'order-101',
          issuanceDisplayState: IssuanceDisplayState.processing,
          actions: [],
        ),
      );
      addTearDown(cubit.close);

      cubit.emit(cubit.state.copyWith(errorMessage: 'Lỗi phát hành trước đó'));
      mediator.errorToThrow = Exception('Network error during poll');

      await cubit.refresh();

      expect(cubit.state.errorMessage, 'Lỗi phát hành trước đó');
    });

    test('slow poll does not overlap', () async {
      final cubit = createCubit(
        initialProjection: const OrderInvoiceProjectionDto(
          salesOrderId: 'order-101',
          issuanceDisplayState: IssuanceDisplayState.processing,
          actions: [],
        ),
        pollInterval: const Duration(milliseconds: 10),
      );
      addTearDown(cubit.close);

      final gate = Completer<OrderInvoiceProjectionDto>();
      mediator.queryResultBuilder = (query) => query is GetOrderInvoiceProjectionQuery
          ? gate.future
          : null;

      int projectionReads() => mediator.executedQueries.whereType<GetOrderInvoiceProjectionQuery>().length;

      cubit.setPollingActive(true);
      await Future<void>.delayed(const Duration(milliseconds: 35));
      expect(projectionReads(), 1);

      gate.complete(
        const OrderInvoiceProjectionDto(
          salesOrderId: 'order-101',
          issuanceDisplayState: IssuanceDisplayState.processing,
          actions: [],
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 8));
      expect(projectionReads(), 2);
    });

    test('poll result after close is dropped', () async {
      final cubit = createCubit(
        initialProjection: const OrderInvoiceProjectionDto(
          salesOrderId: 'order-101',
          issuanceDisplayState: IssuanceDisplayState.processing,
          actions: [],
        ),
      );

      final gate = Completer<OrderInvoiceProjectionDto>();
      mediator.queryResultBuilder = (_) => gate.future;

      final refreshFuture = cubit.refresh();
      await cubit.close();

      gate.complete(
        const OrderInvoiceProjectionDto(
          salesOrderId: 'order-101',
          issuanceDisplayState: IssuanceDisplayState.issued,
          actions: [OrderInvoiceAction.view],
        ),
      );
      await refreshFuture;

      expect(cubit.isClosed, isTrue);
    });
  });
}
