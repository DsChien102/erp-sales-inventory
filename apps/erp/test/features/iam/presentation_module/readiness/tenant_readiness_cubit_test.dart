import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_iam_application/testing.dart';
import 'package:vet45_iam_domain/domain.dart';
import 'package:erp/features/iam/presentation.dart';
import 'package:erp/features/iam/testing.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

void main() {
  TenantReadinessCubit buildCubit({
    required IIamModule module,
    String tenantId = 'org-002',
    IdempotencyKeyFactory? keyFactory,
  }) {
    return TenantReadinessCubit(
      iamModule: module,
      executionContext: FakeExecutionContext(tenantId: tenantId),
      keyFactory: keyFactory ?? FakeIdempotencyKeyFactory(),
    );
  }

  test('readinessBlocked loads blockers and canActivate=false', () async {
    final cubit = buildCubit(
      module: FakeIamModule(scenario: FakeIamScenario.readinessBlocked),
      tenantId: 'org-001',
    );
    await cubit.load();
    expect(cubit.state.readiness!.blockers, isNotEmpty);
    expect(cubit.state.readiness!.canActivate, isFalse);
    expect(cubit.state.status, IamLoadStatus.success);
    await cubit.close();
  });

  test('readinessWarningOnly allows activate with warnings only', () async {
    final cubit = buildCubit(
      module: FakeIamModule(scenario: FakeIamScenario.readinessWarningOnly),
      tenantId: 'org-002',
    );
    await cubit.load();
    expect(cubit.state.readiness!.blockers, isEmpty);
    expect(cubit.state.readiness!.warnings, isNotEmpty);
    expect(cubit.state.readiness!.canActivate, isTrue);
    await cubit.close();
  });

  test('activateOk uses tenantVersion, stable key, refreshes context', () async {
    final keys = FakeIdempotencyKeyFactory();
    final module = RecordingIamModule(
      FakeIamModule(scenario: FakeIamScenario.activateOk),
    );
    final cubit = buildCubit(module: module, keyFactory: keys);
    await cubit.load();
    final version = cubit.state.readiness!.tenantVersion;

    final ok = await cubit.activate();
    expect(ok, isTrue);
    expect(cubit.state.activation?.status, TenantLifecycleStatus.active);
    expect(cubit.state.successMessage, isNotNull);

    final command = module.commandsOf<ActivateTenantCommand>().single;
    expect(command.expectedVersion, version);
    expect(command.idempotencyKey, 'activate-tenant-test-idempotency-key');
    expect(keys.calls, 1);

    final contextQueries = module.queriesOf<GetTenantContextQuery>().toList();
    expect(contextQueries, isNotEmpty);
    expect(contextQueries.last.bootstrapFromLastSelected, isFalse);

    // Second activate after success needs a new key (previous cleared).
    await cubit.load();
    // Already active → soft success without new command if status active.
    await cubit.close();
  });

  test('activateReadinessBlocked reloads readiness', () async {
    final module = RecordingIamModule(
      FakeIamModule(scenario: FakeIamScenario.activateReadinessBlocked),
    );
    final cubit = buildCubit(module: module);
    await cubit.load();
    final queriesBefore = module.queriesOf<GetTenantReadinessQuery>().length;

    final ok = await cubit.activate();
    expect(ok, isFalse);
    expect(cubit.state.failure?.code, IamBlockedCodes.readinessBlocked);
    expect(
      module.queriesOf<GetTenantReadinessQuery>().length,
      greaterThan(queriesBefore),
    );
    await cubit.close();
  });

  test('activateIdempotentRetry reuses the same key until success', () async {
    final keys = FakeIdempotencyKeyFactory();
    final module = RecordingIamModule(_FailThenSucceedActivateModule());
    final cubit = buildCubit(module: module, keyFactory: keys);
    await cubit.load();
    expect(await cubit.activate(), isFalse);
    expect(keys.calls, 1);
    expect(await cubit.activate(), isTrue);
    expect(keys.calls, 1);
    final cmds = module.commandsOf<ActivateTenantCommand>().toList();
    expect(cmds, hasLength(2));
    expect(cmds[0].idempotencyKey, cmds[1].idempotencyKey);
    await cubit.close();
  });

  test('activateIdempotencyConflict keeps failure and key', () async {
    final keys = FakeIdempotencyKeyFactory();
    final module = RecordingIamModule(
      FakeIamModule(scenario: FakeIamScenario.activateIdempotencyConflict),
    );
    final cubit = buildCubit(module: module, keyFactory: keys);
    await cubit.load();
    expect(await cubit.activate(), isFalse);
    expect(cubit.state.failure?.code, IamBlockedCodes.idempotencyConflict);
    expect(keys.calls, 1);
    expect(await cubit.activate(), isFalse);
    expect(keys.calls, 1);
    await cubit.close();
  });

  test('activateAlreadyActive soft-succeeds without command', () async {
    final module = RecordingIamModule(
      FakeIamModule(scenario: FakeIamScenario.activateAlreadyActive),
    );
    final cubit = buildCubit(module: module, tenantId: 'org-001');
    await cubit.load();
    expect(cubit.state.readiness!.status, TenantLifecycleStatus.active);
    expect(await cubit.activate(), isTrue);
    expect(cubit.state.successMessage, isNotNull);
    expect(module.commandsOf<ActivateTenantCommand>(), isEmpty);
    await cubit.close();
  });

  test('STATE_CHANGED reloads readiness and clears key', () async {
    final keys = FakeIdempotencyKeyFactory();
    final module = RecordingIamModule(_StateChangedActivateModule());
    final cubit = buildCubit(module: module, keyFactory: keys);
    await cubit.load();
    final before = module.queriesOf<GetTenantReadinessQuery>().length;
    expect(await cubit.activate(), isFalse);
    expect(cubit.state.failure?.code, IamBlockedCodes.stateChanged);
    expect(
      module.queriesOf<GetTenantReadinessQuery>().length,
      greaterThan(before),
    );
    // Key cleared → next activate allocates again.
    expect(await cubit.activate(), isFalse);
    expect(keys.calls, 2);
    await cubit.close();
  });

  test('CTA mapper routes by TenantReadinessIssueCodes', () {
    expect(
      TenantReadinessCtaMapper.routeFor(
        TenantReadinessIssueCodes.displayNameMissing,
      ),
      '/more/organization-profile/edit',
    );
    expect(
      TenantReadinessCtaMapper.routeFor(
        TenantReadinessIssueCodes.contactEmailMissingOrInvalid,
      ),
      '/more/organization-profile/edit',
    );
    expect(
      TenantReadinessCtaMapper.routeFor(
        TenantReadinessIssueCodes.legalProfileMissing,
      ),
      '/more/organization-profile/legal',
    );
    expect(
      TenantReadinessCtaMapper.routeFor(
        TenantReadinessIssueCodes.duplicateTaxCode,
      ),
      '/more/organization-profile/legal',
    );
    expect(
      TenantReadinessCtaMapper.routeFor(
        TenantReadinessIssueCodes.ownerEmailUnverified,
      ),
      isNull,
    );
    expect(
      TenantReadinessCtaMapper.routeFor(
        TenantReadinessIssueCodes.platformBlockerPresent,
      ),
      isNull,
    );
  });
}

