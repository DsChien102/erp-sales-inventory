import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_application/testing.dart';
import 'package:erp/features/partner/presentation.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

void main() {
  late FakeExecutionContext executionContext;

  setUp(() {
    executionContext = FakeExecutionContext(
      tenantId: 'tenant-1',
      userId: 'user-1',
    );
  });

  test('deactivate dispatches DeactivatePartnerCommand with reason', () async {
    final module = _RecordingPartnerModule();
    final cubit = PartnerStatusCubit(
      partnerModule: module,
      executionContext: executionContext,
    );

    await cubit.deactivate(
      partnerId: 'p-1',
      expectedVersion: 2,
      reason: 'Không còn giao dịch',
    );

    final command = module.commands.single as DeactivatePartnerCommand;
    expect(command.tenantId, 'tenant-1');
    expect(command.actorId, 'user-1');
    expect(command.partnerId, 'p-1');
    expect(command.expectedVersion, 2);
    expect(command.reason, 'Không còn giao dịch');
    expect(cubit.state.status, PartnerStatusSubmitStatus.success);
    expect(
      cubit.state.successMessage,
      PartnerStatusCubit.deactivateSuccessMessage,
    );
  });

  test('deactivate maps NO_PERMISSION', () async {
    final cubit = PartnerStatusCubit(
      partnerModule: FakePartnerModule(
        scenario: FakePartnerScenario.deactivatePermissionDenied,
      ),
      executionContext: executionContext,
    );

    await cubit.deactivate(partnerId: 'p-1', expectedVersion: 1);

    expect(cubit.state.status, PartnerStatusSubmitStatus.failure);
    expect(cubit.state.generalError, contains('không có quyền'));
  });

  test('deactivate maps STATE_CHANGED', () async {
    final cubit = PartnerStatusCubit(
      partnerModule: FakePartnerModule(
        scenario: FakePartnerScenario.deactivateStateChanged,
      ),
      executionContext: executionContext,
    );

    await cubit.deactivate(partnerId: 'p-1', expectedVersion: 1);

    expect(cubit.state.status, PartnerStatusSubmitStatus.failure);
    expect(cubit.state.generalError, contains('tải lại'));
  });

  test('reactivate dispatches ReactivatePartnerCommand', () async {
    final module = _RecordingPartnerModule();
    final cubit = PartnerStatusCubit(
      partnerModule: module,
      executionContext: executionContext,
    );

    await cubit.reactivate(partnerId: 'p-1', expectedVersion: 4);

    final command = module.commands.single as ReactivatePartnerCommand;
    expect(command.partnerId, 'p-1');
    expect(command.expectedVersion, 4);
    expect(cubit.state.status, PartnerStatusSubmitStatus.success);
    expect(
      cubit.state.successMessage,
      PartnerStatusCubit.reactivateSuccessMessage,
    );
  });

  test('softDelete dispatches SoftDeletePartnerCommand with reason', () async {
    final module = _RecordingPartnerModule();
    final cubit = PartnerStatusCubit(
      partnerModule: module,
      executionContext: executionContext,
    );

    await cubit.softDelete(
      partnerId: 'p-1',
      expectedVersion: 3,
      reason: 'Tạo nhầm',
    );

    final command = module.commands.single as SoftDeletePartnerCommand;
    expect(command.partnerId, 'p-1');
    expect(command.expectedVersion, 3);
    expect(command.reason, 'Tạo nhầm');
    expect(cubit.state.status, PartnerStatusSubmitStatus.success);
    expect(
      cubit.state.successMessage,
      PartnerStatusCubit.softDeleteSuccessMessage,
    );
  });

  test('softDelete maps HAS_TRANSACTIONS', () async {
    final cubit = PartnerStatusCubit(
      partnerModule: FakePartnerModule(
        scenario: FakePartnerScenario.softDeleteHasTransactions,
      ),
      executionContext: executionContext,
    );

    await cubit.softDelete(partnerId: 'p-1', expectedVersion: 1);

    expect(cubit.state.status, PartnerStatusSubmitStatus.failure);
    expect(cubit.state.generalError, contains('phát sinh giao dịch'));
  });
}

final class _RecordingPartnerModule implements IPartnerModule {
  final commands = <ICommand<Object?>>[];

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) async {
    commands.add(command as ICommand<Object?>);
    if (command is DeactivatePartnerCommand) {
      final deactivate = command as DeactivatePartnerCommand;
      return DeactivatePartnerResult(
        partnerId: deactivate.partnerId,
        expectedVersion: deactivate.expectedVersion + 1,
      ) as TResult;
    }
    if (command is ReactivatePartnerCommand) {
      final reactivate = command as ReactivatePartnerCommand;
      return ReactivatePartnerResult(
        partnerId: reactivate.partnerId,
        expectedVersion: reactivate.expectedVersion + 1,
      ) as TResult;
    }
    if (command is SoftDeletePartnerCommand) {
      final softDelete = command as SoftDeletePartnerCommand;
      return SoftDeletePartnerResult(
        partnerId: softDelete.partnerId,
        expectedVersion: softDelete.expectedVersion + 1,
      ) as TResult;
    }
    throw UnsupportedError(command.runtimeType.toString());
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) {
    throw UnsupportedError(query.runtimeType.toString());
  }
}
