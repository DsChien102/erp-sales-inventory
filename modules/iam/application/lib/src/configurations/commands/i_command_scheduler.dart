import 'package:vet45_shared_application/application.dart';

/// Enqueues durable internal commands for async worker execution.
abstract interface class ICommandScheduler {
  Future<String> enqueue(
    ICommand<void> command, {
    String? sourceEventId,
  });
}
