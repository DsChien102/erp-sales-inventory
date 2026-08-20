import 'dart:convert';

import 'package:messaging_worker/worker_structured_log.dart';
import 'package:test/test.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

void main() {
  group('WorkerStructuredLog', () {
    test('encodes event name and fields as one JSON object', () {
      final logger = _RecordingLogger();
      final log = WorkerStructuredLog(logger);

      log.info('queue_skip', {'tenantId': 't1', 'module': 'partner'});

      expect(logger.infoMessages, hasLength(1));
      final decoded = jsonDecode(logger.infoMessages.single) as Map<String, dynamic>;
      expect(decoded['event'], 'queue_skip');
      expect(decoded['tenantId'], 't1');
      expect(decoded['module'], 'partner');
    });

    test('createWorkerTickId is stable-prefixed and unique per sequence', () {
      final a = createWorkerTickId(1);
      final b = createWorkerTickId(2);
      expect(a, startsWith('t'));
      expect(b, startsWith('t'));
      expect(a, isNot(b));
      expect(a, endsWith('-1'));
      expect(b, endsWith('-2'));
    });
  });
}

final class _RecordingLogger implements ILogger {
  final List<String> infoMessages = <String>[];

  @override
  void fine(Object? message, [Object? error, StackTrace? stackTrace]) {}

  @override
  void info(Object? message, [Object? error, StackTrace? stackTrace]) {
    infoMessages.add(message! as String);
  }

  @override
  void warning(Object? message, [Object? error, StackTrace? stackTrace]) {}

  @override
  void severe(Object? message, [Object? error, StackTrace? stackTrace]) {}
}
