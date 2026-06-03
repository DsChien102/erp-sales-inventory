import 'messaging_process_result.dart';

/// Contract for a bounded context that participates in the messaging pipeline.
abstract interface class IMessagingModule {
  String get name;

  Future<MessagingProcessResult> processMessagingOnce({
    required String tenantId,
    int batchSize = 10,
  });
}
