import 'package:erp/features/dashboard/logic/default_pair_gate_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../presentation/fake_default_pair_repository.dart';

void main() {
  group('DefaultPairGateCubit (Task 3)', () {
    test('d1_get_ok_ready_without_ensure', () async {
      final repo = FakeDefaultPairRepository(mode: FakeDefaultPairMode.ready);
      final cubit = DefaultPairGateCubit(repository: repo);
      addTearDown(cubit.close);

      final expectation = expectLater(
        cubit.stream.map((s) => s.status),
        emitsInOrder([
          DefaultPairGateStatus.loading,
          DefaultPairGateStatus.ready,
        ]),
      );

      await cubit.load();
      await expectation;

      expect(repo.ensureCalls, 0);
      expect(cubit.state.status, DefaultPairGateStatus.ready);
    });

    test('d2_missing_then_ensure_ready', () async {
      final repo = FakeDefaultPairRepository(
        mode: FakeDefaultPairMode.missingThenEnsure,
      );
      final cubit = DefaultPairGateCubit(repository: repo);
      addTearDown(cubit.close);

      final expectation = expectLater(
        cubit.stream.map((s) => s.status),
        emitsInOrder([
          DefaultPairGateStatus.loading,
          DefaultPairGateStatus.ready,
        ]),
      );

      await cubit.load();
      await expectation;

      expect(repo.ensureCalls, 1);
      expect(cubit.state.status, DefaultPairGateStatus.ready);
    });

    test('d3_get_other_error_no_ensure', () async {
      final repo = FakeDefaultPairRepository(
        mode: FakeDefaultPairMode.getError,
      );
      final cubit = DefaultPairGateCubit(repository: repo);
      addTearDown(cubit.close);

      final expectation = expectLater(
        cubit.stream.map((s) => s.status),
        emitsInOrder([
          DefaultPairGateStatus.loading,
          DefaultPairGateStatus.error,
        ]),
      );

      await cubit.load();
      await expectation;

      expect(repo.ensureCalls, 0);
      expect(cubit.state.status, DefaultPairGateStatus.error);
    });

    test('d3_ensure_error', () async {
      final repo = FakeDefaultPairRepository(
        mode: FakeDefaultPairMode.ensureError,
      );
      final cubit = DefaultPairGateCubit(repository: repo);
      addTearDown(cubit.close);

      final expectation = expectLater(
        cubit.stream.map((s) => s.status),
        emitsInOrder([
          DefaultPairGateStatus.loading,
          DefaultPairGateStatus.error,
        ]),
      );

      await cubit.load();
      await expectation;

      expect(repo.ensureCalls, 1);
      expect(cubit.state.status, DefaultPairGateStatus.error);
    });

    test('d3_non_app_error', () async {
      final repo = FakeDefaultPairRepository(
        mode: FakeDefaultPairMode.ready,
        pause: () async => throw StateError('x'),
      );
      final cubit = DefaultPairGateCubit(repository: repo);
      addTearDown(cubit.close);

      final expectation = expectLater(
        cubit.stream.map((s) => s.status),
        emitsInOrder([
          DefaultPairGateStatus.loading,
          DefaultPairGateStatus.error,
        ]),
      );

      await cubit.load();
      await expectation;

      expect(repo.ensureCalls, 0);
      expect(cubit.state.status, DefaultPairGateStatus.error);
    });
  });
}
