import 'package:get_it/get_it.dart';
import 'package:test/test.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

void main() {
  group('RecordingQueryBus', () {
    test('records last executed query', () async {
      final bus = RecordingQueryBus()
        ..register<GetTaskByIdQuery, TaskDto>(_GetTaskHandler());

      await bus.execute(GetTaskByIdQuery('task-1'));

      expect(bus.lastQuery, isA<GetTaskByIdQuery>());
      expect((bus.lastQuery! as GetTaskByIdQuery).taskId, 'task-1');
    });
  });

  group('PipelineTestHarness', () {
    test('runs validation behavior before handler', () async {
      final order = <String>[];
      final pipeline = PipelineTestHarness<CreateTaskCommand, void>(
        handler: (_) async {
          order.add('handler');
        },
        behaviors: [
          _RecordingValidationBehavior(order),
        ],
      ).build();

      await pipeline(CreateTaskCommand(title: 'x', assigneeId: 'u-1'));

      expect(order, ['validate', 'handler']);
    });
  });

  group('Task CQRS example', () {
    test('executes create command through decorated bus', () async {
      final container = GetIt.asNewInstance()
        ..registerFactory<ICommandValidator<CreateTaskCommand>>(
          () => _CreateTaskValidator(),
        );

      final bus = InMemoryCommandBus();
      final pipeline = DefaultCommandPipeline.buildBusinessPipeline<
        CreateTaskCommand,
        void,
        _CreateTaskHandler
      >(
        container: container,
        handler: _CreateTaskHandler(),
        invoke: (command, handler) => handler.handle(command),
      );
      bus.register<CreateTaskCommand, void>(pipeline);

      await bus.execute(
        CreateTaskCommand(title: 'Write toolkit plan', assigneeId: 'user-1'),
      );
    });

    test('query bus returns task dto', () async {
      final bus = RecordingQueryBus()
        ..register<GetTaskByIdQuery, TaskDto>(_GetTaskHandler());

      final dto = await bus.execute(GetTaskByIdQuery('task-42'));

      expect(dto.id, 'task-42');
      expect(dto.title, 'Task task-42');
    });
  });

  group('Access fakes', () {
    test('FakePermissionChecker records required permissions', () async {
      final checker = FakePermissionChecker();
      await checker.require('tasks.write');
      expect(checker.required, ['tasks.write']);
    });

    test('FakeTenantAccessChecker records tenant checks', () async {
      final checker = FakeTenantAccessChecker();
      await checker.ensureAccess('tenant-1');
      expect(checker.checked, ['tenant-1']);
    });
  });
}

final class CreateTaskCommand extends CommandBase<void> {
  CreateTaskCommand({required this.title, required this.assigneeId});

  final String title;
  final String assigneeId;
}

final class GetTaskByIdQuery extends QueryBase<TaskDto> {
  GetTaskByIdQuery(this.taskId);

  final String taskId;
}

final class TaskDto {
  const TaskDto({required this.id, required this.title});

  final String id;
  final String title;
}

final class _CreateTaskHandler implements ICommandHandler<CreateTaskCommand, void> {
  @override
  Future<void> handle(CreateTaskCommand command) async {}
}

final class _GetTaskHandler implements IQueryHandler<GetTaskByIdQuery, TaskDto> {
  @override
  Future<TaskDto> handle(GetTaskByIdQuery query) async {
    return TaskDto(id: query.taskId, title: 'Task ${query.taskId}');
  }
}

final class _CreateTaskValidator implements ICommandValidator<CreateTaskCommand> {
  @override
  Future<void> validate(CreateTaskCommand command) async {
    if (command.title.trim().isEmpty) {
      throw ValidationException('title is required');
    }
  }
}

final class _RecordingValidationBehavior
    implements ICommandPipelineBehavior<CreateTaskCommand, void> {
  _RecordingValidationBehavior(this.order);

  final List<String> order;

  @override
  Future<void> handle(
    CreateTaskCommand command,
    Future<void> Function(CreateTaskCommand command) next,
  ) async {
    order.add('validate');
    return next(command);
  }
}