final class _FailThenSucceedActivateModule implements IIamModule {
  bool _failedOnce = false;

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    if (command is ActivateTenantCommand) {
      final activate = command as ActivateTenantCommand;
      if (!_failedOnce) {
        _failedOnce = true;
        throw const IamBlockedException(IamBlockedCodes.idempotencyConflict);
      }
      return Future.value(
        TenantActivationResultDto(
              tenantId: activate.tenantId,
              status: TenantLifecycleStatus.active,
              activatedAt: DateTime.utc(2026, 7, 31),
              version: activate.expectedVersion + 1,
            )
            as TResult,
      );
    }
    throw UnsupportedError(command.runtimeType.toString());
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) {
    if (query is GetTenantReadinessQuery) {
      final readinessQuery = query as GetTenantReadinessQuery;
      return Future.value(
        TenantReadinessDto(
              tenantId: readinessQuery.tenantId,
              status: TenantLifecycleStatus.provisioning,
              blockers: const [],
              warnings: const [],
              evaluatedAt: DateTime.utc(2026, 7, 31),
              tenantVersion: 1,
              canActivate: true,
            )
            as TResult,
      );
    }
    if (query is GetTenantContextQuery) {
      return Future.value(
        const TenantContextDto(status: TenantContextStatus.valid) as TResult,
      );
    }
    throw UnsupportedError(query.runtimeType.toString());
  }
}

final class _StateChangedActivateModule implements IIamModule {
  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    throw const IamBlockedException(IamBlockedCodes.stateChanged);
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) {
    if (query is GetTenantReadinessQuery) {
      final readinessQuery = query as GetTenantReadinessQuery;
      return Future.value(
        TenantReadinessDto(
              tenantId: readinessQuery.tenantId,
              status: TenantLifecycleStatus.provisioning,
              blockers: const [],
              warnings: const [TenantReadinessIssueCodes.legalProfileMissing],
              evaluatedAt: DateTime.utc(2026, 7, 31),
              tenantVersion: 2,
              canActivate: true,
            )
            as TResult,
      );
    }
    throw UnsupportedError(query.runtimeType.toString());
  }
}
