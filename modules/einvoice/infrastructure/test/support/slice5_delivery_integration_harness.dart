import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:get_it/get_it.dart';
import 'package:uuid/uuid.dart';
import 'package:vet45_adapters/vet45_adapters.dart'
    hide InternalCommandSerializer, ISerializableInternalCommand;
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_infrastructure/src/adapters/misa/me_invoice_delivery_observation_provider_adapter.dart';
import 'package:vet45_einvoice_infrastructure/src/adapters/misa/me_invoice_delivery_provider_adapter.dart';
import 'package:vet45_einvoice_infrastructure/src/adapters/misa/tenant_me_invoice_client_factory.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/outbox/outbox_module.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/commands_executor.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/einvoice_command_dispatcher.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/einvoice_integration_event_dispatcher.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/generated/einvoice_internal_command_registry.g.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/generated/einvoice_integration_event_registry.g.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/internal_commands/delivery_command_dead_letter_handler.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/internal_commands/delivery_reconciliation_command_dead_letter_handler.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/internal_commands/i_einvoice_internal_command_client.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/internal_commands/i_einvoice_internal_command_dead_letter_handler.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/internal_commands/process_internal_commands_command.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/internal_commands/process_internal_commands_command_handler.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/inbox/i_einvoice_inbox_client.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/inbox/process_inbox_command.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/inbox/process_inbox_command_handler.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/outbox/i_einvoice_outbox_client.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/outbox/process_outbox_command.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/outbox/process_outbox_command_handler.dart';
import 'package:vet45_einvoice_infrastructure/src/domain/delivery/supabase_delivery_command_gateway.dart';
import 'package:vet45_einvoice_infrastructure/src/domain/delivery/supabase_delivery_read_gateway.dart';
import 'package:vet45_einvoice_infrastructure/src/domain/delivery/supabase_delivery_reconciliation_gateway.dart';
import 'package:vet45_einvoice_integration_events/integration_events.dart';
import 'package:vet45_misa/e_invoice.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import 'fake_einvoice_rpc_supabase.dart';

String _sha256Hex(String input) =>
    sha256.convert(utf8.encode(input)).toString();

String _deterministicUuid(String seed) {
  final hex = _sha256Hex(seed);
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
      '${hex.substring(20, 32)}';
}

String deliveryIntentHash(Map<String, dynamic> intent) =>
    _sha256Hex(jsonEncode(intent));

String deliverySendCommandId(String deliveryId, int retryCount) =>
    _deterministicUuid('$deliveryId|send_invoice_email|$retryCount');

String deliveryReconciliationCommandId(String caseId, int sequence) =>
    _deterministicUuid('$caseId|$sequence');

({String displayState, bool hasSecondaryAttention}) deliveryDisplayProjection(
  List<String> statuses,
) {
  if (statuses.isEmpty) {
    return (displayState: 'NOT_SENT', hasSecondaryAttention: false);
  }
  final hasSuccess = statuses.contains('SUCCEEDED');
  final latest = statuses.last;
  if (hasSuccess) {
    return (
      displayState: 'SENT',
      hasSecondaryAttention: latest == 'FAILED' || latest == 'UNKNOWN',
    );
  }
  if (statuses.contains('PROCESSING') ||
      statuses.contains('QUEUED') ||
      statuses.contains('SUBMITTED')) {
    return (displayState: 'SENDING', hasSecondaryAttention: false);
  }
  if (statuses.contains('UNKNOWN')) {
    return (displayState: 'UNKNOWN', hasSecondaryAttention: false);
  }
  return (displayState: 'FAILED', hasSecondaryAttention: false);
}

final class Slice5PartnerRecipient {
  Slice5PartnerRecipient({
    required this.partnerId,
    this.invoiceEmail,
    this.recipientName,
    this.isActive = true,
  });

  final String partnerId;
  final String? invoiceEmail;
  final String? recipientName;
  final bool isActive;
}

final class Slice5ElectronicInvoice {
  Slice5ElectronicInvoice({
    required this.electronicInvoiceId,
    required this.tenantId,
    required this.salesOrderId,
    required this.providerConnectionId,
    required this.providerInvoiceReference,
    required this.invoiceSeries,
    this.buyerPartnerId,
    this.buyerSnapshotEmail,
    this.buyerSnapshotName,
    this.effectiveBuyerEmail,
  });

  final String electronicInvoiceId;
  final String tenantId;
  final String salesOrderId;
  final String providerConnectionId;
  final String providerInvoiceReference;
  final String invoiceSeries;
  final String? buyerPartnerId;
  final String? buyerSnapshotEmail;
  final String? buyerSnapshotName;
  final String? effectiveBuyerEmail;
}

final class Slice5ProviderConnection {
  Slice5ProviderConnection({
    required this.id,
    required this.tenantId,
    this.supportsEmailDelivery = true,
    this.supportsDeliveryResultObservation = false,
    this.status = 'CONNECTED',
  });

  final String id;
  final String tenantId;
  bool supportsEmailDelivery;
  bool supportsDeliveryResultObservation;
  String status;
}

final class Slice5DeliveryRecord {
  Slice5DeliveryRecord({
    required this.id,
    required this.tenantId,
    required this.electronicInvoiceId,
    required this.salesOrderId,
    required this.deliveryNo,
    required this.deliveryIntent,
    required this.triggerType,
    required this.recipientSnapshot,
    required this.idempotencyKey,
    required this.intentHash,
    required this.initiatedByActorType,
    this.initiatedByActorId,
    this.startedAt,
  }) : status = 'QUEUED',
       retryCount = 0,
       version = 0;

  final String id;
  final String tenantId;
  final String electronicInvoiceId;
  final String salesOrderId;
  final int deliveryNo;
  final String deliveryIntent;
  final String triggerType;
  final Map<String, dynamic> recipientSnapshot;
  final String idempotencyKey;
  final String intentHash;
  final String initiatedByActorType;
  final String? initiatedByActorId;
  final DateTime? startedAt;
  String status;
  int retryCount;
  int version;
  String? providerDeliveryReference;
  DateTime? completedAt;
}

final class Slice5AttemptRecord {
  Slice5AttemptRecord({
    required this.id,
    required this.tenantId,
    required this.deliveryId,
    required this.attemptNo,
    required this.providerConnectionId,
  }) : status = 'QUEUED',
       version = 0;

  final String id;
  final String tenantId;
  final String deliveryId;
  final int attemptNo;
  final String providerConnectionId;
  String status;
  int version;
  String? providerRequestReference;
  String? interactionReference;
  DateTime? submittedAt;
  DateTime? completedAt;
}

final class Slice5ReconciliationCaseRecord {
  Slice5ReconciliationCaseRecord({
    required this.id,
    required this.tenantId,
    required this.attemptId,
    required this.deliveryId,
    required this.providerConnectionId,
    required this.reasonCode,
  }) : status = 'PENDING',
       attemptCount = 0,
       version = 0;

  final String id;
  final String tenantId;
  final String attemptId;
  final String deliveryId;
  final String providerConnectionId;
  final String reasonCode;
  String status;
  int attemptCount;
  int version;
  DateTime? nextCheckAt;
}

final class Slice5OutboxMessage {
  Slice5OutboxMessage({
    required this.messageId,
    required this.eventType,
    required this.payload,
    required this.occurredAt,
  });

  final String messageId;
  final String eventType;
  final Map<String, dynamic> payload;
  final DateTime occurredAt;
  String? claimToken;
  bool completed = false;
}

