import 'package:test/test.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

void main() {
  group('CommandBus', () {
    test('executes business command without bus-level logging hook', () async {
      final bus = CommandBus();
      bus.register<_EchoCommand, String>((command) async => command.text);

      final result = await bus.execute(_EchoCommand('hello'));
      expect(result, 'hello');
    });

    test('logs recurring commands through bus execution logger', () async {
      final bus = CommandBus();
      bus.register<_RecurringCommand, void>((_) async {});

      await expectLater(bus.execute(_RecurringCommand()), completes);
    });

    test('throws when handler is missing', () async {
      final bus = CommandBus();

      await expectLater(
        () => bus.execute(_EchoCommand('x')),
        throwsA(isA<StateError>()),
      );
    });
  });
}

final class _EchoCommand implements ICommand<String> {
  _EchoCommand(this.text);

  final String text;

  @override
  String get id => 'echo-1';
}

final class _RecurringCommand extends CommandBase<void> implements IRecurringCommand {
  _RecurringCommand() : super('recurring-1');
}
