import 'package:uuid/uuid.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../inbox/i_iam_inbox_client.dart';
import '../internal_commands/i_iam_internal_command_client.dart';
import '../outbox/i_iam_outbox_client.dart';

/// In-memory outbox for unit tests (simulates rows written by mutation RPC).
final class InMemoryIamOutboxClient implements IIamOutboxClient {
  final List<StoredOutboxMessage> messages = <StoredOutboxMessage>[];
  final List<String> failedErrors = <String>[];

  /// Test helper: seed a row as if `enqueue_outbox_message` ran in an RPC.
  String seed({
    required String tenantId,
    required String eventType,
    required Map<String, dynamic> payload,
    String? messageId,
    DateTime? occurredAt,
  }) {
    final id = messageId ?? const Uuid().v4();
    messages.add(
      StoredOutboxMessage(
        id: id,
        tenantId: tenantId,
        eventType: eventType,
        payload: Map<String, dynamic>.from(payload),
        occurredAt: occurredAt ?? DateTime.now().toUtc(),
      ),
    );
    return id;
  }

  @override
  Future<List<ClaimedOutboxMessage>> claimBatch({
    required String tenantId,
    required int limit,
  }) async {
    final pending = messages
        .where(
          (m) =>
              m.tenantId == tenantId &&
              m.processedAt == null &&
              m.failedAt == null &&
              m.claimToken == null,
        )
        .take(limit)
        .toList(growable: false);

    final claimed = <ClaimedOutboxMessage>[];
    for (final message in pending) {
      final token = const Uuid().v4();
      message.claimToken = token;
      claimed.add(
        ClaimedOutboxMessage(
          messageId: message.id,
          eventType: message.eventType,
          payload: Map<String, dynamic>.from(message.payload),
          occurredAt: message.occurredAt,
          claimToken: token,
        ),
      );
    }
    return claimed;
  }

  @override
  Future<void> complete({
    required String tenantId,
    required String messageId,
    required String claimToken,
  }) async {
    final message = _findClaimed(
      tenantId: tenantId,
      messageId: messageId,
      claimToken: claimToken,
    );
    if (message == null) {
      return;
    }
    message.processedAt = DateTime.now().toUtc();
    message.claimToken = null;
  }

  @override
  Future<void> fail({
    required String tenantId,
    required String messageId,
    required String claimToken,
    required String error,
  }) async {
    failedErrors.add(error);
    final message = _findClaimed(
      tenantId: tenantId,
      messageId: messageId,
      claimToken: claimToken,
    );
    if (message == null) {
      return;
    }
    message.failedAt = DateTime.now().toUtc();
    message.error = error;
    message.claimToken = null;
  }

  StoredOutboxMessage? _findClaimed({
    required String tenantId,
    required String messageId,
    required String claimToken,
  }) {
    for (final message in messages) {
      if (message.id == messageId &&
          message.tenantId == tenantId &&
          message.claimToken == claimToken) {
        return message;
      }
    }
    return null;
  }
}

final class StoredOutboxMessage {
  StoredOutboxMessage({
    required this.id,
    required this.tenantId,
    required this.eventType,
    required this.payload,
    required this.occurredAt,
  });

  final String id;
  final String tenantId;
  final String eventType;
  final Map<String, dynamic> payload;
  final DateTime occurredAt;
  String? claimToken;
  DateTime? processedAt;
  DateTime? failedAt;
  String? error;
}

/// In-memory inbox for unit tests.
final class InMemoryIamInboxClient implements IIamInboxClient {
  final List<StoredInboxMessage> messages = <StoredInboxMessage>[];
  final List<String> failedErrors = <String>[];

  @override
  Future<String> receive({
    required String tenantId,
    required String messageId,
    required String eventType,
    required Map<String, dynamic> payload,
    required DateTime occurredAt,
  }) async {
    final exists = messages.any((m) => m.id == messageId);
    if (!exists) {
      messages.add(
        StoredInboxMessage(
          id: messageId,
          tenantId: tenantId,
          eventType: eventType,
          payload: Map<String, dynamic>.from(payload),
          occurredAt: occurredAt,
        ),
      );
    }
    return messageId;
  }

  @override
  Future<List<ClaimedInboxMessage>> claimBatch({
    required String tenantId,
    required int limit,
  }) async {
    final pending = messages
        .where(
          (m) =>
              m.tenantId == tenantId &&
              m.processedAt == null &&
              m.failedAt == null &&
              m.claimToken == null,
        )
        .take(limit)
        .toList(growable: false);

    final claimed = <ClaimedInboxMessage>[];
    for (final message in pending) {
      final token = const Uuid().v4();
      message.claimToken = token;
      claimed.add(
        ClaimedInboxMessage(
          messageId: message.id,
          eventType: message.eventType,
          payload: Map<String, dynamic>.from(message.payload),
          occurredAt: message.occurredAt,
          claimToken: token,
        ),
      );
    }
    return claimed;
  }

  @override
  Future<void> complete({
    required String tenantId,
    required String messageId,
    required String claimToken,
  }) async {
    final message = _findClaimed(
      tenantId: tenantId,
      messageId: messageId,
      claimToken: claimToken,
    );
    if (message == null) {
      return;
    }
    message.processedAt = DateTime.now().toUtc();
    message.claimToken = null;
  }