final class Slice5State {
  bool autoSendEnabled = true;
  final Set<String> permittedActors = {};
  final Set<String> accessibleSalesOrders = {};
  final Map<String, Slice5ElectronicInvoice> invoicesBySalesOrder = {};
  final Map<String, Slice5ElectronicInvoice> invoicesById = {};
  final Map<String, Slice5ProviderConnection> connections = {};
  final Map<String, Slice5PartnerRecipient> partners = {};
  final Map<String, Slice5DeliveryRecord> deliveries = {};
  final Map<String, Slice5AttemptRecord> attempts = {};
  final Map<String, Slice5ReconciliationCaseRecord> reconciliationCases = {};
  final List<Slice5OutboxMessage> outbox = [];
  final List<DeliveryResultRecordedIntegrationEvent> resultEvents = [];
  final List<DeliveryAttentionRequiredIntegrationEvent> attentionEvents = [];
  int deliveryCounter = 0;
  int attemptCounter = 0;
  int caseCounter = 0;
}

final class Slice5InternalCommandClient
    implements IEinvoiceInternalCommandClient {
  Slice5InternalCommandClient({required this.serializer});

  final InternalCommandSerializer serializer;
  final List<_StoredCommand> commands = [];

  void enqueue(ISerializableInternalCommand command) {
    if (command is! CommandBase) {
      throw ArgumentError('command must extend CommandBase');
    }
    final base = command as CommandBase<void>;
    final commandId = base.id;
    if (commands.any((c) => c.id == commandId)) {
      return;
    }
    commands.add(
      _StoredCommand(
        id: commandId,
        tenantId: serializer.tenantIdOf(command),
        commandType: serializer.commandTypeOf(command),
        payload: serializer.toPayload(command),
        enqueuedAt: Slice5TestHarness.fixedNow,
      ),
    );
  }

  int countPending(String commandType) => commands
      .where(
        (c) =>
            c.commandType == commandType &&
            c.processedAt == null &&
            c.failedAt == null,
      )
      .length;

  int countByType(String commandType) =>
      commands.where((c) => c.commandType == commandType).length;

  @override
  Future<int> seedDueReconciliationCommands({
    required String tenantId,
    int limit = 50,
  }) async {
    var seeded = 0;
    final now = Slice5TestHarness.fixedNow;
    for (final caseRecord in _casesForTenant(tenantId)) {
      if (seeded >= limit) break;
      if (caseRecord.status != 'PENDING') continue;
      if (caseRecord.nextCheckAt != null &&
          caseRecord.nextCheckAt!.isAfter(now)) {
        continue;
      }
      final nextSequence = caseRecord.attemptCount + 1;
      if (nextSequence > 5) continue;
      final cmdId = deliveryReconciliationCommandId(
        caseRecord.id,
        nextSequence,
      );
      if (commands.any((c) => c.id == cmdId)) continue;
      enqueue(
        ReconcileInvoiceDeliveryCommand(
          id: cmdId,
          tenantId: tenantId,
          reconciliationCaseId: caseRecord.id,
          checkSequence: nextSequence,
        ),
      );
      seeded++;
    }
    return seeded;
  }

  Iterable<Slice5ReconciliationCaseRecord> _casesForTenant(String tenantId) =>
      []; // wired via harness reference

  void bindCases(
    Iterable<Slice5ReconciliationCaseRecord> Function(String tenantId) resolver,
  ) {
    _casesResolver = resolver;
  }

  Iterable<Slice5ReconciliationCaseRecord> Function(String tenantId)?
  _casesResolver;

  Iterable<Slice5ReconciliationCaseRecord> casesForTenant(String tenantId) =>
      _casesResolver?.call(tenantId) ?? const [];

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
    command.processedAt = Slice5TestHarness.fixedNow;
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
    if (command == null) throw StateError('Command not found');
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
    command.failedAt = Slice5TestHarness.fixedNow;
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

final class Slice5InboxClient implements IEinvoiceInboxClient {
  final List<String> receivedMessageIds = [];
  final List<ClaimedInboxMessage> _pending = [];

  @override
  Future<String> receive({
    required String tenantId,
    required String messageId,
    required String eventType,
    required Map<String, dynamic> payload,
    required DateTime occurredAt,
  }) async {
    if (receivedMessageIds.contains(messageId)) {
      return messageId;
    }
    receivedMessageIds.add(messageId);
    _pending.add(
      ClaimedInboxMessage(
        messageId: messageId,
        eventType: eventType,
        payload: Map<String, dynamic>.from(payload),
        occurredAt: occurredAt,
        claimToken: 'tok-$messageId',
      ),
    );
    return messageId;
  }

  @override
  Future<List<ClaimedInboxMessage>> claimBatch({
    required String tenantId,
    required int limit,
  }) async {
    final batch = _pending.take(limit).toList(growable: false);
    _pending.removeRange(0, batch.length);
    return batch;
  }

  @override
  Future<void> complete({
    required String tenantId,
    required String messageId,
    required String claimToken,
  }) async {}

  @override
  Future<void> fail({
    required String tenantId,
    required String messageId,
    required String claimToken,
    required String error,
  }) async {}
}

final class Slice5OutboxClient implements IEinvoiceOutboxClient {
  Slice5OutboxClient(this.state);

  final Slice5State state;

  @override
  Future<List<ClaimedOutboxMessage>> claimBatch({
    required String tenantId,
    required int limit,
  }) async {
    final pending = state.outbox
        .where((m) => !m.completed && m.claimToken == null)
        .take(limit)
        .toList(growable: false);
    for (final message in pending) {
      message.claimToken = 'outbox-${message.messageId}';
    }
    return pending
        .map(
          (m) => ClaimedOutboxMessage(
            messageId: m.messageId,
            eventType: m.eventType,
            payload: Map<String, dynamic>.from(m.payload),
            occurredAt: m.occurredAt,
            claimToken: m.claimToken!,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> complete({
    required String tenantId,
    required String messageId,
    required String claimToken,
  }) async {
    final message = state.outbox.firstWhere((m) => m.messageId == messageId);
    message.completed = true;
    message.claimToken = null;
  }

  @override
  Future<void> fail({
    required String tenantId,
    required String messageId,
    required String claimToken,
    required String error,
  }) async {}
}

/// Scriptable observation port for capability-aware reconciliation tests.
final class CapableDeliveryObservationProviderPort
    implements IInvoiceDeliveryObservationProviderPort {
  final Queue<DeliveryObservationOutcome> outcomes = Queue();
  int observeCalls = 0;

  void enqueue(DeliveryObservationOutcome outcome) => outcomes.add(outcome);

  @override
  Future<DeliveryObservationOutcome> observe(
    DeliveryObservationContextDto context,
  ) async {
    observeCalls++;
    if (outcomes.isNotEmpty) {
      return outcomes.removeFirst();
    }
    return const DeliveryObservationUndetermined('PROVIDER_DELIVERY_PENDING');
  }
}

final class Slice5DeliveryRpcEngine {
  Slice5DeliveryRpcEngine({
    required this.state,
    required this.internalClient,
    required this.fixedNow,
  });

  final Slice5State state;
  final Slice5InternalCommandClient internalClient;
  final DateTime fixedNow;

  void registerAll(FakeEinvoiceRpcSupabase supabase) {
    supabase.registerHandler(
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
    supabase.registerHandler('start_auto_delivery', _startAutoDelivery);
    supabase.registerHandler('send_electronic_invoice', _sendElectronicInvoice);
    supabase.registerHandler(
      'load_delivery_attempt_context',
      _loadAttemptContext,
    );
    supabase.registerHandler(
      'prepare_delivery_provider_call',
      _prepareProviderCall,
    );
    supabase.registerHandler('record_delivery_result', _recordDeliveryResult);
    supabase.registerHandler(
      'record_delivery_command_dead_letter',
      _recordCommandDeadLetter,
    );
    supabase.registerHandler(
      'get_send_invoice_sheet_context',
      _getSendSheetContext,
    );
    supabase.registerHandler('get_invoice_delivery_history', _getHistory);
    supabase.registerHandler(
      'load_delivery_reconciliation_context',
      _loadReconciliationContext,
    );
    supabase.registerHandler(
      'record_delivery_reconciliation_check',
      _recordReconciliationCheck,
    );
  }

  Slice5ElectronicInvoice? _invoiceById(String tenantId, String invoiceId) {
    for (final invoice in state.invoicesById.values) {
      if (invoice.tenantId == tenantId &&
          invoice.electronicInvoiceId == invoiceId) {
        return invoice;
      }
    }
    return null;
  }

  Slice5ProviderConnection? _connection(String tenantId, String connectionId) =>
      state.connections['$tenantId:$connectionId'];

  List<Slice5DeliveryRecord> _deliveriesForInvoice(
    String tenantId,
    String electronicInvoiceId,
  ) =>
      state.deliveries.values
          .where(
            (d) =>
                d.tenantId == tenantId &&
                d.electronicInvoiceId == electronicInvoiceId,
          )
          .toList()
        ..sort((a, b) => a.deliveryNo.compareTo(b.deliveryNo));

  List<String> _statusesForInvoice(
    String tenantId,
    String electronicInvoiceId,
  ) => _deliveriesForInvoice(
    tenantId,
    electronicInvoiceId,
  ).map((d) => d.status).toList(growable: false);

  String _publicStatus(String status) =>
      status == 'QUEUED' || status == 'SUBMITTED' ? 'PROCESSING' : status;

  void _emitResultEvent(Slice5DeliveryRecord delivery) {
    final invoice = _invoiceById(
      delivery.tenantId,
      delivery.electronicInvoiceId,
    )!;
    final projection = deliveryDisplayProjection(
      _statusesForInvoice(delivery.tenantId, delivery.electronicInvoiceId),
    );
    final statusCamel = switch (delivery.status) {
      'PROCESSING' || 'QUEUED' || 'SUBMITTED' => 'processing',
      'SUCCEEDED' => 'succeeded',
      'FAILED' => 'failed',
      'UNKNOWN' => 'unknown',
      _ => delivery.status.toLowerCase(),
    };
    final displayCamel = switch (projection.displayState) {
      'NOT_SENT' => 'notSent',
      'SENDING' => 'sending',
      'SENT' => 'sent',
      'FAILED' => 'failed',
      'UNKNOWN' => 'unknown',
      _ => projection.displayState.toLowerCase(),
    };
    final event = DeliveryResultRecordedIntegrationEvent(
      id: 'evt-result-${state.resultEvents.length + 1}',
      occurredOn: fixedNow,
      tenantId: delivery.tenantId,
      salesOrderId: invoice.salesOrderId,
      deliveryId: delivery.id,
      deliveryStatus: statusCamel,
      deliveryDisplayState: displayCamel,
      deliveryVersion: delivery.version,
      hasSecondaryAttention: projection.hasSecondaryAttention,
    );
    state.resultEvents.add(event);
    state.outbox.add(
      Slice5OutboxMessage(
        messageId: event.id,
        eventType: DeliveryResultRecordedIntegrationEvent.type,
        payload: event.toPayload(),
        occurredAt: fixedNow,
      ),
    );
  }

  void _emitAttention({
    required Slice5DeliveryRecord delivery,
    required Slice5ReconciliationCaseRecord caseRecord,
    required String safeErrorCode,
  }) {
    final invoice = _invoiceById(
      delivery.tenantId,
      delivery.electronicInvoiceId,
    )!;
    final event = DeliveryAttentionRequiredIntegrationEvent(
      id: 'evt-attention-${state.attentionEvents.length + 1}',
      occurredOn: fixedNow,
      tenantId: delivery.tenantId,
      electronicInvoiceId: delivery.electronicInvoiceId,
      salesOrderId: invoice.salesOrderId,
      deliveryId: delivery.id,
      reconciliationCaseId: caseRecord.id,
      safeErrorCode: safeErrorCode,
    );
    state.attentionEvents.add(event);
    state.outbox.add(
      Slice5OutboxMessage(
        messageId: event.id,
        eventType: DeliveryAttentionRequiredIntegrationEvent.type,
        payload: event.toPayload(),
        occurredAt: fixedNow,
      ),
    );
  }

  Future<dynamic> _startAutoDelivery(Map<String, dynamic>? params) async {
    final tenantId = params!['p_tenant_id'] as String;
    final electronicInvoiceId = params['p_electronic_invoice_id'] as String;
    final idempotencyKey = params['p_idempotency_key'] as String;
    final intent = {
      'operation': 'AUTO_INITIAL_SEND',
      'electronic_invoice_id': electronicInvoiceId,
      'channel': 'EMAIL',
      'seed': 'auto_initial',
    };
    final intentHash = deliveryIntentHash(intent);

    final existing = state.deliveries.values.where(
      (d) => d.tenantId == tenantId && d.idempotencyKey == idempotencyKey,
    );
    if (existing.isNotEmpty) {
      final delivery = existing.first;
      return [
        {
          'disposition': 'started',
          'delivery_id': delivery.id,
          'skip_reason': null,
        },
      ];
    }

    final invoice = _invoiceById(tenantId, electronicInvoiceId);
    if (invoice == null) {
      throw RpcException('NOT_FOUND: electronic invoice not found');
    }

    if (!state.autoSendEnabled) {
      return [
        {
          'disposition': 'skipped',
          'delivery_id': null,
          'skip_reason': 'POLICY_OFF',
        },
      ];
    }

    final connection = _connection(tenantId, invoice.providerConnectionId);
    if (connection == null ||
        connection.status != 'CONNECTED' ||
        !connection.supportsEmailDelivery) {
      throw RpcException(
        'DELIVERY_NOT_SUPPORTED: email delivery capability missing',
      );
    }

    if (_deliveriesForInvoice(
      tenantId,
      electronicInvoiceId,
    ).any((d) => d.status == 'QUEUED' || d.status == 'SUBMITTED')) {
      throw RpcException('OPERATION_IN_PROGRESS: delivery currently locked');
    }

    if (_deliveriesForInvoice(
      tenantId,
      electronicInvoiceId,
    ).any((d) => d.deliveryIntent == 'INITIAL_SEND')) {
      return [
        {
          'disposition': 'skipped',
          'delivery_id': null,
          'skip_reason': 'INITIAL_DELIVERY_ALREADY_CLAIMED',
        },
      ];
    }

    String? email;
    String? name;
    String? source;
    if (invoice.buyerPartnerId != null) {
      final partner = state.partners[invoice.buyerPartnerId!];
      if (partner != null &&
          partner.isActive &&
          partner.invoiceEmail != null &&
          partner.invoiceEmail!.contains('@')) {
        email = partner.invoiceEmail;
        name = partner.recipientName;
        source = 'CURRENT_PARTNER_PROFILE';
      }
    }
    if (email == null && invoice.buyerSnapshotEmail != null) {
      email = invoice.buyerSnapshotEmail;
      name = invoice.buyerSnapshotName;
      source = 'BUYER_INVOICE_SNAPSHOT';
    }
    if (email == null || !email.contains('@')) {
      return [
        {
          'disposition': 'skipped',
          'delivery_id': null,
          'skip_reason': 'INVALID_OR_MISSING_EMAIL',
        },
      ];
    }

    final snapshot = {
      'toEmail': email,
      'source': source,
      'recipientName': name,
      'ccEmails': <dynamic>[],
      'schemaVersion': '1',
      if (invoice.buyerPartnerId != null)
        'buyerPartnerId': invoice.buyerPartnerId,
    };
    final started = _startDelivery(
      tenantId: tenantId,
      invoice: invoice,
      deliveryIntent: 'INITIAL_SEND',
      triggerType: 'AUTOMATIC',
      snapshot: snapshot,
      idempotencyKey: idempotencyKey,
      intentHash: intentHash,
      actorType: 'SYSTEM',
      actorId: null,
      connectionId: invoice.providerConnectionId,
    );
    return [
      {
        'disposition': 'started',
        'delivery_id': started.deliveryId,
        'skip_reason': null,
      },
    ];
  }

  Future<dynamic> _sendElectronicInvoice(Map<String, dynamic>? params) async {
    final tenantId = params!['p_tenant_id'] as String;
    final actorId = params['p_actor_id'] as String;
    final salesOrderId = params['p_sales_order_id'] as String;
    final recipientEmail = (params['p_recipient_email'] as String).trim();
    final idempotencyKey = params['p_idempotency_key'] as String;

    if (!state.permittedActors.contains(actorId)) {
      throw RpcException('NO_PERMISSION: einvoice.send required');
    }
    if (!state.accessibleSalesOrders.contains(salesOrderId)) {
      throw RpcException('NOT_FOUND: sales order not found');
    }
    if (!recipientEmail.contains('@')) {
      throw RpcException('VALIDATION_ERROR: recipient email is invalid');
    }

    final invoice = state.invoicesBySalesOrder[salesOrderId];
    if (invoice == null || invoice.tenantId != tenantId) {
      throw RpcException('NOT_FOUND: electronic invoice not found');
    }

    final hasInitial = _deliveriesForInvoice(
      tenantId,
      invoice.electronicInvoiceId,
    ).any((d) => d.deliveryIntent == 'INITIAL_SEND');
    final intentKind = hasInitial ? 'RESEND' : 'INITIAL_SEND';
    final intent = {
      'operation': 'MANUAL_SEND',
      'sales_order_id': salesOrderId,
      'electronic_invoice_id': invoice.electronicInvoiceId,
      'delivery_intent': intentKind,
      'recipient_email': recipientEmail,
      'channel': 'EMAIL',
    };
    final intentHash = deliveryIntentHash(intent);

    final existing = state.deliveries.values.where(
      (d) => d.tenantId == tenantId && d.idempotencyKey == idempotencyKey,
    );
    if (existing.isNotEmpty) {
      final delivery = existing.first;
      return [
        {'delivery_id': delivery.id, 'status': _publicStatus(delivery.status)},
      ];
    }

    final connection = _connection(tenantId, invoice.providerConnectionId);
    if (connection == null ||
        connection.status != 'CONNECTED' ||
        !connection.supportsEmailDelivery) {
      throw RpcException(
        'DELIVERY_NOT_SUPPORTED: email delivery capability missing',
      );
    }

    if (_deliveriesForInvoice(
      tenantId,
      invoice.electronicInvoiceId,
    ).any((d) => d.status == 'QUEUED' || d.status == 'SUBMITTED')) {
      throw RpcException('OPERATION_IN_PROGRESS: delivery currently locked');
    }

    final snapshot = {
      'toEmail': recipientEmail,
      'source': 'USER_INPUT',
      'recipientName': null,
      'ccEmails': <dynamic>[],
      'schemaVersion': '1',
    };
    final started = _startDelivery(
      tenantId: tenantId,
      invoice: invoice,
      deliveryIntent: intentKind,
      triggerType: 'MANUAL',
      snapshot: snapshot,
      idempotencyKey: idempotencyKey,
      intentHash: intentHash,
      actorType: 'USER',
      actorId: actorId,
      connectionId: invoice.providerConnectionId,
    );
    return [
      {'delivery_id': started.deliveryId, 'status': 'PROCESSING'},
    ];
  }

  ({String deliveryId, String attemptId}) _startDelivery({
    required String tenantId,
    required Slice5ElectronicInvoice invoice,
    required String deliveryIntent,
    required String triggerType,
    required Map<String, dynamic> snapshot,
    required String idempotencyKey,
    required String intentHash,
    required String actorType,
    required String? actorId,
    required String connectionId,
  }) {
    state.deliveryCounter++;
    final deliveryId = 'del-${state.deliveryCounter}';
    final attemptId = 'att-${++state.attemptCounter}';
    final deliveryNo =
        _deliveriesForInvoice(tenantId, invoice.electronicInvoiceId).length + 1;
    final delivery = Slice5DeliveryRecord(
      id: deliveryId,
      tenantId: tenantId,
      electronicInvoiceId: invoice.electronicInvoiceId,
      salesOrderId: invoice.salesOrderId,
      deliveryNo: deliveryNo,
      deliveryIntent: deliveryIntent,
      triggerType: triggerType,
      recipientSnapshot: snapshot,
      idempotencyKey: idempotencyKey,
      intentHash: intentHash,
      initiatedByActorType: actorType,
      initiatedByActorId: actorId,
      startedAt: fixedNow,
    );
    state.deliveries[deliveryId] = delivery;
    final attempt = Slice5AttemptRecord(
      id: attemptId,
      tenantId: tenantId,
      deliveryId: deliveryId,
      attemptNo: 1,
      providerConnectionId: connectionId,
    );
    state.attempts[attemptId] = attempt;
    internalClient.enqueue(
      SendInvoiceEmailCommand(
        id: deliverySendCommandId(deliveryId, 0),
        tenantId: tenantId,
        deliveryId: deliveryId,
        retryCount: 0,
      ),
    );
    return (deliveryId: deliveryId, attemptId: attemptId);
  }

  Future<dynamic> _loadAttemptContext(Map<String, dynamic>? params) async {
    final tenantId = params!['p_tenant_id'] as String;
    final deliveryId = params['p_delivery_id'] as String;
    final retryCount = params['p_retry_count'] as int;
    final delivery = state.deliveries[deliveryId];
    if (delivery == null ||
        delivery.tenantId != tenantId ||
        delivery.retryCount != retryCount) {
      return <Map<String, dynamic>>[];
    }
    final attempt = state.attempts.values
        .where((item) => item.deliveryId == deliveryId)
        .firstOrNull;
    if (attempt == null) {
      return <Map<String, dynamic>>[];
    }
    final invoice = _invoiceById(tenantId, delivery.electronicInvoiceId)!;
    return [
      {
        'tenant_id': tenantId,
        'delivery_id': deliveryId,
        'retry_count': delivery.retryCount,
        'delivery_version': delivery.version,
        'provider_connection_id': attempt.providerConnectionId,
        'provider_transaction_id': invoice.providerInvoiceReference,
        'invoice_series': invoice.invoiceSeries,
        'recipient_email': delivery.recipientSnapshot['toEmail'],
        'recipient_name': delivery.recipientSnapshot['recipientName'],
      },
    ];
  }

  Future<dynamic> _prepareProviderCall(Map<String, dynamic>? params) async {
    final tenantId = params!['p_tenant_id'] as String;
    final deliveryId = params['p_delivery_id'] as String;
    final retryCount = params['p_retry_count'] as int;
    final delivery = state.deliveries[deliveryId]!;
    final attempt = state.attempts.values
        .where((item) => item.deliveryId == deliveryId)
        .first;
    final invoice = _invoiceById(tenantId, delivery.electronicInvoiceId)!;
    if (delivery.retryCount != retryCount ||
        delivery.status == 'SUCCEEDED' ||
        delivery.status == 'FAILED' ||
        delivery.status == 'UNKNOWN') {
      return [
        {
          'action': 'SKIP',
          'delivery_version': delivery.version,
          'provider_connection_id': null,
          'provider_transaction_id': null,
          'invoice_series': null,
          'recipient_email': null,
          'recipient_name': null,
        },
      ];
    }
    if (delivery.status == 'SUBMITTED') {
      return [
        {
          'action': 'RECORD_UNKNOWN',
          'delivery_version': delivery.version,
          'provider_connection_id': attempt.providerConnectionId,
          'provider_transaction_id': invoice.providerInvoiceReference,
          'invoice_series': invoice.invoiceSeries,
          'recipient_email': delivery.recipientSnapshot['toEmail'],
          'recipient_name': delivery.recipientSnapshot['recipientName'],
        },
      ];
    }
    delivery.status = 'SUBMITTED';
    attempt.status = 'SUBMITTED';
    attempt.providerRequestReference = params['p_request_reference'] as String;
    attempt.submittedAt = fixedNow;
    delivery.version++;
    return [
      {
        'action': 'CALL_PROVIDER',
        'delivery_version': delivery.version,
        'provider_connection_id': attempt.providerConnectionId,
        'provider_transaction_id': invoice.providerInvoiceReference,
        'invoice_series': invoice.invoiceSeries,
        'recipient_email': delivery.recipientSnapshot['toEmail'],
        'recipient_name': delivery.recipientSnapshot['recipientName'],
      },
    ];
  }

  Future<dynamic> _recordDeliveryResult(Map<String, dynamic>? params) async {
    final tenantId = params!['p_tenant_id'] as String;
    final deliveryId = params['p_delivery_id'] as String;
    final retryCount = params['p_retry_count'] as int;
    final expectedVersion = params['p_expected_version'] as int;
    final outcomeKind = params['p_outcome_kind'] as String;
    final providerReference = params['p_provider_reference'] as String?;
    final safeCode = params['p_safe_code'] as String?;
    final delivery = state.deliveries[deliveryId]!;
    final attempt = state.attempts.values
        .where((item) => item.deliveryId == deliveryId)
        .first;

    if (delivery.retryCount != retryCount ||
        delivery.status == 'SUCCEEDED' ||
        delivery.status == 'FAILED' ||
        delivery.status == 'UNKNOWN') {
      final projection = deliveryDisplayProjection(
        _statusesForInvoice(tenantId, delivery.electronicInvoiceId),
      );
      return [
        {
          'delivery_status': _publicStatus(delivery.status),
          'display_state': projection.displayState,
          'has_secondary_attention': projection.hasSecondaryAttention,
        },
      ];
    }

    if (delivery.version != expectedVersion) {
      throw RpcException('STATE_CHANGED: expected version mismatch');
    }

    var completed = true;
    switch (outcomeKind) {
      case 'SUCCESS':
        attempt.status = 'SUCCEEDED';
        delivery.status = 'SUCCEEDED';
        delivery.providerDeliveryReference = providerReference;
      case 'DEFINITE_FAILURE':
        attempt.status = 'FAILED';
        delivery.status = 'FAILED';
      case 'RETRYABLE_FAILURE':
        attempt.status = 'FAILED';
        if (delivery.retryCount < 2) {
          delivery.retryCount += 1;
          delivery.status = 'QUEUED';
          completed = false;
          internalClient.enqueue(
            SendInvoiceEmailCommand(
              id: deliverySendCommandId(deliveryId, delivery.retryCount),
              tenantId: tenantId,
              deliveryId: deliveryId,
              retryCount: delivery.retryCount,
            ),
          );
        } else {
          delivery.status = 'FAILED';
        }
      case 'UNDETERMINED':
        attempt.status = 'UNKNOWN';
        delivery.status = 'UNKNOWN';
        _openReconciliationCase(
          tenantId: tenantId,
          delivery: delivery,
          attempt: attempt,
          reasonCode: safeCode ?? 'DISPATCH_STATE_UNCERTAIN',
        );
      default:
        throw RpcException(
          'VALIDATION_ERROR: unknown outcome kind $outcomeKind',
        );
    }
    if (completed) {
      attempt.completedAt = fixedNow;
      delivery.completedAt = fixedNow;
    }
    attempt.version++;
    delivery.version++;
    _emitResultEvent(delivery);
    final projection = deliveryDisplayProjection(
      _statusesForInvoice(tenantId, delivery.electronicInvoiceId),
    );
    return [
      {
        'delivery_status': _publicStatus(delivery.status),
        'display_state': projection.displayState,
        'has_secondary_attention': projection.hasSecondaryAttention,
      },
    ];
  }

  void _openReconciliationCase({
    required String tenantId,
    required Slice5DeliveryRecord delivery,
    required Slice5AttemptRecord attempt,
    required String reasonCode,
  }) {
    final existing = state.reconciliationCases.values.where(
      (c) =>
          c.tenantId == tenantId &&
          c.attemptId == attempt.id &&
          c.status == 'PENDING',
    );
    if (existing.isNotEmpty) return;
    state.caseCounter++;
    final caseId = 'case-${state.caseCounter}';
    final caseRecord = Slice5ReconciliationCaseRecord(
      id: caseId,
      tenantId: tenantId,
      attemptId: attempt.id,
      deliveryId: delivery.id,
      providerConnectionId: attempt.providerConnectionId,
      reasonCode: reasonCode,
    );
    caseRecord.nextCheckAt = fixedNow.add(const Duration(seconds: 30));
    state.reconciliationCases[caseId] = caseRecord;
    internalClient.enqueue(
      ReconcileInvoiceDeliveryCommand(
        id: deliveryReconciliationCommandId(caseId, 1),
        tenantId: tenantId,
        reconciliationCaseId: caseId,
        checkSequence: 1,
      ),
    );
  }

  Future<void> recordCommandDeadLetterDirect({
    required String tenantId,
    required String deliveryId,
    required int retryCount,
    required String safeFailureCode,
  }) {
    return _recordCommandDeadLetter({
      'p_tenant_id': tenantId,
      'p_delivery_id': deliveryId,
      'p_retry_count': retryCount,
      'p_safe_failure_code': safeFailureCode,
    });
  }

  Future<dynamic> _recordCommandDeadLetter(Map<String, dynamic>? params) async {
    final tenantId = params!['p_tenant_id'] as String;
    final deliveryId = params['p_delivery_id'] as String;
    final retryCount = params['p_retry_count'] as int;
    final safeCode =
        (params['p_safe_failure_code'] as String?) ??
        'WORKER_EXHAUSTED_BEFORE_DISPATCH';
    final delivery = state.deliveries[deliveryId]!;
    final attempt = state.attempts.values
        .where((item) => item.deliveryId == deliveryId)
        .first;
    if (delivery.retryCount != retryCount ||
        delivery.status == 'SUCCEEDED' ||
        delivery.status == 'FAILED' ||
        delivery.status == 'UNKNOWN') {
      return null;
    }
    if (delivery.status == 'QUEUED') {
      attempt.status = 'FAILED';
      delivery.status = 'FAILED';
    } else if (delivery.status == 'SUBMITTED') {
      attempt.status = 'UNKNOWN';
      delivery.status = 'UNKNOWN';
      _openReconciliationCase(
        tenantId: tenantId,
        delivery: delivery,
        attempt: attempt,
        reasonCode: safeCode,
      );
    }
    attempt.version++;
    delivery.version++;
    _emitResultEvent(delivery);
    return null;
  }

  Future<dynamic> _getSendSheetContext(Map<String, dynamic>? params) async {
    final tenantId = params!['p_tenant_id'] as String;
    final actorId = params['p_actor_id'] as String;
    final salesOrderId = params['p_sales_order_id'] as String;
    if (!state.permittedActors.contains(actorId) ||
        !state.accessibleSalesOrders.contains(salesOrderId)) {
      throw RpcException('NOT_FOUND: sales order not found');
    }
    final invoice = state.invoicesBySalesOrder[salesOrderId];
    if (invoice == null)
      return throw RpcException('NOT_FOUND: electronic invoice not found');
    final deliveries = _deliveriesForInvoice(
      tenantId,
      invoice.electronicInvoiceId,
    );
    final hasInitial = deliveries.any(
      (d) => d.deliveryIntent == 'INITIAL_SEND',
    );
    final locked = deliveries.any(
      (d) => d.status == 'QUEUED' || d.status == 'SUBMITTED',
    );
    final projection = deliveryDisplayProjection(
      _statusesForInvoice(tenantId, invoice.electronicInvoiceId),
    );
    final history = deliveries
        .map(
          (d) => {
            'deliveryId': d.id,
            'deliveryNo': d.deliveryNo,
            'kind': d.deliveryIntent,
            'triggerType': d.triggerType,
            'recipientEmail': d.recipientSnapshot['toEmail'],
            'status': _publicStatus(d.status),
            'initiatedByActorType': d.initiatedByActorType,
            'initiatedByActorId': d.initiatedByActorId,
            'startedAt': (d.startedAt ?? fixedNow).toIso8601String(),
            'completedAt': d.completedAt?.toIso8601String(),
            'failureCode': null,
          },
        )
        .toList(growable: false);
    final suggested = _suggestedRecipient(
      tenantId: tenantId,
      invoice: invoice,
      mode: hasInitial ? 'resend' : 'send',
      deliveries: deliveries,
    );
    return [
      {
        'mode': hasInitial ? 'resend' : 'send',
        'suggested_email': suggested.$1,
        'suggested_email_source': suggested.$2,
        'history': history,
        'operation_locked': locked,
        'display_state': projection.displayState,
      },
    ];
  }

  (String?, String?) _suggestedRecipient({
    required String tenantId,
    required Slice5ElectronicInvoice invoice,
    required String mode,
    required List<Slice5DeliveryRecord> deliveries,
  }) {
    if (mode == 'send') {
      if (invoice.buyerPartnerId != null) {
        final partner = state.partners[invoice.buyerPartnerId!];
        if (partner != null &&
            partner.isActive &&
            partner.invoiceEmail != null &&
            partner.invoiceEmail!.contains('@')) {
          return (partner.invoiceEmail, 'CURRENT_PARTNER_PROFILE');
        }
        final lastPartnerSuccess = deliveries.reversed.where(
          (d) =>
              d.status == 'SUCCEEDED' &&
              d.recipientSnapshot['buyerPartnerId'] == invoice.buyerPartnerId,
        );
        if (lastPartnerSuccess.isNotEmpty) {
          return (
            lastPartnerSuccess.first.recipientSnapshot['toEmail'] as String?,
            'LAST_SUCCESSFUL_PARTNER_DELIVERY',
          );
        }
      }
      if (invoice.buyerSnapshotEmail != null) {
        return (invoice.buyerSnapshotEmail, 'BUYER_INVOICE_SNAPSHOT');
      }
      return (null, null);
    }
    final lastAny = deliveries.isNotEmpty ? deliveries.last : null;
    if (lastAny != null) {
      return (
        lastAny.recipientSnapshot['toEmail'] as String?,
        'LAST_INVOICE_DELIVERY',
      );
    }
    return (null, null);
  }

  Future<dynamic> _getHistory(Map<String, dynamic>? params) async {
    final tenantId = params!['p_tenant_id'] as String;
    final actorId = params['p_actor_id'] as String;
    final salesOrderId = params['p_sales_order_id'] as String;
    if (!state.permittedActors.contains(actorId) ||
        !state.accessibleSalesOrders.contains(salesOrderId)) {
      throw RpcException('NOT_FOUND: sales order not found');
    }
    final invoice = state.invoicesBySalesOrder[salesOrderId];
    if (invoice == null)
      return throw RpcException('NOT_FOUND: electronic invoice not found');
    final deliveries = _deliveriesForInvoice(
      tenantId,
      invoice.electronicInvoiceId,
    );
    final projection = deliveryDisplayProjection(
      _statusesForInvoice(tenantId, invoice.electronicInvoiceId),
    );
    final items = deliveries
        .map(
          (d) => {
            'deliveryId': d.id,
            'deliveryNo': d.deliveryNo,
            'kind': d.deliveryIntent,
            'triggerType': d.triggerType,
            'recipientEmail': d.recipientSnapshot['toEmail'],
            'status': _publicStatus(d.status),
            'initiatedByActorType': d.initiatedByActorType,
            'initiatedByActorId': d.initiatedByActorId,
            'startedAt': (d.startedAt ?? fixedNow).toIso8601String(),
            'completedAt': d.completedAt?.toIso8601String(),
            'failureCode': null,
          },
        )
        .toList(growable: false);
    return [
      {
        'deliveries': items,
        'display_state': projection.displayState,
        'has_secondary_attention': projection.hasSecondaryAttention,
      },
    ];
  }

  Future<dynamic> _loadReconciliationContext(
    Map<String, dynamic>? params,
  ) async {
    final tenantId = params!['p_tenant_id'] as String;
    final caseId = params['p_reconciliation_case_id'] as String;
    final checkSequence = params['p_check_sequence'] as int;
    final caseRecord = state.reconciliationCases[caseId];
    if (caseRecord == null ||
        caseRecord.tenantId != tenantId ||
        caseRecord.status != 'PENDING' ||
        caseRecord.attemptCount + 1 != checkSequence) {
      return <Map<String, dynamic>>[];
    }
    final connection = _connection(tenantId, caseRecord.providerConnectionId);
    return [
      {
        'tenant_id': tenantId,
        'reconciliation_case_id': caseId,
        'delivery_id': caseRecord.deliveryId,
        'attempt_id': caseRecord.attemptId,
        'provider_connection_id': caseRecord.providerConnectionId,
        'supports_delivery_result_observation':
            connection?.supportsDeliveryResultObservation ?? false,
        'check_sequence': checkSequence,
        'case_version': caseRecord.version,
        'provider_delivery_reference': null,
      },
    ];
  }

  Future<dynamic> _recordReconciliationCheck(
    Map<String, dynamic>? params,
  ) async {
    final tenantId = params!['p_tenant_id'] as String;
    final caseId = params['p_reconciliation_case_id'] as String;
    final checkSequence = params['p_check_sequence'] as int;
    final observationKind = (params['p_observation_kind'] as String)
        .toUpperCase();
    final safeCode = params['p_safe_code'] as String?;
    final providerReference = params['p_provider_reference'] as String?;
    final caseRecord = state.reconciliationCases[caseId]!;
    final delivery = state.deliveries[caseRecord.deliveryId]!;
    final attempt = state.attempts[caseRecord.attemptId]!;
    caseRecord.attemptCount = checkSequence;
    caseRecord.version++;

    if (observationKind == 'UNSUPPORTED') {
      caseRecord.status = 'UNRESOLVED';
      caseRecord.nextCheckAt = null;
      _emitAttention(
        delivery: delivery,
        caseRecord: caseRecord,
        safeErrorCode: safeCode ?? 'DELIVERY_RESULT_OBSERVATION_UNSUPPORTED',
      );
    } else if (observationKind == 'SUCCESS') {
      caseRecord.status = 'RESOLVED';
      caseRecord.nextCheckAt = null;
      attempt.status = 'SUCCEEDED';
      delivery.status = 'SUCCEEDED';
      delivery.providerDeliveryReference = providerReference;
      _emitResultEvent(delivery);
    } else if (observationKind == 'DEFINITE_FAILURE') {
      caseRecord.status = 'RESOLVED';
      attempt.status = 'FAILED';
      delivery.status = 'FAILED';
      _emitResultEvent(delivery);
    } else if (observationKind == 'UNDETERMINED') {
      if (checkSequence >= 5) {
        caseRecord.status = 'UNRESOLVED';
        caseRecord.nextCheckAt = null;
        _emitAttention(
          delivery: delivery,
          caseRecord: caseRecord,
          safeErrorCode: safeCode ?? 'PROVIDER_DELIVERY_PENDING',
        );
      } else {
        caseRecord.status = 'PENDING';
        caseRecord.nextCheckAt = fixedNow.add(const Duration(minutes: 2));
        internalClient.enqueue(
          ReconcileInvoiceDeliveryCommand(
            id: deliveryReconciliationCommandId(caseId, checkSequence + 1),
            tenantId: tenantId,
            reconciliationCaseId: caseId,
            checkSequence: checkSequence + 1,
          ),
        );
      }
    }

    final projection = deliveryDisplayProjection(
      _statusesForInvoice(tenantId, delivery.electronicInvoiceId),
    );
    return [
      {
        'case_status': caseRecord.status,
        'delivery_status': _publicStatus(delivery.status),
        'next_check_at': caseRecord.nextCheckAt?.toIso8601String(),
        'has_secondary_attention': projection.hasSecondaryAttention,
      },
    ];
  }
}

final class Slice5TestHarness {
  static final fixedNow = DateTime.utc(2026, 9, 3, 9);
  static const tenantId = 'tenant-s5-1';
  static const actorId = 'actor-s5-1';
  static const salesOrderId = 'order-s5-1';
  static const electronicInvoiceId = 'ei-s5-1';
  static const providerConnectionId = 'conn-s5-1';
  static const buyerPartnerId = 'partner-s5-1';

  late final GetIt container;
  late final Slice5State state;
  late final Slice5InternalCommandClient internalClient;
  late final Slice5DeliveryRpcEngine rpcEngine;
  late final FakeMeInvoiceClient fakeMeInvoiceClient;
  late final MeInvoiceDeliveryProviderAdapter deliveryAdapter;
  late final CapableDeliveryObservationProviderPort capableObservationPort;
  late final MeInvoiceDeliveryObservationProviderAdapter
  unsupportedObservationPort;
  late final CommandBus commandBus;
  late final SupabaseDeliveryReadGateway readGateway;
  late final Slice5InboxClient inboxClient;
  late final Slice5OutboxClient outboxClient;
  late final InMemoryEventBusClient eventBus;
  late final ProcessInternalCommandsCommandHandler processInternalHandler;
  late final ProcessInboxCommandHandler processInboxHandler;
  late final ProcessOutboxCommandHandler processOutboxHandler;
  late final EinvoiceIntegrationEventDispatcher integrationEventDispatcher;
  late final GetSendInvoiceSheetContextQueryHandler sheetHandler;
  late final GetInvoiceDeliveryHistoryQueryHandler historyHandler;

  void setUp({bool supportsDeliveryObservation = false}) {
    container = GetIt.asNewInstance();
    state = Slice5State();
    final serializer = createGeneratedEinvoiceInternalCommandSerializer();
    internalClient = Slice5InternalCommandClient(serializer: serializer);
    internalClient.bindCases(
      (tenantId) =>
          state.reconciliationCases.values.where((c) => c.tenantId == tenantId),
    );
    rpcEngine = Slice5DeliveryRpcEngine(
      state: state,
      internalClient: internalClient,
      fixedNow: fixedNow,
    );
    capableObservationPort = CapableDeliveryObservationProviderPort();
    unsupportedObservationPort =
        const MeInvoiceDeliveryObservationProviderAdapter();

    final fakeSupabase = FakeEinvoiceRpcSupabase();
    rpcEngine.registerAll(fakeSupabase);
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
    deliveryAdapter = MeInvoiceDeliveryProviderAdapter(
      rpcClient: rpcClient,
      clientFactory: clientFactory,
      defaultAppId: 'test-app',
      defaultBaseUrl: MeInvoiceConfig.testBaseUrl,
    );

    final commandGateway = SupabaseDeliveryCommandGateway(rpcClient: rpcClient);
    final reconciliationGateway = SupabaseDeliveryReconciliationGateway(
      rpcClient: rpcClient,
    );
    readGateway = SupabaseDeliveryReadGateway(rpcClient: rpcClient);

    final commandLogger = const NullLoggerFactory().named('einvoice.commands');
    commandBus = CommandBus(logger: commandLogger, container: container);
    container.registerSingleton<CommandBus>(commandBus);
    EinvoiceCommandsExecutor.bind(commandBus);

    final commandDispatcher = EinvoiceCommandDispatcher(commandBus: commandBus);
    inboxClient = Slice5InboxClient();
    outboxClient = Slice5OutboxClient(state);
    eventBus = InMemoryEventBusClient();
    integrationEventDispatcher = EinvoiceIntegrationEventDispatcher();

    registerGeneratedEinvoiceIntegrationEventSubscriptions(
      eventBus: eventBus,
      inboxClient: inboxClient,
      logger: const NullLoggerFactory().named('einvoice.events_bus'),
    );
    integrationEventDispatcher
        .register<ElectronicInvoiceRegisteredIntegrationEvent>(
          ElectronicInvoiceRegisteredIntegrationEventHandler(
            commands: commandDispatcher,
          ),
        );

    final startAutoHandler = StartAutoDeliveryCommandHandler(
      gateway: commandGateway,
    );
    final sendHandler = SendElectronicInvoiceCommandHandler(
      gateway: commandGateway,
    );
    final sendEmailHandler = SendInvoiceEmailCommandHandler(
      commandGateway: commandGateway,
      providerPort: deliveryAdapter,
      commandDispatcher: commandDispatcher,
    );
    final recordResultHandler = RecordDeliveryResultCommandHandler(
      gateway: commandGateway,
    );
    final reconcileHandler = ReconcileInvoiceDeliveryCommandHandler(
      reconciliationGateway: reconciliationGateway,
      observationPort: supportsDeliveryObservation
          ? capableObservationPort
          : unsupportedObservationPort,
    );
    sheetHandler = GetSendInvoiceSheetContextQueryHandler(gateway: readGateway);
    historyHandler = GetInvoiceDeliveryHistoryQueryHandler(
      gateway: readGateway,
    );

    commandBus
      ..register<StartAutoDeliveryCommand, AutoDeliveryResultDto>(
        startAutoHandler.handle,
      )
      ..register<SendElectronicInvoiceCommand, SendInvoiceResultDto>(
        sendHandler.handle,
      )
      ..register<SendInvoiceEmailCommand, void>(sendEmailHandler.handle)
      ..register<RecordDeliveryResultCommand, RecordDeliveryResultDto>(
        recordResultHandler.handle,
      )
      ..register<ReconcileInvoiceDeliveryCommand, void>(
        reconcileHandler.handle,
      );

    final deadLetterHandlers =
        <String, IEinvoiceInternalCommandDeadLetterHandler>{
          SendInvoiceEmailCommand.type: DeliveryCommandDeadLetterHandler(
            commandGateway: commandGateway,
          ),
          ReconcileInvoiceDeliveryCommand.type:
              DeliveryReconciliationCommandDeadLetterHandler(
                reconciliationGateway: reconciliationGateway,
              ),
        };

    processInternalHandler = ProcessInternalCommandsCommandHandler(
      commandClient: internalClient,
      serializer: serializer,
      deadLetterHandlers: deadLetterHandlers,
    );
    processInboxHandler = ProcessInboxCommandHandler(
      inboxClient: inboxClient,
      integrationEventDispatcher: integrationEventDispatcher,
    );
    processOutboxHandler = ProcessOutboxCommandHandler(
      outboxClient: outboxClient,
      eventTypeMapper: OutboxModule.createDefault().mapper,
      eventsBus: eventBus,
    );

    commandBus
      ..register<ProcessInternalCommandsCommand, bool>(
        processInternalHandler.handle,
      )
      ..register<ProcessInboxCommand, bool>(processInboxHandler.handle)
      ..register<ProcessOutboxCommand, bool>(processOutboxHandler.handle);

    seedDefaultInvoice(
      supportsDeliveryObservation: supportsDeliveryObservation,
    );
  }

  void seedDefaultInvoice({
    bool supportsDeliveryObservation = false,
    String? partnerEmail,
    String? buyerSnapshotEmail,
    bool partnerActive = true,
    bool autoSendEnabled = true,
    bool supportsEmailDelivery = true,
  }) {
    state.autoSendEnabled = autoSendEnabled;
    state.permittedActors.add(actorId);
    state.accessibleSalesOrders.add(salesOrderId);
    state.connections['$tenantId:$providerConnectionId'] =
        Slice5ProviderConnection(
          id: providerConnectionId,
          tenantId: tenantId,
          supportsEmailDelivery: supportsEmailDelivery,
          supportsDeliveryResultObservation: supportsDeliveryObservation,
        );
    state.partners[buyerPartnerId] = Slice5PartnerRecipient(
      partnerId: buyerPartnerId,
      invoiceEmail: partnerEmail ?? 'partner@buyer.test',
      recipientName: 'Partner Buyer',
      isActive: partnerActive,
    );
    final invoice = Slice5ElectronicInvoice(
      electronicInvoiceId: electronicInvoiceId,
      tenantId: tenantId,
      salesOrderId: salesOrderId,
      providerConnectionId: providerConnectionId,
      providerInvoiceReference: 'tx-s5-1',
      invoiceSeries: '1C26TYY',
      buyerPartnerId: buyerPartnerId,
      buyerSnapshotEmail: buyerSnapshotEmail ?? 'snapshot@buyer.test',
      buyerSnapshotName: 'Snapshot Buyer',
    );
    state.invoicesBySalesOrder[salesOrderId] = invoice;
    state.invoicesById[electronicInvoiceId] = invoice;
  }

  void replaceInvoice(Slice5ElectronicInvoice invoice) {
    state.invoicesBySalesOrder[invoice.salesOrderId] = invoice;
    state.invoicesById[invoice.electronicInvoiceId] = invoice;
  }

  Future<void> runWorker({int rounds = 1}) async {
    for (var i = 0; i < rounds; i++) {
      await commandBus.execute(
        ProcessInternalCommandsCommand(tenantId: tenantId, batchSize: 50),
      );
    }
  }

  Future<void> runOutbox() async {
    await commandBus.execute(
      ProcessOutboxCommand(tenantId: tenantId, batchSize: 50),
    );
  }

  Future<void> runInbox() async {
    await commandBus.execute(
      ProcessInboxCommand(tenantId: tenantId, batchSize: 50),
    );
  }

  Future<void> publishRegisteredEvent({String? eventId}) async {
    final id = eventId ?? 'evt-registered-1';
    state.outbox.add(
      Slice5OutboxMessage(
        messageId: id,
        eventType: ElectronicInvoiceRegisteredIntegrationEvent.type,
        payload: {
          'electronic_invoice_id': electronicInvoiceId,
          'sales_order_id': salesOrderId,
        },
        occurredAt: fixedNow,
      ),
    );
    await runOutbox();
    await runInbox();
  }

  Future<AutoDeliveryResultDto> startAutoDelivery({
    String? triggerId,
    String? idempotencyKey,
  }) {
    return commandBus.execute(
      StartAutoDeliveryCommand(
        tenantId: tenantId,
        electronicInvoiceId: electronicInvoiceId,
        triggerId: triggerId ?? 'tr-auto-1',
        idempotencyKey:
            idempotencyKey ??
            AutoDeliveryIdempotencyKey.generate(
              tenantId: tenantId,
              electronicInvoiceId: electronicInvoiceId,
            ),
      ),
    );
  }

  Future<SendInvoiceResultDto> sendElectronicInvoice({
    required String recipientEmail,
    required String idempotencyKey,
  }) {
    return commandBus.execute(
      SendElectronicInvoiceCommand(
        tenantId: tenantId,
        actorId: actorId,
        salesOrderId: salesOrderId,
        recipientEmail: recipientEmail,
        idempotencyKey: idempotencyKey,
      ),
    );
  }

  Future<SendInvoiceSheetContextDto> getSendSheet() {
    return sheetHandler.handle(
      GetSendInvoiceSheetContextQuery(
        tenantId: tenantId,
        actorId: actorId,
        salesOrderId: salesOrderId,
      ),
    );
  }

  Future<InvoiceDeliveryHistoryDto> getHistory() {
    return historyHandler.handle(
      GetInvoiceDeliveryHistoryQuery(
        tenantId: tenantId,
        actorId: actorId,
        salesOrderId: salesOrderId,
      ),
    );
  }

  Slice5DeliveryRecord? soleDelivery() {
    if (state.deliveries.length != 1) return null;
    return state.deliveries.values.single;
  }

  List<Slice5DeliveryRecord> deliveriesChronological() {
    final list = state.deliveries.values.toList(growable: false)
      ..sort((a, b) => a.deliveryNo.compareTo(b.deliveryNo));
    return list;
  }

  Future<void> recordCommandDeadLetter({
    required String deliveryId,
    required int retryCount,
    String safeFailureCode = 'WORKER_EXHAUSTED_BEFORE_DISPATCH',
  }) {
    return rpcEngine.recordCommandDeadLetterDirect(
      tenantId: tenantId,
      deliveryId: deliveryId,
      retryCount: retryCount,
      safeFailureCode: safeFailureCode,
    );
  }
}
