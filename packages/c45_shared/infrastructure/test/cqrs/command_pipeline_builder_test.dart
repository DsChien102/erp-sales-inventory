import 'package:test/test.dart';
import 'package:c45_shared_infrastructure/infrastructure.dart';

void main() {
  group('CommandPipelineBuilder', () {
    test('runs middleware in outer-to-inner order', () async {
      final order = <String>[];

      final pipeline =
          CommandPipelineBuilder<String, String>((command) async {
            order.add('inner:$command');
            return command;
          }).wrap((command, next) async {
            order.add('outer-before');
            final result = await next(command);
            order.add('outer-after');
            return result;
          }).build();

      final result = await pipeline('cmd');

      expect(result, 'cmd');
      expect(order, ['outer-before', 'inner:cmd', 'outer-after']);
    });

    test('outer middleware can short-circuit before inner runs', () async {
      var innerRan = false;

      final pipeline =
          CommandPipelineBuilder<String, String>((_) async {
            innerRan = true;
            return 'inner';
          }).wrap((command, next) async {
            if (command.isEmpty) {
              throw StateError('validation failed');
            }
            return next(command);
          }).build();

      await expectLater(pipeline(''), throwsStateError);
      expect(innerRan, isFalse);
    });
  });
}
