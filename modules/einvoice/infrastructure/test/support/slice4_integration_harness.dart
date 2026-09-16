import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:supabase/supabase.dart';
import 'package:uuid/uuid.dart';
import 'package:vet45_adapters/vet45_adapters.dart'
    hide InternalCommandSerializer, ISerializableInternalCommand;
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_einvoice_infrastructure/src/adapters/misa/me_invoice_electronic_invoice_provider_adapter.dart';
import 'package:vet45_einvoice_infrastructure/src/adapters/misa/tenant_me_invoice_client_factory.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/commands_executor.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/einvoice_command_dispatcher.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/generated/einvoice_internal_command_registry.g.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/internal_commands/i_einvoice_internal_command_client.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/internal_commands/i_einvoice_internal_command_dead_letter_handler.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/internal_commands/invoice_document_command_dead_letter_handler.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/internal_commands/official_view_command_dead_letter_handler.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/internal_commands/process_internal_commands_command.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/internal_commands/process_internal_commands_command_handler.dart';
import 'package:vet45_einvoice_integration_events/integration_events.dart';
import 'package:vet45_misa/e_invoice.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

typedef _EinvoiceRpcHandler =
    Future<dynamic> Function(Map<String, dynamic>? params);

final class _FakeEinvoiceRpcSupabase implements SupabaseClient {
  final Map<String, _EinvoiceRpcHandler> _handlers = {};

  void registerHandler(String functionName, _EinvoiceRpcHandler handler) {
    _handlers[functionName] = handler;
  }

