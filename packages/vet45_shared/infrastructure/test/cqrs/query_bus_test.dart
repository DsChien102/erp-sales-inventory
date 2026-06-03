import 'package:test/test.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

void main() {
  group('QueryBus', () {
    test('executes registered query handler', () async {
      final bus = QueryBus();
      bus.register<_CountQuery, int>((query) async => query.value);

      final result = await bus.execute(_CountQuery(3));
      expect(result, 3);
    });

    test('throws when handler is missing', () async {
      final bus = QueryBus();

      await expectLater(
        () => bus.execute(_CountQuery(1)),
        throwsA(isA<StateError>()),
      );
    });
  });
}

final class _CountQuery extends QueryBase<int> {
  _CountQuery(this.value) : super('query-1');

  final int value;
}
