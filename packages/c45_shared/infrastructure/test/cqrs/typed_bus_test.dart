import 'package:test/test.dart';
import 'package:c45_shared_infrastructure/infrastructure.dart';

void main() {
  group('TypedBus', () {
    test('dispatches registered handler by runtime type', () async {
      final bus = TypedBus<Object, String>();

      bus.register<_Ping, String>((message) async => 'pong:${message.value}');

      final result = await bus.execute(_Ping('x'));
      expect(result, 'pong:x');
    });

    test('throws when handler is missing', () async {
      final bus = TypedBus<Object, void>();

      await expectLater(
        () => bus.execute(_Ping('x')),
        throwsA(isA<StateError>()),
      );
    });
  });
}

final class _Ping {
  const _Ping(this.value);

  final String value;
}
