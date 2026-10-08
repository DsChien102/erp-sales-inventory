import 'package:erp/features/partner/data/models/partner_action_log.dart';
import 'package:erp/features/partner/data/partner_repository.dart';
import 'package:erp/features/partner/presentation.dart';
import 'package:erp/features/partner/presentation/pages/partner_change_history_page.dart';
import 'package:erp/features/partner/presentation/widgets/partner_change_history_body.dart';
import 'package:erp/features/partner/presentation/widgets/partner_change_history_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vet45_design_system/design_system.dart';

void main() {
  final occurredAt = DateTime.utc(2026, 7, 16, 11, 26);

  testWidgets(
    'wgt_e01_u07_fr01_01: history card renders every field-change state with DS widgets',
    (tester) async {
      final entry = PartnerChangeHistoryEntry(
        id: 'al-1',
        occurredAt: occurredAt,
        actorDisplayName: 'user-1',
        changeType: 'update',
        summary: 'Cập nhật MST, SĐT chính và 1 thông tin khác',
        reason: 'Chuẩn hóa hồ sơ',
        changes: [
          PartnerFieldChange(
            label: 'MST',
            before: PartnerActionLogDiff.emptyValueLabel,
            after: '2201018022',
            kind: PartnerFieldChangeKind.added,
          ),
          PartnerFieldChange(
            label: 'SĐT chính',
            before: '0901234567',
            after: '0907654321',
            kind: PartnerFieldChangeKind.modified,
          ),
          PartnerFieldChange(
            label: 'Ghi chú',
            before: 'Khách cũ',
            after: PartnerActionLogDiff.emptyValueLabel,
            kind: PartnerFieldChangeKind.removed,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PartnerChangeHistoryCard(entry: entry),
          ),
        ),
      );

      expect(find.byType(VCard), findsOneWidget);
      expect(find.byType(VText), findsNWidgets(7));
      expect(find.text('MST: Thêm mới: 2201018022'), findsOneWidget);
      expect(
        find.text('SĐT chính: 0901234567 → 0907654321'),
        findsOneWidget,
      );
      expect(find.text('Ghi chú: Đã xóa: Khách cũ'), findsOneWidget);
      expect(find.text('Lý do: Chuẩn hóa hồ sơ'), findsOneWidget);
      expect(find.text('bởi user-1'), findsOneWidget);
    },
  );

  testWidgets(
    'wgt_e01_u07_fr01_02: history body uses DS empty state',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PartnerChangeHistoryBody(
            state: const PartnerChangeHistoryState(
              status: PartnerChangeHistoryStatus.success,
            ),
            onRetry: () {},
            onRefresh: () async {},
          ),
        ),
      );

      expect(find.byType(VEmptyState), findsOneWidget);
      expect(find.text('Chưa có lịch sử thao tác nào'), findsOneWidget);
    },
  );

  testWidgets(
    'wgt_e01_u07_fr01_03: history body uses DS error state and retries',
    (tester) async {
      var retryCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: PartnerChangeHistoryBody(
            state: const PartnerChangeHistoryState(
              status: PartnerChangeHistoryStatus.failure,
              errorMessage: 'Không thể tải lịch sử',
            ),
            onRetry: () => retryCount += 1,
            onRefresh: () async {},
          ),
        ),
      );

      expect(find.byType(VEmptyState), findsOneWidget);
      expect(find.text('Không thể tải lịch sử'), findsOneWidget);

      await tester.tap(find.text('Thử lại'));
      await tester.pump();

      expect(retryCount, 1);
    },
  );

  testWidgets(
    'wgt_e01_u07_fr01_04: history page uses the DS page scaffold',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PartnerChangeHistoryPage(
            partnerId: 'p-1',
            partnerName: 'Nguyễn Văn A',
            repository: _emptyRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('partner_change_history_page')),
        findsOneWidget,
      );
      expect(find.byType(VPageScaffold), findsOneWidget);
    },
  );
}

class _MockPartnerRepository extends Mock implements PartnerRepository {}

PartnerRepository _emptyRepository() {
  final repository = _MockPartnerRepository();
  when(
    () => repository.getActionLogs(
      any(),
      page: any(named: 'page'),
      limit: any(named: 'limit'),
    ),
  ).thenAnswer(
    (_) async => const PartnerActionLogPage(items: [], total: 0, page: 1, limit: 20),
  );
  return repository;
}
