import 'dart:async';

import 'package:erp/features/tenant_context/presentation/bloc/tenant_context_cubit.dart';
import 'package:erp/features/tenant_context/presentation/bloc/tenant_context_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_iam_application/testing.dart';

void main() {
  test('ready cubit re-bootstraps when tenant access is revoked', () async {
    final revoked = StreamController<String>.broadcast();
    final cubit = TenantContextCubit(
      iamModule: FakeIamModule(),
      initialState: const TenantContextState(
        status: TenantContextLoadStatus.ready,
        userDisplayName: '',
      ),
      tenantAccessRevoked: revoked.stream,
    );
    expect(cubit.state.status, TenantContextLoadStatus.ready);

    final statuses = <TenantContextLoadStatus>[];
    final sub = cubit.stream.listen((s) => statuses.add(s.status));

    revoked.add('TENANT_SUSPENDED');
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(statuses, contains(TenantContextLoadStatus.loading));
    await sub.cancel();
    await cubit.close();
    await revoked.close();
  });

  test('blocked cubit ignores further revoked signals', () async {
    final revoked = StreamController<String>.broadcast();
    final cubit = TenantContextCubit(
      iamModule: FakeIamModule(scenario: FakeIamScenario.contextNone),
      tenantAccessRevoked: revoked.stream,
    );
    await cubit.bootstrap();
    expect(cubit.state.isBlocked, isTrue);

    final statuses = <TenantContextLoadStatus>[];
    final sub = cubit.stream.listen((s) => statuses.add(s.status));
    revoked.add('TENANT_CLOSED');
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(statuses, isEmpty);
    await sub.cancel();
    await cubit.close();
    await revoked.close();
  });
}