  @override
  SupabaseQuerySchema schema(String schema) {
    if (schema != 'einvoice') {
      throw UnsupportedError('Only einvoice schema is supported.');
    }
    return _FakeEinvoiceQuerySchema(this);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

final class _FakeEinvoiceQuerySchema implements SupabaseQuerySchema {
  _FakeEinvoiceQuerySchema(this.client);
  final _FakeEinvoiceRpcSupabase client;

  @override
  PostgrestFilterBuilder<T> rpc<T>(
    String fn, {
    Map<String, dynamic>? params,
    bool get = false,
  }) => _FakePostgrestRpc<T>(client, fn, params);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

final class _FakePostgrestRpc<T> implements PostgrestFilterBuilder<T> {
  _FakePostgrestRpc(this.client, this.functionName, this.params);

  final _FakeEinvoiceRpcSupabase client;
  final String functionName;
  final Map<String, dynamic>? params;

  @override
  Stream<T> asStream() => throw UnsupportedError('stream not supported');

  @override
  Future<R> then<R>(
    FutureOr<R> Function(T value) onValue, {
    Function? onError,
  }) => _execute().then(onValue, onError: onError);

  Future<T> _execute() async {
    final handler = client._handlers[functionName];
    if (handler == null) {
      throw StateError('No handler registered for RPC $functionName');
    }
    return await handler(params) as T;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

final class _StoredCommand {
  _StoredCommand({
    required this.id,
    required this.tenantId,
    required this.commandType,
    required this.payload,
    required this.enqueuedAt,
  });

  final String id;
  final String tenantId;
  final String commandType;
  final Map<String, dynamic> payload;
  final DateTime enqueuedAt;
  int retryCount = 0;
  String? claimToken;
  DateTime? processedAt;
  DateTime? failedAt;
}

final class Slice4InternalCommandClient
    implements IEinvoiceInternalCommandClient {
  Slice4InternalCommandClient({required this.serializer});

  final InternalCommandSerializer serializer;
  final List<_StoredCommand> commands = [];

  void enqueue(ISerializableInternalCommand command) {
    if (command is! CommandBase) {
      throw ArgumentError('command must extend CommandBase');
    }
    final base = command as CommandBase<void>;
    commands.add(
      _StoredCommand(
        id: base.id,
        tenantId: serializer.tenantIdOf(command),
        commandType: serializer.commandTypeOf(command),
        payload: serializer.toPayload(command),
        enqueuedAt: DateTime.utc(2026, 8, 31, 9),
      ),
    );
  }

  int countPending(String commandType) {
    return commands
        .where(
          (c) =>
              c.commandType == commandType &&
              c.processedAt == null &&
              c.failedAt == null,
        )
        .length;
  }

  @override
  Future<int> seedDueReconciliationCommands({
    required String tenantId,
    int limit = 50,
  }) async => 0;

  @override
  Future<List<ClaimedInternalCommand>> claimBatch({
    required String tenantId,
    required int limit,
  }) async {
    final pending = commands
        .where(
          (c) =>
              c.tenantId == tenantId &&
              c.processedAt == null &&
              c.failedAt == null &&
              c.claimToken == null,
        )
        .take(limit)
        .toList(growable: false);

    final claimed = <ClaimedInternalCommand>[];
    for (final command in pending) {
      final token = const Uuid().v4();
      command.claimToken = token;
      claimed.add(
        ClaimedInternalCommand(
          commandId: command.id,
          commandType: command.commandType,
          payload: Map<String, dynamic>.from(command.payload),
          enqueuedAt: command.enqueuedAt,
          claimToken: token,
          retryCount: command.retryCount,
        ),
      );
    }
    return claimed;
  }

  @override
  Future<void> complete({
    required String tenantId,
    required String commandId,
    required String claimToken,
  }) async {
    final command = _findClaimed(
      tenantId: tenantId,
      commandId: commandId,
      claimToken: claimToken,
    );
    if (command == null) return;
    command.processedAt = DateTime.utc(2026, 8, 31, 9);
    command.claimToken = null;
  }

  @override
  Future<InternalCommandDisposition> retryOrDeadLetter({
    required String tenantId,
    required String commandId,
    required String claimToken,
    required String error,
  }) async {
    final command = _findClaimed(
      tenantId: tenantId,
      commandId: commandId,
      claimToken: claimToken,
    );
    if (command == null) {
      throw StateError('Command not found');
    }
    command.retryCount++;
    command.claimToken = null;
    return InternalCommandDisposition.retry;
  }

  @override
  Future<void> fail({
    required String tenantId,
    required String commandId,
    required String claimToken,
    required String error,
  }) async {
    final command = _findClaimed(
      tenantId: tenantId,
      commandId: commandId,
      claimToken: claimToken,
    );
    if (command == null) return;
    command.failedAt = DateTime.utc(2026, 8, 31, 9);
    command.claimToken = null;
  }

  @override
  Future<void> reschedule({
    required String tenantId,
    required String commandId,
    required String claimToken,
    required Duration delay,
  }) async {
    final command = _findClaimed(
      tenantId: tenantId,
      commandId: commandId,
      claimToken: claimToken,
    );
    if (command == null) return;
    command.claimToken = null;
  }

  _StoredCommand? _findClaimed({
    required String tenantId,
    required String commandId,
    required String claimToken,
  }) {
    for (final command in commands) {
      if (command.id == commandId &&
          command.tenantId == tenantId &&
          command.claimToken == claimToken) {
        return command;
      }
    }
    return null;
  }
}

final class Slice4ElectronicInvoiceRecord {
  Slice4ElectronicInvoiceRecord({
    required this.electronicInvoiceId,
    required this.salesOrderId,
    required this.providerConnectionId,
    required this.providerInvoiceReference,
    required this.invoiceSeries,
  });

  final String electronicInvoiceId;
  final String salesOrderId;
  final String providerConnectionId;
  final String providerInvoiceReference;
  final String invoiceSeries;
}

final class Slice4OfficialViewOperation {
  Slice4OfficialViewOperation({
    required this.operationId,
    required this.tenantId,
    required this.electronicInvoiceId,
    required this.salesOrderId,
    required this.generation,
    required this.attemptOrdinal,
    required this.providerConnectionId,
    required this.correlationId,
    required this.commandId,
  });

  final String operationId;
  final String tenantId;
  final String electronicInvoiceId;
  final String salesOrderId;
  int generation;
  int attemptOrdinal;
  InvoiceDocumentStatus status = InvoiceDocumentStatus.pending;
  int version = 0;
  final String providerConnectionId;
  final String correlationId;
  final String commandId;
  String? viewerUrl;
  DateTime? expiresAt;
  String? failureCode;
}

final class Slice4DocumentOperation {
  Slice4DocumentOperation({
    required this.operationId,
    required this.tenantId,
    required this.electronicInvoiceId,
    required this.salesOrderId,
    required this.documentType,
    required this.generation,
    required this.attemptOrdinal,
    required this.documentVersion,
    required this.providerConnectionId,
    required this.idempotencyKey,
    required this.correlationId,
    required this.commandId,
    this.documentIntent,
  });

  final String operationId;
  final String tenantId;
  final String electronicInvoiceId;
  final String salesOrderId;
  final InvoiceDocumentType documentType;
  int generation;
  int attemptOrdinal;
  int documentVersion;
  InvoiceDocumentStatus status = InvoiceDocumentStatus.pending;
  int version = 0;
  final String providerConnectionId;
  final String idempotencyKey;
  final String? documentIntent;
  final String correlationId;
  final String commandId;
  String? downloadUrl;
  String? checksum;
  DateTime? accessExpiresAt;
  String? fileRef;
  String? failureCode;
}

final class Slice4Interaction {
  Slice4Interaction({
    required this.interactionReference,
    required this.tenantId,
    required this.version,
    required this.providerConnectionId,
    required this.direction,
    required this.operationType,
    required this.targetType,
    required this.targetId,
    required this.correlationId,
    required this.requestReference,
    required this.startedAt,
    this.outcome,
    this.safeErrorCode,
    this.providerReference,
    this.completedAt,
  });

  final String interactionReference;
  final String tenantId;
  int version;
  final String providerConnectionId;
  final ProviderInteractionDirection direction;
  final String operationType;
  final String targetType;
  final String targetId;
  final String correlationId;
  final String requestReference;
  final DateTime startedAt;
  ProviderInteractionOutcome? outcome;
  String? safeErrorCode;
  String? providerReference;
  DateTime? completedAt;
  bool completed = false;
}

final class Slice4State {
  final Set<String> accessibleSalesOrders = {};
  final Set<String> permittedActors = {};
  final Map<String, Slice4ElectronicInvoiceRecord> invoicesBySalesOrder = {};
  final Map<String, List<String>> supportedDocumentTypes = {};
  final Map<String, Slice4OfficialViewOperation> officialOps = {};
  final Map<String, Slice4DocumentOperation> documentOps = {};
  final Map<String, Slice4DocumentOperation> documentOpsByIdempotency = {};
  final Map<String, Slice4Interaction> interactionsByCorrelation = {};
  final List<ProviderObservationRecord> observations = [];
  final List<ProviderObservationAttentionRequiredIntegrationEvent>
  attentionEvents = [];
  final Map<String, List<int>> storedDocumentBytes = {};
  int storageUploadCount = 0;
}

final class Slice4ElectronicInvoiceCommandGateway
    implements IElectronicInvoiceCommandGateway {
  Slice4ElectronicInvoiceCommandGateway({
    required this.state,
    required this.internalClient,
    required this.fixedNow,
  });

  final Slice4State state;
  final Slice4InternalCommandClient internalClient;
  final DateTime fixedNow;

  void _requireAccess(String actorId, String salesOrderId) {
    if (!state.permittedActors.contains(actorId)) {
      throw StateError('PERMISSION_DENIED');
    }
    if (!state.accessibleSalesOrders.contains(salesOrderId)) {
      throw StateError('NOT_FOUND');
    }
  }

  Slice4ElectronicInvoiceRecord _invoice(String salesOrderId) {
    final invoice = state.invoicesBySalesOrder[salesOrderId];
    if (invoice == null) {
      throw StateError('NOT_FOUND');
    }
    return invoice;
  }

  @override
  Future<OfficialInvoiceViewDto> requestOfficialView({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
  }) async {
    _requireAccess(actorId, salesOrderId);
    final invoice = _invoice(salesOrderId);

    final existing = state.officialOps.values
        .where((op) => op.salesOrderId == salesOrderId)
        .toList(growable: false);
    if (existing.isNotEmpty) {
      final op = existing.last;
      if (op.status == InvoiceDocumentStatus.available ||
          op.status == InvoiceDocumentStatus.checkRequired ||
          op.status == InvoiceDocumentStatus.pending) {
        return OfficialInvoiceViewDto(
          operationId: op.operationId,
          status: op.status,
          viewerUrl: op.viewerUrl,
          expiresAt: op.expiresAt,
        );
      }
    }

    final operationId = 'op-official-${state.officialOps.length + 1}';
    final attemptOrdinal = 1;
    final commandId = 'cmd-official-$operationId-$attemptOrdinal';
    final correlationId = 'corr-official-$operationId';

    final op = Slice4OfficialViewOperation(
      operationId: operationId,
      tenantId: tenantId,
      electronicInvoiceId: invoice.electronicInvoiceId,
      salesOrderId: salesOrderId,
      generation: 1,
      attemptOrdinal: attemptOrdinal,
      providerConnectionId: invoice.providerConnectionId,
      correlationId: correlationId,
      commandId: commandId,
    );
    state.officialOps[operationId] = op;

    internalClient.enqueue(
      FetchOfficialInvoiceViewCommand(
        id: commandId,
        tenantId: tenantId,
        operationId: operationId,
        electronicInvoiceId: invoice.electronicInvoiceId,
        attemptOrdinal: attemptOrdinal,
        correlationId: correlationId,
      ),
    );

    return OfficialInvoiceViewDto(
      operationId: operationId,
      status: InvoiceDocumentStatus.pending,
    );
  }

  Future<OfficialInvoiceViewDto> replayOfficialView({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
  }) async {
    _requireAccess(actorId, salesOrderId);
    final op = state.officialOps.values.lastWhere(
      (item) => item.salesOrderId == salesOrderId,
    );
    if (op.status == InvoiceDocumentStatus.checkRequired) {
      op.status = InvoiceDocumentStatus.pending;
      op.attemptOrdinal++;
      op.version++;
      final commandId = 'cmd-official-${op.operationId}-${op.attemptOrdinal}';
      internalClient.enqueue(
        FetchOfficialInvoiceViewCommand(
          id: commandId,
          tenantId: tenantId,
          operationId: op.operationId,
          electronicInvoiceId: op.electronicInvoiceId,
          attemptOrdinal: op.attemptOrdinal,
          correlationId: 'corr-replay-${op.attemptOrdinal}',
        ),
      );
    }
    return OfficialInvoiceViewDto(
      operationId: op.operationId,
      status: op.status,
      viewerUrl: op.viewerUrl,
      expiresAt: op.expiresAt,
    );
  }

  @override
  Future<InvoiceDocumentRetrievalDto> requestDocument({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
    required InvoiceDocumentType documentType,
    required String idempotencyKey,
  }) async {
    _requireAccess(actorId, salesOrderId);
    final invoice = _invoice(salesOrderId);
    final supported =
        state.supportedDocumentTypes[invoice.providerConnectionId] ??
        ['PDF', 'XML'];
    final wireType = documentType == InvoiceDocumentType.pdf ? 'PDF' : 'XML';
    if (!supported.contains(wireType)) {
      throw StateError('DOCUMENT_UNAVAILABLE');
    }

    final existing =
        state.documentOpsByIdempotency['$tenantId:$idempotencyKey'];
    if (existing != null) {
      if (existing.documentIntent != null &&
          existing.documentIntent != '$salesOrderId:${documentType.name}') {
        throw StateError('IDEMPOTENCY_CONFLICT');
      }
      return InvoiceDocumentRetrievalDto(
        operationId: existing.operationId,
        status: existing.status,
        downloadUrl: existing.downloadUrl,
        checksum: existing.checksum,
      );
    }

    final operationId = 'op-doc-${state.documentOps.length + 1}';
    final attemptOrdinal = 1;
    final commandId = 'cmd-doc-$operationId-$attemptOrdinal';
    final correlationId = 'corr-doc-$operationId';
    final op = Slice4DocumentOperation(
      operationId: operationId,
      tenantId: tenantId,
      electronicInvoiceId: invoice.electronicInvoiceId,
      salesOrderId: salesOrderId,
      documentType: documentType,
      generation: 1,
      attemptOrdinal: attemptOrdinal,
      documentVersion: 0,
      providerConnectionId: invoice.providerConnectionId,
      idempotencyKey: idempotencyKey,
      correlationId: correlationId,
      commandId: commandId,
      documentIntent: '$salesOrderId:${documentType.name}',
    );
    state.documentOps[operationId] = op;
    state.documentOpsByIdempotency['$tenantId:$idempotencyKey'] = op;

    internalClient.enqueue(
      DownloadInvoiceDocumentCommand(
        id: commandId,
        tenantId: tenantId,
        operationId: operationId,
        electronicInvoiceId: invoice.electronicInvoiceId,
        documentType: documentType,
        operationGeneration: op.generation,
        attemptOrdinal: attemptOrdinal,
        correlationId: correlationId,
      ),
    );

    return InvoiceDocumentRetrievalDto(
      operationId: operationId,
      status: InvoiceDocumentStatus.pending,
    );
  }

  @override
  Future<OfficialViewOperationContextDto?> loadOfficialViewContext({
    required String tenantId,
    required String operationId,
  }) async {
    final op = state.officialOps[operationId];
    if (op == null || op.tenantId != tenantId) return null;
    final invoice = state.invoicesBySalesOrder.values.firstWhere(
      (item) => item.electronicInvoiceId == op.electronicInvoiceId,
    );
    return OfficialViewOperationContextDto(
      operationId: op.operationId,
      tenantId: op.tenantId,
      electronicInvoiceId: op.electronicInvoiceId,
      generation: op.generation,
      attemptOrdinal: op.attemptOrdinal,
      status: op.status,
      providerConnectionId: op.providerConnectionId,
      providerInvoiceReference: invoice.providerInvoiceReference,
      invoiceSeries: invoice.invoiceSeries,
      expectedVersion: op.version,
    );
  }

  @override
  Future<InvoiceDocumentOperationContextDto?> loadDocumentContext({
    required String tenantId,
    required String operationId,
  }) async {
    final op = state.documentOps[operationId];
    if (op == null || op.tenantId != tenantId) return null;
    final invoice = state.invoicesBySalesOrder.values.firstWhere(
      (item) => item.electronicInvoiceId == op.electronicInvoiceId,
    );
    return InvoiceDocumentOperationContextDto(
      operationId: op.operationId,
      tenantId: op.tenantId,
      electronicInvoiceId: op.electronicInvoiceId,
      documentType: op.documentType,
      generation: op.generation,
      attemptOrdinal: op.attemptOrdinal,
      documentVersion: op.documentVersion,
      status: op.status,
      providerConnectionId: op.providerConnectionId,
      providerInvoiceReference: invoice.providerInvoiceReference,
      invoiceSeries: invoice.invoiceSeries,
      expectedVersion: op.version,
    );
  }

  @override
  Future<ProviderObservationOperationContextDto?> loadObservationContext({
    required String tenantId,
    required String commandId,
  }) async {
    final command = internalClient.commands
        .where((c) => c.id == commandId)
        .firstOrNull;
    if (command == null || command.tenantId != tenantId) return null;
    final electronicInvoiceId =
        command.payload['electronic_invoice_id'] as String;
    final invoice = state.invoicesBySalesOrder.values.firstWhere(
      (item) => item.electronicInvoiceId == electronicInvoiceId,
    );
    return ProviderObservationOperationContextDto(
      commandId: commandId,
      tenantId: tenantId,
      electronicInvoiceId: electronicInvoiceId,
      providerConnectionId: invoice.providerConnectionId,
      providerInvoiceReference: invoice.providerInvoiceReference,
      invoiceSeries: invoice.invoiceSeries,
      triggerId: command.payload['trigger_id'] as String,
      correlationId: command.payload['correlation_id'] as String,
    );
  }

  @override
  Future<void> recordOfficialViewResult(OfficialViewResultRecord record) async {
    final op = state.officialOps[record.operationId];
    if (op == null || op.version != record.expectedVersion) return;
    op.status = record.status;
    op.viewerUrl = record.viewerUrl;
    op.expiresAt = record.expiresAt;
    op.failureCode = record.failureCode;
    op.version++;
  }

  @override
  Future<void> recordDocumentResult(InvoiceDocumentResultRecord record) async {
    final op = state.documentOps[record.operationId];
    if (op == null || op.version != record.expectedOperationVersion) return;
    op.status = record.status;
    op.downloadUrl = record.downloadUrl;
    op.checksum = record.checksum;
    op.accessExpiresAt = record.accessExpiresAt;
    op.fileRef = record.fileRef;
    op.failureCode = record.failureCode;
    op.version++;
    if (record.status == InvoiceDocumentStatus.available) {
      op.documentVersion++;
    }
  }

  @override
  Future<ProviderObservationDto> recordProviderObservation(
    ProviderObservationRecord record,
  ) async {
    state.observations.add(record);
    if (record.providerStateCode == 'NOT_FOUND' ||
        record.providerStateCode == 'MISMATCH') {
      state.attentionEvents.add(
        ProviderObservationAttentionRequiredIntegrationEvent(
          id: 'evt-attention-${state.attentionEvents.length + 1}',
          occurredOn: fixedNow,
          tenantId: record.tenantId,
          observationId: 'obs-${state.observations.length}',
          electronicInvoiceId: record.electronicInvoiceId,
          providerStateCode: record.providerStateCode,
          providerInteractionReference: record.providerInteractionReference,
        ),
      );
    }
    return ProviderObservationDto(
      observationId: 'obs-${state.observations.length}',
      electronicInvoiceId: record.electronicInvoiceId,
      providerStateCode: record.providerStateCode,
      observedAt: record.observedAt,
      safeDescription: record.safeDescription,
      providerReference: record.providerReference,
      source: record.source,
      correlationId: 'corr-obs-${state.observations.length}',
      detailsSnapshot: record.detailsSnapshot,
    );
  }

  void enqueueObservation({
    required String tenantId,
    required String electronicInvoiceId,
    required String triggerId,
  }) {
    final alreadyQueued = internalClient.commands.any(
      (command) =>
          command.commandType == PollProviderObservationCommand.type &&
          command.payload['trigger_id'] == triggerId &&
          command.processedAt == null &&
          command.failedAt == null,
    );
    if (alreadyQueued) {
      return;
    }
    final invoice = state.invoicesBySalesOrder.values.firstWhere(
      (item) => item.electronicInvoiceId == electronicInvoiceId,
    );
    final commandId = 'cmd-obs-$triggerId';
    internalClient.enqueue(
      PollProviderObservationCommand(
        id: commandId,
        tenantId: tenantId,
        providerConnectionId: invoice.providerConnectionId,
        electronicInvoiceId: electronicInvoiceId,
        triggerId: triggerId,
        correlationId: 'corr-obs-$triggerId',
      ),
    );
  }
}

final class Slice4ProviderInteractionGateway
    implements IProviderInteractionGateway {
  Slice4ProviderInteractionGateway({
    required this.state,
    required this.fixedNow,
  });

  final Slice4State state;
  final DateTime fixedNow;
  int startCount = 0;

  @override
  Future<ProviderInteractionRecord> start({
    required String tenantId,
    required String providerConnectionId,
    required ProviderInteractionDirection direction,
    required String operationType,
    required String targetType,
    required String targetId,
    required String correlationId,
    required String requestReference,
  }) async {
    startCount++;
    final existing = state.interactionsByCorrelation[correlationId];
    if (existing != null && existing.completed) {
      return ProviderInteractionRecord(
        interactionReference: existing.interactionReference,
        tenantId: existing.tenantId,
        version: existing.version,
        providerConnectionId: existing.providerConnectionId,
        direction: existing.direction,
        operationType: existing.operationType,
        targetType: existing.targetType,
        targetId: existing.targetId,
        correlationId: existing.correlationId,
        requestReference: existing.requestReference,
        status: ProviderInteractionStatus.completed,
        startedAt: existing.startedAt,
        outcome: existing.outcome,
        completedAt: existing.completedAt,
        providerReference: existing.providerReference,
        safeErrorCode: existing.safeErrorCode,
      );
    }

    final interaction = Slice4Interaction(
      interactionReference: 'int-$correlationId',
      tenantId: tenantId,
      version: 0,
      providerConnectionId: providerConnectionId,
      direction: direction,
      operationType: operationType,
      targetType: targetType,
      targetId: targetId,
      correlationId: correlationId,
      requestReference: requestReference,
      startedAt: fixedNow,
    );
    state.interactionsByCorrelation[correlationId] = interaction;

    return ProviderInteractionRecord(
      interactionReference: interaction.interactionReference,
      tenantId: tenantId,
      version: 0,
      providerConnectionId: providerConnectionId,
      direction: direction,
      operationType: operationType,
      targetType: targetType,
      targetId: targetId,
      correlationId: correlationId,
      requestReference: requestReference,
      status: ProviderInteractionStatus.started,
      startedAt: fixedNow,
    );
  }

  @override
  Future<ProviderInteractionRecord> finalize({
    required String tenantId,
    required String interactionReference,
    required int expectedVersion,
    required ProviderInteractionOutcome outcome,
    String? responseReference,
    String? providerReference,
    String? safeErrorCode,
  }) async {
    final interaction = state.interactionsByCorrelation.values.firstWhere(
      (item) => item.interactionReference == interactionReference,
    );
    interaction.version = expectedVersion + 1;
    interaction.outcome = outcome;
    interaction.providerReference = providerReference;
    interaction.safeErrorCode = safeErrorCode;
    interaction.completedAt = fixedNow.add(const Duration(minutes: 1));
    interaction.completed = true;

    return ProviderInteractionRecord(
      interactionReference: interaction.interactionReference,
      tenantId: tenantId,
      version: interaction.version,
      providerConnectionId: interaction.providerConnectionId,
      direction: interaction.direction,
      operationType: interaction.operationType,
      targetType: interaction.targetType,
      targetId: interaction.targetId,
      correlationId: interaction.correlationId,
      requestReference: interaction.requestReference,
      status: ProviderInteractionStatus.completed,
      startedAt: interaction.startedAt,
      outcome: outcome,
      completedAt: interaction.completedAt,
      providerReference: providerReference,
      safeErrorCode: safeErrorCode,
    );
  }
}

final class Slice4DocumentStoragePort implements IInvoiceDocumentStoragePort {
  Slice4DocumentStoragePort({required this.state});

  final Slice4State state;

  @override
  Future<StoredInvoiceDocumentDto> store({
    required String tenantId,
    required String electronicInvoiceId,
    required InvoiceDocumentType documentType,
    required int documentVersion,
    required List<int> bytes,
  }) async {
    state.storageUploadCount++;
    final key = '$electronicInvoiceId:${documentType.name}:$documentVersion';
    state.storedDocumentBytes[key] = List<int>.from(bytes);
    return StoredInvoiceDocumentDto(
      storageReference: 'storage://$key',
      checksum: 'sha256-test',
      contentType: documentType == InvoiceDocumentType.pdf
          ? 'application/pdf'
          : 'application/xml',
      fileName: documentType == InvoiceDocumentType.pdf
          ? 'invoice.pdf'
          : 'invoice.xml',
      fileSize: bytes.length,
    );
  }
}

final class Slice4TestHarness {
  static final fixedNow = DateTime.utc(2026, 8, 31, 9);

  late final GetIt container;
  late final Slice4State state;
  late final Slice4InternalCommandClient internalClient;
  late final Slice4ElectronicInvoiceCommandGateway commandGateway;
  late final Slice4ProviderInteractionGateway interactionGateway;
  late final Slice4DocumentStoragePort storagePort;
  late final FakeMeInvoiceClient fakeMeInvoiceClient;
  late final MeInvoiceElectronicInvoiceProviderAdapter providerAdapter;
  late final CommandBus commandBus;
  late final ProcessInternalCommandsCommandHandler processInternalHandler;

  void setUp() {
    container = GetIt.asNewInstance();
    state = Slice4State();
    final serializer = createGeneratedEinvoiceInternalCommandSerializer();
    internalClient = Slice4InternalCommandClient(serializer: serializer);
    commandGateway = Slice4ElectronicInvoiceCommandGateway(
      state: state,
      internalClient: internalClient,
      fixedNow: fixedNow,
    );
    interactionGateway = Slice4ProviderInteractionGateway(
      state: state,
      fixedNow: fixedNow,
    );
    storagePort = Slice4DocumentStoragePort(state: state);

    final fakeSupabase = _FakeEinvoiceRpcSupabase();
    fakeSupabase.registerHandler(
      'read_provider_credentials',
      (_) async => [
        {
          'tax_code': '0100109106',
          'base_url': MeInvoiceConfig.testBaseUrl,
          'username': 'user',
          'password': 'pass',
        },
      ],
    );
    final rpcClient = SupabaseSchemaRpcClient(
      supabase: fakeSupabase,
      schema: 'einvoice',
      mapError: (error, [stackTrace]) => RpcException(error.toString()),
      logger: const NullLoggerFactory().named('einvoice.rpc'),
    );

    fakeMeInvoiceClient = FakeMeInvoiceClient();
    final clientFactory = TenantMeInvoiceClientFactory();
    clientFactory.setClientForTesting(
      tenantId: tenantId,
      client: fakeMeInvoiceClient,
      config: MeInvoiceConfig(
        baseUrl: MeInvoiceConfig.testBaseUrl,
        appId: 'test-app',
        taxCode: '0100109106',
        username: 'user',
        password: 'pass',
      ),
    );

    providerAdapter = MeInvoiceElectronicInvoiceProviderAdapter(
      rpcClient: rpcClient,
      clientFactory: clientFactory,
      defaultAppId: 'test-app',
      defaultBaseUrl: MeInvoiceConfig.testBaseUrl,
      now: () => fixedNow,
    );

    final commandLogger = const NullLoggerFactory().named('einvoice.commands');
    commandBus = CommandBus(logger: commandLogger, container: container);
    container.registerSingleton<CommandBus>(commandBus);
    EinvoiceCommandsExecutor.bind(commandBus);

    final commandDispatcher = EinvoiceCommandDispatcher(commandBus: commandBus);

    container
      ..registerSingleton<IElectronicInvoiceCommandGateway>(commandGateway)
      ..registerSingleton<IProviderInteractionGateway>(interactionGateway)
      ..registerSingleton<IInvoiceDocumentStoragePort>(storagePort)
      ..registerSingleton<IElectronicInvoiceProviderPort>(providerAdapter)
      ..registerSingleton<IEinvoiceCommandDispatcher>(commandDispatcher)
      ..registerSingleton<InternalCommandSerializer>(serializer)
      ..registerSingleton<IEinvoiceInternalCommandClient>(internalClient);

    final requestOfficialHandler = RequestOfficialInvoiceViewCommandHandler(
      gateway: commandGateway,
    );
    final requestDocumentHandler = RequestInvoiceDocumentCommandHandler(
      gateway: commandGateway,
    );
    final fetchOfficialHandler = FetchOfficialInvoiceViewCommandHandler(
      commandGateway: commandGateway,
      providerPort: providerAdapter,
      interactionGateway: interactionGateway,
    );
    final downloadDocumentHandler = DownloadInvoiceDocumentCommandHandler(
      commandGateway: commandGateway,
      providerPort: providerAdapter,
      interactionGateway: interactionGateway,
      storagePort: storagePort,
    );
    final pollObservationHandler = PollProviderObservationCommandHandler(
      commandGateway: commandGateway,
      providerPort: providerAdapter,
      interactionGateway: interactionGateway,
      commandDispatcher: commandDispatcher,
    );
    final recordObservationHandler = RecordProviderObservationCommandHandler(
      gateway: commandGateway,
    );

    commandBus
      ..register<RequestOfficialInvoiceViewCommand, OfficialInvoiceViewDto>(
        requestOfficialHandler.handle,
      )
      ..register<RequestInvoiceDocumentCommand, InvoiceDocumentRetrievalDto>(
        requestDocumentHandler.handle,
      )
      ..register<FetchOfficialInvoiceViewCommand, void>(
        fetchOfficialHandler.handle,
      )
      ..register<DownloadInvoiceDocumentCommand, void>(
        downloadDocumentHandler.handle,
      )
      ..register<PollProviderObservationCommand, void>(
        pollObservationHandler.handle,
      )
      ..register<RecordProviderObservationCommand, ProviderObservationDto>(
        recordObservationHandler.handle,
      );

    final deadLetterHandlers =
        <String, IEinvoiceInternalCommandDeadLetterHandler>{
          FetchOfficialInvoiceViewCommand.type:
              OfficialViewCommandDeadLetterHandler(
                commandGateway: commandGateway,
                interactionGateway: interactionGateway,
              ),
          DownloadInvoiceDocumentCommand.type:
              InvoiceDocumentCommandDeadLetterHandler(
                commandGateway: commandGateway,
                interactionGateway: interactionGateway,
              ),
        };

    processInternalHandler = ProcessInternalCommandsCommandHandler(
      commandClient: internalClient,
      serializer: serializer,
      deadLetterHandlers: deadLetterHandlers,
    );

    commandBus.register<ProcessInternalCommandsCommand, bool>(
      processInternalHandler.handle,
    );

    seedDefaultInvoice();
  }

  static const tenantId = 'tenant-s4-1';
  static const actorId = 'actor-s4-1';
  static const salesOrderId = 'order-s4-1';
  static const electronicInvoiceId = 'ei-s4-1';
  static const providerConnectionId = 'conn-s4-1';

  void seedDefaultInvoice() {
    state.accessibleSalesOrders.add(salesOrderId);
    state.permittedActors.add(actorId);
    state.invoicesBySalesOrder[salesOrderId] = Slice4ElectronicInvoiceRecord(
      electronicInvoiceId: electronicInvoiceId,
      salesOrderId: salesOrderId,
      providerConnectionId: providerConnectionId,
      providerInvoiceReference: 'tx-s4-1',
      invoiceSeries: '1C26TYY',
    );
    state.supportedDocumentTypes[providerConnectionId] = ['PDF', 'XML'];
  }

  Future<void> runWorker() async {
    await commandBus.execute(
      ProcessInternalCommandsCommand(tenantId: tenantId),
    );
  }

  Future<OfficialInvoiceViewDto> requestOfficialView() async {
    return commandBus.execute(
      RequestOfficialInvoiceViewCommand(
        tenantId: tenantId,
        actorId: actorId,
        salesOrderId: salesOrderId,
      ),
    );
  }

  Future<InvoiceDocumentRetrievalDto> requestDocument({
    required InvoiceDocumentType documentType,
    required String idempotencyKey,
  }) async {
    return commandBus.execute(
      RequestInvoiceDocumentCommand(
        tenantId: tenantId,
        actorId: actorId,
        salesOrderId: salesOrderId,
        documentType: documentType,
        idempotencyKey: idempotencyKey,
      ),
    );
  }
}
