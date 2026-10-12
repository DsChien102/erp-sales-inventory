import 'dart:async';

import 'package:erp/core/session/session_controller.dart';
import 'package:erp/core/session/session_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_session_repository.dart';

void main() {
  test('ready cubit re-bootstraps when tenant access is revoked', () async {
    final revoked = StreamController<String>.broadcast();
    final cubit = SessionController(
      repository: FakeSessionRepository(),
      initialState: const SessionState(
        status: TenantLoadStatus.ready,
        userDisplayName: '',
      ),
      tenantAccessRevoked: revoked.stream,
    );
    expect(cubit.state.status, TenantLoadStatus.ready);

    final statuses = <TenantLoadStatus>[];
    final sub = cubit.stream.listen((s) => statuses.add(s.status));

    revoked.add('MEMBERSHIP_REMOVED');
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(statuses, contains(TenantLoadStatus.loading));
    await sub.cancel();
    await cubit.close();
    await revoked.close();
  });

  test('blocked cubit ignores further revoked signals', () async {
    final revoked = StreamController<String>.broadcast();
    final cubit = SessionController(
      repository: FakeSessionRepository(noTenants: true),
      tenantAccessRevoked: revoked.stream,
    );
    await cubit.bootstrap();
    expect(cubit.state.isBlocked, isTrue);

    final statuses = <TenantLoadStatus>[];
    final sub = cubit.stream.listen((s) => statuses.add(s.status));
    revoked.add('MEMBERSHIP_REMOVED');
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(statuses, isEmpty);
    await sub.cancel();
    await cubit.close();
    await revoked.close();
  });
}
