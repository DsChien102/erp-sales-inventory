import 'dart:async';

import 'package:erp/core/session/session_controller.dart';
import 'package:erp/core/session/session_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_shared_application/application.dart';

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

    revoked.add('TENANT_SUSPENDED');
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
    revoked.add('TENANT_CLOSED');
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(statuses, isEmpty);
    await sub.cancel();
    await cubit.close();
    await revoked.close();
  });

  test('suspended account signals sign-out instead of re-bootstrap', () async {
    final revoked = StreamController<String>.broadcast();
    final cubit = SessionController(
      repository: FakeSessionRepository(),
      initialState: const SessionState(
        status: TenantLoadStatus.ready,
        userDisplayName: '',
      ),
      tenantAccessRevoked: revoked.stream,
    );

    revoked.add(TenantAccessRevokedSignal.platformUserSuspended);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(cubit.state.identityRevoked, isTrue);
    // Không bootstrap lại: state giữ nguyên ready.
    expect(cubit.state.status, TenantLoadStatus.ready);

    await cubit.close();
    await revoked.close();
  });
}
