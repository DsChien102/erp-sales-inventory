import 'package:get_it/get_it.dart';
import 'package:test/test.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

void main() {
  group('ValidationCommandHandlerDecorator', () {
    test('runs validator before inner handler', () async {
      final order = <String>[];

      final decorator = ValidationCommandHandlerDecorator<_TestCommand, String>(
        validator: _RecordingValidator(order),
        inner: (command) async {
          order.add('inner:${command.id}');
          return 'ok';
        },
      );

      final result = await decorator.handle(_TestCommand('cmd-1'));

      expect(result, 'ok');
      expect(order, ['validate:cmd-1', 'inner:cmd-1']);
    });

    test('does not run inner when validation fails', () async {
      final decorator = ValidationCommandHandlerDecorator<_TestCommand, String>(
        validator: _FailingValidator(),
        inner: (_) async {
          throw StateError('inner should not run');
        },
      );

      await expectLater(
        decorator.handle(_TestCommand('cmd-1')),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('LoggingCommandHandlerDecorator', () {
    test('skips logging for recurring commands', () async {
      var innerRan = false;

      final decorator = LoggingCommandHandlerDecorator<_RecurringTestCommand, String>(
        inner: (_) async {
          innerRan = true;
          return 'ok';
        },
      );

      final result = await decorator.handle(_RecurringTestCommand('cmd-1'));

      expect(result, 'ok');
      expect(innerRan, isTrue);
    });

    test('runs inner and rethrows on failure', () async {
      final decorator = LoggingCommandHandlerDecorator<_TestCommand, String>(
        inner: (_) async {
          throw StateError('handler failed');
        },
      );

      await expectLater(
        decorator.handle(_TestCommand('cmd-1')),
        throwsStateError,
      );
    });
  });

  group('DefaultCommandPipeline', () {
    test('buildBusinessPipeline runs validation then handler', () async {
      final order = <String>[];
      final container = GetIt.asNewInstance()
        ..registerFactory<ICommandValidator<_TestCommand>>(
          () => _RecordingValidator(order),
        )
        ..registerFactory<_TestHandler>(() => _TestHandler(order));

      final pipeline = DefaultCommandPipeline.buildBusinessPipeline<
        _TestCommand,
        String,
        _TestHandler
      >(
        container: container,
        handler: container.get<_TestHandler>(),
        invoke: (command, handler) => handler.handle(command),
      );

      final result = await pipeline(_TestCommand('cmd-1'));

      expect(result, 'handled:cmd-1');
      expect(order, containsAll(['validate:cmd-1', 'handle:cmd-1']));
    });

    test('buildBusinessPipeline skips validation when validator not registered', () async {
      final order = <String>[];
      final container = GetIt.asNewInstance()
        ..registerFactory<_TestHandler>(() => _TestHandler(order));

      final pipeline = DefaultCommandPipeline.buildBusinessPipeline<
        _TestCommand,
        String,
        _TestHandler
      >(
        container: container,
        handler: container.get<_TestHandler>(),
        invoke: (command, handler) => handler.handle(command),
      );

      final result = await pipeline(_TestCommand('cmd-1'));

      expect(result, 'handled:cmd-1');
      expect(order, ['handle:cmd-1']);
    });
  });
}

final class _TestCommand extends CommandBase<String> {
  _TestCommand(super.id);
}

final class _RecurringTestCommand extends CommandBase<String> implements IRecurringCommand {
  _RecurringTestCommand(super.id);
}

final class _RecordingValidator implements ICommandValidator<_TestCommand> {
  _RecordingValidator(this.order);

  final List<String> order;

  @override
  Future<void> validate(_TestCommand command) async {
    order.add('validate:${command.id}');
  }
}

final class _FailingValidator implements ICommandValidator<_TestCommand> {
  @override
  Future<void> validate(_TestCommand command) async {
    throw ValidationException('invalid');
  }
}

final class _TestHandler {
  _TestHandler(this.order);

  final List<String> order;

  Future<String> handle(_TestCommand command) async {
    order.add('handle:${command.id}');
    return 'handled:${command.id}';
  }
}
