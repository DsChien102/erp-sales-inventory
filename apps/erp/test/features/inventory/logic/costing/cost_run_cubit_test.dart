import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/inventory/data/core/inventory_error_codes.dart';
import 'package:erp/features/inventory/data/costing/costing_models.dart';
import 'package:erp/features/inventory/data/costing/costing_repository.dart';
import 'package:erp/features/inventory/data/stock/stock_models.dart';
import 'package:erp/features/inventory/logic/costing/cost_run_cubit.dart';
import 'package:erp/features/inventory/logic/costing/cost_run_state.dart';
import 'package:flutter_test/flutter_test.dart';

CostRunView _run({
  CostRunStatus status = CostRunStatus.readyForReview,
  List<CostBlocker> blockers = const [],
}) {
  return CostRunView(
    runId: 'run-1',
    code: 'GV-2611-01',
    kind: CostRunKind.midPeriod,
    periodMonth: DateTime(2026, 11, 1),
    status: status,
    method: CostMethod.periodic,
    fromSequence: 0,
    cutOffSequence: 10,
    cutOffAt: DateTime(2026, 11, 12, 10, 0),
    createdAt: DateTime(2026, 11, 12, 10, 0),
    blockers: blockers,
    productCount: blockers.isEmpty ? 1 : 0,
    changedCount: 0,
    totals: const CostTotals(
      closingValue: 880000,
      cogsValue: 770000,
      cogsAdjust: 20000,
      valueAdjust: -20000,
      balanceOk: true,
    ),
    alt: const CostAlt(
      method: CostMethod.moving,
      closingValue: 900000,
      cogsValue: 750000,
    ),
    lines: const [],
  );
}

class _FakeCostingRepository implements CostingRepository {
  CostRunView? createResult;
  final List<Object> publishQueue = [];
  final List<String> publishKeys = [];
  bool discardCalled = false;

  @override
  Future<CostRunView> createRun({
    required String idempotencyKey,
    required CostRunKind kind,
  }) async {
    return createResult!;
  }

  @override
  Future<CostRunView> publish({
    required String idempotencyKey,
    required String runId,
  }) async {
    publishKeys.add(idempotencyKey);
    final next = publishQueue.removeAt(0);
    if (next is CostRunView) return next;
    throw next;
  }

  @override
  Future<void> discard({
    required String idempotencyKey,
    required String runId,
  }) async {
    discardCalled = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeCostingRepository repo;

  setUp(() {
    repo = _FakeCostingRepository();
  });

  test('calculate_from_draft_emits_calculating_then_loaded', () async {
    repo.createResult = _run();
    final cubit = CostRunCubit(repo)
      ..startDraft(CostRunKind.midPeriod, DateTime(2026, 11, 1));
    final states = <CostRunState>[];
    final sub = cubit.stream.listen(states.add);

    await cubit.calculate();
    await pumpEventQueue();
    await sub.cancel();
    await cubit.close();

    expect(states.map((s) => s.phase).toList(), [
      CostRunPhase.calculating,
      CostRunPhase.loaded,
    ]);
    expect(states.last.run?.status, CostRunStatus.readyForReview);
  });

  test('calculate_blocked_keeps_blockers', () async {
    repo.createResult = _run(
      status: CostRunStatus.blocked,
      blockers: const [CostBlocker(code: 'STOCKTAKE_OPEN')],
    );
    final cubit = CostRunCubit(repo)
      ..startDraft(CostRunKind.midPeriod, DateTime(2026, 11, 1));
    final states = <CostRunState>[];
    final sub = cubit.stream.listen(states.add);

    await cubit.calculate();
    await pumpEventQueue();
    await sub.cancel();
    await cubit.close();

    expect(states.last.phase, CostRunPhase.loaded);
    expect(states.last.run?.status, CostRunStatus.blocked);
    expect(states.last.run?.blockers.first.code, 'STOCKTAKE_OPEN');
  });

  test('publish_success_emits_published', () async {
    repo.publishQueue.add(_run(status: CostRunStatus.published));
    final cubit = CostRunCubit(repo)
      ..emit(
        CostRunState(
          phase: CostRunPhase.loaded,
          kind: CostRunKind.midPeriod,
          period: DateTime(2026, 11, 1),
          run: _run(),
        ),
      );
    final states = <CostRunState>[];
    final sub = cubit.stream.listen(states.add);

    final ok = await cubit.publish();
    await pumpEventQueue();
    await sub.cancel();
    await cubit.close();

    expect(ok, isTrue);
    expect(states.map((s) => s.phase).toList(), [
      CostRunPhase.publishing,
      CostRunPhase.published,
    ]);
    expect(states.last.run?.status, CostRunStatus.published);
  });

  test('publish_stale_marks_stale', () async {
    repo.publishQueue.add(const AppException(InventoryErrorCode.costRunStale));
    final cubit = CostRunCubit(repo)
      ..emit(
        CostRunState(
          phase: CostRunPhase.loaded,
          kind: CostRunKind.midPeriod,
          period: DateTime(2026, 11, 1),
          run: _run(),
        ),
      );
    final states = <CostRunState>[];
    final sub = cubit.stream.listen(states.add);

    final ok = await cubit.publish();
    await pumpEventQueue();
    await sub.cancel();
    await cubit.close();

    expect(ok, isFalse);
    expect(states.last.phase, CostRunPhase.loaded);
    expect(states.last.run?.status, CostRunStatus.stale);
    expect(
      states.last.message,
      'Dữ liệu đầu vào đã thay đổi. Hãy tạo lần tính kế tiếp.',
    );
  });

  test('publish_network_error_retries_same_key', () async {
    repo.publishQueue.add(Exception('network timeout'));
    repo.publishQueue.add(_run(status: CostRunStatus.published));

    final cubit = CostRunCubit(repo)
      ..emit(
        CostRunState(
          phase: CostRunPhase.loaded,
          kind: CostRunKind.midPeriod,
          period: DateTime(2026, 11, 1),
          run: _run(),
        ),
      );

    await cubit.publish();
    expect(cubit.state.phase, CostRunPhase.loaded);
    expect(cubit.state.message, isNotNull);

    await cubit.publish();
    expect(cubit.state.phase, CostRunPhase.published);
    expect(repo.publishKeys, hasLength(2));
    expect(repo.publishKeys[0], repo.publishKeys[1]);
    await cubit.close();
  });

  test('discard_emits_discarded', () async {
    final cubit = CostRunCubit(repo)
      ..emit(
        CostRunState(
          phase: CostRunPhase.loaded,
          kind: CostRunKind.midPeriod,
          period: DateTime(2026, 11, 1),
          run: _run(),
        ),
      );
    final states = <CostRunState>[];
    final sub = cubit.stream.listen(states.add);

    await cubit.discard();
    await pumpEventQueue();
    await sub.cancel();
    await cubit.close();

    expect(repo.discardCalled, isTrue);
    expect(states.last.phase, CostRunPhase.discarded);
  });
}
