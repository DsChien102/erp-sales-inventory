import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/partner/data/models/partner_action_log.dart';
import 'package:erp/features/partner/data/partner_repository.dart';
import 'package:erp/features/partner/presentation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements PartnerRepository {}

void main() {
  PartnerChangeHistoryCubit cubitReturning(PartnerActionLogPage page) {
    final repository = _MockRepo();
    when(
      () => repository.getActionLogs(
        any(),
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => page);
    return PartnerChangeHistoryCubit(repository: repository);
  }

  test('loadHistory maps action logs from the repository', () async {
    final cubit = cubitReturning(_mixedPage());

    await cubit.loadHistory('p-1');

    expect(cubit.state.status, PartnerChangeHistoryStatus.success);
    expect(cubit.state.items, hasLength(3));
    expect(cubit.state.items.first.summary, 'Thêm người liên hệ');
    expect(cubit.state.items.first.actorDisplayName, '8acac7ec');
    expect(cubit.state.items.last.summary, 'Tạo đối tác');

    final updateEntry = cubit.state.items[1];
    expect(updateEntry.summary, 'Cập nhật MST, SĐT chính');
    expect(
      updateEntry.changes,
      containsAll([
        const PartnerFieldChange(
          label: 'SĐT chính',
          before: '0901234567',
          after: '0907654321',
          kind: PartnerFieldChangeKind.modified,
        ),
        const PartnerFieldChange(
          label: 'MST',
          before: PartnerActionLogDiff.emptyValueLabel,
          after: '2201018022',
          kind: PartnerFieldChangeKind.added,
        ),
      ]),
    );
  });

  test('entries without snapshots keep generic summary and no changes', () async {
    final cubit = cubitReturning(_mixedPage());

    await cubit.loadHistory('p-1');

    expect(cubit.state.items.last.summary, 'Tạo đối tác');
    expect(cubit.state.items.last.changes, isEmpty);
  });

  test('loadHistory shows empty success when no logs', () async {
    final cubit = cubitReturning(
      const PartnerActionLogPage(items: [], total: 0, page: 1, limit: 20),
    );

    await cubit.loadHistory('p-1');

    expect(cubit.state.status, PartnerChangeHistoryStatus.success);
    expect(cubit.state.items, isEmpty);
  });

  test('loadHistory shows the Vietnamese sentence for NO_PERMISSION', () async {
    final repository = _MockRepo();
    when(
      () => repository.getActionLogs(
        any(),
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).thenThrow(const AppException(AppErrorCode.noPermission));
    final cubit = PartnerChangeHistoryCubit(repository: repository);

    await cubit.loadHistory('p-1');

    expect(cubit.state.status, PartnerChangeHistoryStatus.failure);
    expect(cubit.state.errorMessage, 'Bạn không có quyền thực hiện thao tác này.');
  });
}

PartnerActionLogPage _mixedPage() {
  const actor = '8acac7ec-0000-4000-8000-000000000001';
  return PartnerActionLogPage(
    total: 3,
    page: 1,
    limit: 20,
    items: [
      PartnerActionLog(
        actionLogId: 'al-1',
        actionType: PartnerActionType.addContact,
        actorUserId: actor,
        createdAt: DateTime(2026, 7, 16, 18, 26),
      ),
      PartnerActionLog(
        actionLogId: 'al-2',
        actionType: PartnerActionType.update,
        actorUserId: actor,
        createdAt: DateTime(2026, 7, 15, 23, 26),
        beforeState: const {
          'display_name': 'Nguyễn Văn A',
          'person_profile': {'phone': '0901234567', 'tax_code': null},
        },
        afterState: const {
          'display_name': 'Nguyễn Văn A',
          'person_profile': {'phone': '0907654321', 'tax_code': '2201018022'},
        },
      ),
      PartnerActionLog(
        actionLogId: 'al-3',
        actionType: PartnerActionType.create,
        actorUserId: actor,
        createdAt: DateTime(2026, 7, 14, 23, 26),
      ),
    ],
  );
}
