import 'package:vet45_shared_application/application.dart';

abstract interface class ICommandScheduler {
  Future<String> enqueue(
    ICommand<void> command, {
    String? sourceEventId,
  });
}
