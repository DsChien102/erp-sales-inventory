import '../models.dart';

abstract final class EInvoiceDeliveryJson {
  static SendInvoiceResultDto sendInvoiceResultFromRow(
    Map<String, dynamic> row,
  ) {
    return SendInvoiceResultDto(
      deliveryId: _requiredString(row, 'delivery_id'),
      status: deliveryStatusFromRpc(_requiredString(row, 'status')),
    );
  }

  static SendInvoiceSheetContextDto sendSheetContextFromRow(
    Map<String, dynamic> row,
  ) {
    final sourceRaw = row['suggested_email_source']?.toString();
    return SendInvoiceSheetContextDto(
      mode: switch (_requiredString(row, 'mode')) {
        'send' => SendInvoiceSheetMode.send,
        'resend' => SendInvoiceSheetMode.resend,
        final other => throw FormatException('Unknown send sheet mode: $other'),
      },
      suggestedEmail: row['suggested_email']?.toString(),
      suggestedEmailSource: sourceRaw == null || sourceRaw.isEmpty
          ? null
          : recipientSourceFromRpc(sourceRaw),
      history: deliveryItemsFromRpc(row['history']),
      operationLocked: _requiredBool(row, 'operation_locked'),
      displayState: deliveryDisplayStateFromRpc(
        _requiredString(row, 'display_state'),
      ),
    );
  }

  static InvoiceDeliveryHistoryDto historyFromRow(Map<String, dynamic> row) {
    return InvoiceDeliveryHistoryDto(
      deliveries: deliveryItemsFromRpc(row['deliveries']),
      displayState: deliveryDisplayStateFromRpc(
        _requiredString(row, 'display_state'),
      ),
      hasSecondaryAttention: _requiredBool(row, 'has_secondary_attention'),
    );
  }

  static List<InvoiceDeliveryItemDto> deliveryItemsFromRpc(Object? raw) {
    if (raw == null) {
      return const [];
    }
    if (raw is! List) {
      throw const FormatException('Delivery history must be a JSON array');
    }
    return raw
        .map((item) {
          if (item is! Map) {
            throw const FormatException('Delivery history item must be an object');
          }
          final row = Map<String, dynamic>.from(item);
          return InvoiceDeliveryItemDto(
            deliveryId: _requiredString(row, 'deliveryId'),
            deliveryNo: _requiredInt(row, 'deliveryNo'),
            kind: deliveryKindFromRpc(_requiredString(row, 'kind')),
            triggerType: deliveryTriggerFromRpc(
              _requiredString(row, 'triggerType'),
            ),
            recipientEmail: _requiredString(row, 'recipientEmail'),
            status: deliveryStatusFromRpc(_requiredString(row, 'status')),
            initiatedByActorType: deliveryActorFromRpc(
              _requiredString(row, 'initiatedByActorType'),
            ),
            initiatedByActorId: row['initiatedByActorId']?.toString(),
            startedAt: _requiredDateTime(row, 'startedAt'),
            completedAt: _optionalDateTime(row, 'completedAt'),
            failureCode: row['failureCode']?.toString(),
          );
        })
        .toList(growable: false);
  }

  static DeliveryStatus deliveryStatusFromRpc(String raw) {
    return switch (raw.toUpperCase()) {
      'PROCESSING' => DeliveryStatus.processing,
      'SUCCEEDED' => DeliveryStatus.succeeded,
      'FAILED' => DeliveryStatus.failed,
      'UNKNOWN' => DeliveryStatus.unknown,
      _ => throw FormatException('Unknown delivery status: $raw'),
    };
  }

  static DeliveryDisplayState deliveryDisplayStateFromRpc(String raw) {
    return switch (raw) {
      'NOT_SENT' || 'notSent' => DeliveryDisplayState.notSent,
      'SENDING' || 'sending' => DeliveryDisplayState.sending,
      'SENT' || 'sent' => DeliveryDisplayState.sent,
      'FAILED' || 'failed' => DeliveryDisplayState.failed,
      'UNKNOWN' || 'unknown' => DeliveryDisplayState.unknown,
      _ => throw FormatException('Unknown delivery display state: $raw'),
    };
  }

  static DeliveryKind deliveryKindFromRpc(String raw) {
    return switch (raw.toUpperCase()) {
      'INITIAL_SEND' || 'INITIAL' => DeliveryKind.initial,
      'RESEND' => DeliveryKind.resend,
      _ => throw FormatException('Unknown delivery kind: $raw'),
    };
  }

  static DeliveryTriggerType deliveryTriggerFromRpc(String raw) {
    return switch (raw.toUpperCase()) {
      'AUTOMATIC' => DeliveryTriggerType.automatic,
      'MANUAL' => DeliveryTriggerType.manual,
      _ => throw FormatException('Unknown delivery trigger: $raw'),
    };
  }

  static DeliveryActorType deliveryActorFromRpc(String raw) {
    return switch (raw.toUpperCase()) {
      'SYSTEM' => DeliveryActorType.system,
      'USER' => DeliveryActorType.user,
      _ => throw FormatException('Unknown delivery actor type: $raw'),
    };
  }

  static DeliveryRecipientSource recipientSourceFromRpc(String raw) {
    return switch (raw.toUpperCase()) {
      'CURRENT_PARTNER_PROFILE' =>
        DeliveryRecipientSource.currentPartnerProfile,
      'BUYER_INVOICE_SNAPSHOT' => DeliveryRecipientSource.buyerInvoiceSnapshot,
      'LAST_SUCCESSFUL_PARTNER_DELIVERY' =>
        DeliveryRecipientSource.lastSuccessfulPartnerDelivery,
      'LAST_INVOICE_DELIVERY' => DeliveryRecipientSource.lastInvoiceDelivery,
      'USER_INPUT' => DeliveryRecipientSource.userInput,
      _ => throw FormatException('Unknown recipient source: $raw'),
    };
  }

  static String _requiredString(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value == null || value.toString().isEmpty) {
      throw FormatException('RPC row missing required field: $key');
    }
    return value.toString();
  }

  static int _requiredInt(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    throw FormatException('RPC row missing required int field: $key');
  }

  static bool _requiredBool(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value is bool) {
      return value;
    }
    throw FormatException('RPC row missing required bool field: $key');
  }

  static DateTime _requiredDateTime(Map<String, dynamic> row, String key) {
    final raw = _requiredString(row, key);
    try {
      return DateTime.parse(raw).toUtc();
    } on FormatException {
      throw FormatException('RPC row has malformed timestamp: $key');
    }
  }

  static DateTime? _optionalDateTime(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value == null || value.toString().isEmpty) {
      return null;
    }
    try {
      return DateTime.parse(value.toString()).toUtc();
    } on FormatException {
      throw FormatException('RPC row has malformed timestamp: $key');
    }
  }
}

