import 'package:test/test.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

void main() {
  group('Entity', () {
    test('collects and clears domain events', () {
      final entity = _TestEntity('e-1');
      entity.raise();

      expect(entity.domainEvents, hasLength(1));
      entity.clearDomainEvent();
      expect(entity.domainEvents, isEmpty);
    });

    test('checkRule throws BusinessRuleValidationException', () {
      final entity = _TestEntity('e-1');
      expect(
        () => entity.breakRule(),
        throwsA(isA<BusinessRuleValidationException>()),
      );
    });
  });

  group('TypedId', () {
    test('compares by value', () {
      const a = TypedId<_Marker>('id-1');
      const b = TypedId<_Marker>('id-1');
      const c = TypedId<_Marker>('id-2');

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('IClock', () {
    test('SystemClock returns current time', () {
      const clock = SystemClock();
      final before = DateTime.now();
      final now = clock.now();
      final after = DateTime.now();

      expect(now.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
      expect(now.isBefore(after.add(const Duration(seconds: 1))), isTrue);
    });
  });

  group('DomainException', () {
    test('exposes message', () {
      final error = DomainException('failed');
      expect(error.toString(), 'failed');
    });
  });
}

final class _Marker {}

final class _BrokenRule implements IBusinessRule {
  @override
  bool isBroken() => true;

  @override
  String get message => 'broken';
}

final class _TestEvent extends DomainEventBase {
  _TestEvent();
}

final class _TestEntity extends Entity<String> {
  _TestEntity(String id) : super(id: id);

  void raise() {
    addDomainEvent(_TestEvent());
  }

  void breakRule() {
    checkRule(_BrokenRule());
  }
}
