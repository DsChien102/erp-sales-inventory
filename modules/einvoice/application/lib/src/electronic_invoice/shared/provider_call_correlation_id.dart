import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Deterministic provider-call correlation for one worker attempt.
abstract final class ProviderCallCorrelationId {
  static String forWorkerAttempt({
    required String commandId,
    required int workerAttemptNumber,
  }) {
    final raw = '$commandId|provider-call|$workerAttemptNumber';
    final hex = sha256.convert(utf8.encode(raw)).toString();
    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20, 32)}';
  }
}
