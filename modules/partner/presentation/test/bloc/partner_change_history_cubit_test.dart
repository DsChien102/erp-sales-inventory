import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_partner_application/testing.dart';
import 'package:vet45_partner_presentation/presentation.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

void main() {
  test('loadHistory maps action logs from module query', () async {
    final cubit = PartnerChangeHistoryCubit(
      partnerModule: FakePartnerModule(
        scenario: FakePartnerScenario.actionLogsMixed,
      ),
      executionContext: FakeExecutionContext(tenantId: 'tenant-1'),
    );

    await cubit.loadHistory('p-1');

    expect(cubit.state.status, PartnerChangeHistoryStatus.success);
    expect(cubit.state.items, hasLength(3));
    expect(cubit.state.items.first.summary, 'Thêm người liên hệ');
    expect(cubit.state.items.first.actorDisplayName, '8acac7ec');
    expect(cubit.state.items.last.summary, 'Tạo đối tác');
  });

  test('loadHistory shows empty success when no logs', () async {
    final cubit = PartnerChangeHistoryCubit(
      partnerModule: FakePartnerModule(
        scenario: FakePartnerScenario.actionLogsEmpty,
      ),
      executionContext: FakeExecutionContext(tenantId: 'tenant-1'),
    );

    await cubit.loadHistory('p-1');

    expect(cubit.state.status, PartnerChangeHistoryStatus.success);
    expect(cubit.state.items, isEmpty);
  });
}
