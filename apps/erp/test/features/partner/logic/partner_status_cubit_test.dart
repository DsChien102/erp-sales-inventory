import 'package:erp/features/partner/data/models/partner_models.dart';
import 'package:erp/features/partner/presentation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_partner_repository.dart';
import '../support/scripted_partner_repository.dart';

/// Repository ghi lệnh và trả về kết quả đổi trạng thái (version + 1).
ScriptedPartnerRepository _recording() => ScriptedPartnerRepository(
  onCall: (method, args) => PartnerVersionResult(
    partnerId: args['partnerId'] as String,
    expectedVersion: (args['expectedVersion'] as int) + 1,
  ),
);

void main() {
  test('deactivate dispatches deactivate with reason', () async {
    final repository = _recording();
    final cubit = PartnerStatusCubit(repository: repository);

    await cubit.deactivate(
      partnerId: 'p-1',
      expectedVersion: 2,
      reason: 'Không còn giao dịch',
    );

    final call = repository.invocations.single;
    expect(call.method, 'deactivate');
    expect(call.args['partnerId'], 'p-1');
    expect(call.args['expectedVersion'], 2);
    expect(call.args['reason'], 'Không còn giao dịch');
    expect(cubit.state.status, PartnerStatusSubmitStatus.success);
    expect(
      cubit.state.successMessage,
      PartnerStatusCubit.deactivateSuccessMessage,
    );
  });

  test('deactivate maps NO_PERMISSION', () async {
    final cubit = PartnerStatusCubit(
      repository: FakePartnerRepository(
        scenario: FakePartnerScenario.deactivatePermissionDenied,
      ),
    );

    await cubit.deactivate(partnerId: 'p-1', expectedVersion: 1);

    expect(cubit.state.status, PartnerStatusSubmitStatus.failure);
    expect(cubit.state.generalError, contains('không có quyền'));
  });

  test('deactivate maps STATE_CHANGED', () async {
    final cubit = PartnerStatusCubit(
      repository: FakePartnerRepository(
        scenario: FakePartnerScenario.deactivateStateChanged,
      ),
    );

    await cubit.deactivate(partnerId: 'p-1', expectedVersion: 1);

    expect(cubit.state.status, PartnerStatusSubmitStatus.failure);
    expect(cubit.state.generalError, contains('tải lại'));
  });

  test('reactivate dispatches reactivate', () async {
    final repository = _recording();
    final cubit = PartnerStatusCubit(repository: repository);

    await cubit.reactivate(partnerId: 'p-1', expectedVersion: 4);

    final call = repository.invocations.single;
    expect(call.method, 'reactivate');
    expect(call.args['partnerId'], 'p-1');
    expect(call.args['expectedVersion'], 4);
    expect(cubit.state.status, PartnerStatusSubmitStatus.success);
    expect(
      cubit.state.successMessage,
      PartnerStatusCubit.reactivateSuccessMessage,
    );
  });

  test('softDelete dispatches softDelete with reason', () async {
    final repository = _recording();
    final cubit = PartnerStatusCubit(repository: repository);

    await cubit.softDelete(
      partnerId: 'p-1',
      expectedVersion: 3,
      reason: 'Tạo nhầm',
    );

    final call = repository.invocations.single;
    expect(call.method, 'softDelete');
    expect(call.args['partnerId'], 'p-1');
    expect(call.args['expectedVersion'], 3);
    expect(call.args['reason'], 'Tạo nhầm');
    expect(cubit.state.status, PartnerStatusSubmitStatus.success);
    expect(
      cubit.state.successMessage,
      PartnerStatusCubit.softDeleteSuccessMessage,
    );
  });

  test('softDelete maps HAS_TRANSACTIONS', () async {
    final cubit = PartnerStatusCubit(
      repository: FakePartnerRepository(
        scenario: FakePartnerScenario.softDeleteHasTransactions,
      ),
    );

    await cubit.softDelete(partnerId: 'p-1', expectedVersion: 1);

    expect(cubit.state.status, PartnerStatusSubmitStatus.failure);
    expect(cubit.state.generalError, contains('phát sinh giao dịch'));
  });

  test('G7 (BR-46): HAS_TRANSACTIONS message is role-neutral', () async {
    final cubit = PartnerStatusCubit(
      repository: FakePartnerRepository(
        scenario: FakePartnerScenario.softDeleteHasTransactions,
      ),
    );

    await cubit.softDelete(partnerId: 'p-1', expectedVersion: 1);

    expect(
      cubit.state.generalError,
      'Hồ sơ đã phát sinh giao dịch nên không thể xóa. Bạn có thể ngừng hoạt động.',
    );
  });
}
