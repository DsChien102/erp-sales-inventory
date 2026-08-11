import 'package:admin/features/users/presentation/bloc/platform_user_detail_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_iam_application/testing.dart';
import 'package:vet45_iam_presentation/presentation.dart';
import 'package:vet45_iam_presentation/testing.dart';
import 'package:vet45_shared_application/application.dart';

void main() {
  PlatformUserDetailCubit build({
    required IIamModule module,
    String userId = 'lan-le',
    IdempotencyKeyFactory? keyFactory,
  }) {
    return PlatformUserDetailCubit(
      iamModule: module,
      userId: userId,
      keyFactory: keyFactory,
    );
  }

  test('load maps RESOURCE_NOT_FOUND to empty without string contains', () async {
    final cubit = build(module: FakeIamModule(), userId: 'missing-user');
    await cubit.load();
    expect(cubit.state.status, IamLoadStatus.empty);
    expect(cubit.state.failure?.code, IamBlockedCodes.resourceNotFound);
    expect(cubit.state.user, isNull);
    await cubit.close();
  });

  test('load maps PLATFORM_PERMISSION_DENIED to unauthorized', () async {
    final cubit = build(
      module: FakeIamModule(scenario: FakeIamScenario.userForbidden403),
    );
    await cubit.load();
    expect(cubit.state.status, IamLoadStatus.unauthorized);
    expect(
      cubit.state.failure?.code,
      IamBlockedCodes.platformPermissionDenied,
    );
    await cubit.close();
  });

  test('requestPasswordReset sends command', () async {
    final module = RecordingIamModule(
      FakeIamModule(scenario: FakeIamScenario.userDetailOk),
    );
    final cubit = build(module: module);
    await cubit.load();
    final ok = await cubit.requestPasswordReset();
    expect(ok, isTrue);
    expect(
      module.commandsOf<RequestPlatformPasswordResetCommand>(),
      hasLength(1),
    );
    await cubit.close();
  });

  test('suspend requires reason and sends command', () async {
    final module = RecordingIamModule(
      FakeIamModule(scenario: FakeIamScenario.suspendOk),
    );
    final cubit = build(module: module);
    await cubit.load();
    expect(await cubit.suspend(reason: '  '), isFalse);
    expect(module.commandsOf<SuspendPlatformUserCommand>(), isEmpty);

    expect(
      await cubit.suspend(reason: 'Vi phạm chính sách truy cập'),
      isTrue,
    );
    final suspend = module.commandsOf<SuspendPlatformUserCommand>().single;
    expect(suspend.reason, 'Vi phạm chính sách truy cập');
    await cubit.close();
  });

  test('sendActivationInvitation for pending user', () async {
    final module = RecordingIamModule(
      FakeIamModule(scenario: FakeIamScenario.activationResendOk),
    );
    final cubit = build(module: module, userId: 'hoa-tran');
    await cubit.load();
    expect(cubit.state.user?.status, PlatformUserStatus.pendingActivation);
    expect(await cubit.sendActivationInvitation(), isTrue);
    expect(
      module.commandsOf<SendActivationInvitationCommand>(),
      hasLength(1),
    );
    await cubit.close();
  });

  test('restore for suspended user', () async {
    final module = RecordingIamModule(
      FakeIamModule(scenario: FakeIamScenario.restoreOk),
    );
    final cubit = build(module: module, userId: 'minh-nguyen');
    await cubit.load();
    expect(await cubit.restore(), isTrue);
    expect(module.commandsOf<RestorePlatformUserCommand>(), hasLength(1));
    await cubit.close();
  });

  test('wrong-status action does not call command', () async {
    final module = RecordingIamModule(
      FakeIamModule(scenario: FakeIamScenario.userDetailOk),
    );
    final cubit = build(module: module); // active
    await cubit.load();
    expect(await cubit.sendActivationInvitation(), isFalse);
    expect(module.commandsOf<SendActivationInvitationCommand>(), isEmpty);
    expect(await cubit.restore(), isFalse);
    expect(module.commandsOf<RestorePlatformUserCommand>(), isEmpty);
    await cubit.close();
  });

  test('step-up maps typed failure without popping success', () async {
    final cubit = build(
      module: FakeIamModule(scenario: FakeIamScenario.stepUpRequired),
      userId: 'lan-le',
    );
    await cubit.load();
    expect(await cubit.suspend(reason: 'policy'), isFalse);
    expect(cubit.state.failure?.code, IamBlockedCodes.stepUpAuthRequired);
    await cubit.close();
  });

  test('idempotency reuses key until success or STATE_CHANGED', () async {
    final keys = FakeIdempotencyKeyFactory();
    final module = RecordingIamModule(_FailThenSucceedSuspendModule());
    final cubit = build(module: module, keyFactory: keys);
    await cubit.load();
    expect(await cubit.suspend(reason: 'retry'), isFalse);
    expect(keys.calls, 1);
    expect(await cubit.suspend(reason: 'retry'), isTrue);
    expect(keys.calls, 1);
    final cmds = module.commandsOf<SuspendPlatformUserCommand>().toList();
    expect(cmds[0].idempotencyKey, cmds[1].idempotencyKey);
    await cubit.close();
  });

  test('action visibility respects status + permission', () async {
    final cubit = build(
      module: FakeIamModule(scenario: FakeIamScenario.userDetailOk),
    );
    await cubit.load();
    expect(cubit.state.showPasswordReset, isTrue);
    expect(cubit.state.showSuspend, isTrue);
    expect(cubit.state.showActivationInvite, isFalse);
    expect(cubit.state.showRestore, isFalse);
    await cubit.close();
  });
}

final class _FailThenSucceedSuspendModule implements IIamModule {
  bool _failedOnce = false;
  final FakeIamModule _delegate = FakeIamModule(
    scenario: FakeIamScenario.suspendOk,
  );

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    if (command is SuspendPlatformUserCommand) {
      if (!_failedOnce) {
        _failedOnce = true;
        throw const IamBlockedException(IamBlockedCodes.idempotencyConflict);
      }
    }
    return _delegate.executeCommandAsync(command);
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) {
    return _delegate.executeQueryAsync(query);
  }
}