  @override
  Future<void> fail({
    required String tenantId,
    required String messageId,
    required String claimToken,
    required String error,
  }) async {
    failedErrors.add(error);
    final message = _findClaimed(
      tenantId: tenantId,
      messageId: messageId,
      claimToken: claimToken,
    );
    if (message == null) {
      return;
    }
    message.failedAt = DateTime.now().toUtc();
    message.error = error;
    message.claimToken = null;
  }

  StoredInboxMessage? _findClaimed({
    required String tenantId,
    required String messageId,
    required String claimToken,
  }) {
    for (final message in messages) {
      if (message.id == messageId &&
          message.tenantId == tenantId &&
          message.claimToken == claimToken) {
        return message;
      }
    }
    return null;
  }
}

final class StoredInboxMessage {
  StoredInboxMessage({
    required this.id,
    required this.tenantId,
    required this.eventType,
    required this.payload,
    required this.occurredAt,
  });

  final String id;
  final String tenantId;
  final String eventType;
  final Map<String, dynamic> payload;
  final DateTime occurredAt;
  String? claimToken;
  DateTime? processedAt;
  DateTime? failedAt;
  String? error;
}

/// In-memory internal commands + [ICommandScheduler] for unit tests.
final class InMemoryIamInternalCommands implements IIamInternalCommandClient, ICommandScheduler {
  final List<_StoredInternalCommand> _commands = <_StoredInternalCommand>[];
  final List<String> failedErrors = <String>[];
  final InternalCommandSerializer serializer;

  InMemoryIamInternalCommands({required this.serializer});

  @override
  Future<String> enqueue(
    ICommand<void> command, {
    String? sourceEventId,
  }) async {
    if (command is! ISerializableInternalCommand) {
      throw ArgumentError.value(
        command,
        'command',
        'must implement ISerializableInternalCommand',
      );
    }
    if (command is! CommandBase) {
      throw ArgumentError.value(
        command,
        'command',
        'must extend CommandBase',
      );
    }
    final serializable = command as ISerializableInternalCommand;
    final base = command;
    _commands.add(
      _StoredInternalCommand(
        id: base.id,
        tenantId: serializer.tenantIdOf(serializable),
        commandType: serializer.commandTypeOf(serializable),
        payload: serializer.toPayload(serializable),
        sourceEventId: sourceEventId,
        enqueuedAt: DateTime.now().toUtc(),
      ),
    );
    return base.id;
  }

  @override
  Future<List<ClaimedInternalCommand>> claimBatch({
    required String tenantId,
    required int limit,
  }) async {
    final pending = _commands
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
          sourceEventId: command.sourceEventId,
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
    if (command == null) {
      return;
    }
    command.processedAt = DateTime.now().toUtc();
    command.claimToken = null;
  }

  @override
  Future<void> fail({
    required String tenantId,
    required String commandId,
    required String claimToken,
    required String error,
  }) async {
    failedErrors.add(error);
    final command = _findClaimed(
      tenantId: tenantId,
      commandId: commandId,
      claimToken: claimToken,
    );
    if (command == null) {
      return;
    }
    command.failedAt = DateTime.now().toUtc();
    command.error = error;
    command.claimToken = null;
  }

  _StoredInternalCommand? _findClaimed({
    required String tenantId,
    required String commandId,
    required String claimToken,
  }) {
    for (final command in _commands) {
      if (command.id == commandId &&
          command.tenantId == tenantId &&
          command.claimToken == claimToken) {
        return command;
      }
    }
    return null;
  }
}

final class _StoredInternalCommand {
  _StoredInternalCommand({
    required this.id,
    required this.tenantId,
    required this.commandType,
    required this.payload,
    required this.enqueuedAt,
    this.sourceEventId,
  });

  final String id;
  final String tenantId;
  final String commandType;
  final Map<String, dynamic> payload;
  final DateTime enqueuedAt;
  final String? sourceEventId;
  String? claimToken;
  DateTime? processedAt;
  DateTime? failedAt;
  String? error;
}

final class InMemoryEmailDeliveryOutcomeStore implements IEmailDeliveryOutcomeStore {
  final Map<String, EmailDeliveryOutcomeDto> byCorrelation = <String, EmailDeliveryOutcomeDto>{};
  final Map<String, String> currentInvitationCorrelationById = <String, String>{};

  @override
  Future<String> record({
    required String correlationId,
    required EmailTemplateId templateId,
    required EmailDeliveryStatus status,
    String? tenantId,
    String? toEmailMasked,
    String? providerMessageId,
    String? error,
    String provider = EmailDeliveryConstants.providerResend,
    String? id,
  }) async {
    final resolvedId = id ?? byCorrelation[correlationId]?.id ?? const Uuid().v4();
    final dto = EmailDeliveryOutcomeDto(
      id: resolvedId,
      tenantId: tenantId,
      templateId: templateId,
      status: status,
      correlationId: correlationId,
      provider: provider,
      providerMessageId: providerMessageId,
      error: error,
      toEmailMasked: toEmailMasked,
    );
    byCorrelation[correlationId] = dto;
    return resolvedId;
  }

  @override
  Future<EmailDeliveryOutcomeDto?> getByCorrelationId(
    String correlationId,
  ) async {
    return byCorrelation[correlationId];
  }

  @override
  Future<bool> isCurrentTenantInvitationDelivery({
    required String invitationId,
    required String correlationId,
  }) async {
    final current = currentInvitationCorrelationById[invitationId];
    return current == null || current == correlationId;
  }
}
