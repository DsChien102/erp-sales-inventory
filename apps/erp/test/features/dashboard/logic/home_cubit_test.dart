import 'dart:async';

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/dashboard/data/home_repository.dart';
import 'package:erp/features/dashboard/data/models/home_summary.dart';
import 'package:erp/features/dashboard/logic/home_cubit.dart';
import 'package:erp/features/dashboard/logic/home_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_home_repository.dart';

/// Mỗi lần fetch trả completer kế tiếp trong hàng (kiểm thứ tự về của kết quả).
class _QueuedRepository implements HomeRepository {
  final queue = <Completer<HomeSummary>>[];

  @override
  Future<HomeSummary> fetch() {
    final c = Completer<HomeSummary>();
    queue.add(c);
    return c.future;
  }
}

void main() {
  test('load success', () async {
    final cubit = HomeCubit(repository: FakeHomeRepository());
    expect(cubit.state.status, HomeStatus.loading);
    await cubit.load();
    expect(cubit.state.status, HomeStatus.ready);
    expect(cubit.state.summary?.revenueToday, 8420000);
    await cubit.close();
  });

  test('load error', () async {
    final cubit = HomeCubit(
      repository: FakeHomeRepository(error: const AppException('NETWORK_ERROR')),
    );
    await cubit.load();
    expect(cubit.state.status, HomeStatus.error);
    expect(cubit.state.summary, isNull);
    expect(cubit.state.error?.code, 'NETWORK_ERROR');
    await cubit.close();
  });

  test('error retry goes back to loading then ready', () async {
    final repo = FakeHomeRepository(error: const AppException('NETWORK_ERROR'));
    final cubit = HomeCubit(repository: repo);
    await cubit.load();
    repo.error = null;
    final states = <HomeStatus>[];
    final sub = cubit.stream.listen((s) => states.add(s.status));
    await cubit.load();
    await Future<void>.delayed(Duration.zero);
    expect(states, [HomeStatus.loading, HomeStatus.ready]);
    await sub.cancel();
    await cubit.close();
  });

  test('refresh error keeps summary', () async {
    final repo = FakeHomeRepository();
    final cubit = HomeCubit(repository: repo);
    await cubit.load();
    repo.error = const AppException('NETWORK_ERROR');
    await cubit.load();
    expect(cubit.state.status, HomeStatus.ready);
    expect(cubit.state.summary?.revenueToday, 8420000);
    expect(cubit.state.refreshError?.code, 'NETWORK_ERROR');
    await cubit.close();
  });

  test('stale response from previous tenant is ignored', () async {
    final repo = _QueuedRepository();
    final cubit = HomeCubit(repository: repo);
    final first = cubit.load();
    final second = cubit.load();
    repo.queue[1].complete(sampleHomeSummary(revenueToday: 222));
    await second;
    repo.queue[0].complete(sampleHomeSummary(revenueToday: 111));
    await first;
    expect(cubit.state.summary?.revenueToday, 222);
    await cubit.close();
  });

  test('stale error from previous load is ignored', () async {
    final repo = _QueuedRepository();
    final cubit = HomeCubit(repository: repo);
    final first = cubit.load();
    final second = cubit.load();
    repo.queue[1].complete(sampleHomeSummary(revenueToday: 222));
    await second;
    repo.queue[0].completeError(const AppException('NETWORK_ERROR'));
    await first;
    expect(cubit.state.status, HomeStatus.ready);
    expect(cubit.state.refreshError, isNull);
    await cubit.close();
  });

  test('load(reset: true) drops old tenant numbers and shows loading', () async {
    final repo = FakeHomeRepository();
    final cubit = HomeCubit(repository: repo);
    await cubit.load();
    repo.gate = Completer<HomeSummary>();
    final pending = cubit.load(reset: true);
    expect(cubit.state.status, HomeStatus.loading);
    expect(cubit.state.summary, isNull);
    repo.gate!.complete(sampleHomeSummary(revenueToday: 5));
    await pending;
    expect(cubit.state.summary?.revenueToday, 5);
    await cubit.close();
  });
}
