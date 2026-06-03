import 'package:vet45_annotations/vet45_annotations.dart';

import 'create_task_command.dart';
import 'cqrs.dart';

@CommandHandlerFor(CreateTaskCommand)
final class CreateTaskCommandHandler implements ICommandHandler<CreateTaskCommand, String> {
  CreateTaskCommandHandler();

  @override
  Future<String> handle(CreateTaskCommand command) async => 'task-id';
}
