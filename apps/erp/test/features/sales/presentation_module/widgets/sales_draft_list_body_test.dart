import 'package:erp/features/sales/data/models/sales_draft_list_page.dart'
    hide SalesDraftListPage;
import 'package:erp/features/sales/presentation.dart';
import 'package:erp/features/sales/presentation/pages/sales_draft_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/features/sales/data/models.dart';
import 'package:c45_shared_application/application.dart';

import '../../support/fake_sales_draft_repository.dart';

void main() {
  group('SalesDraftListBody', () {
    testWidgets('mine_tab_shows_no_created_by', (tester) async {
      final otherItem = _draftVm(
        draftId: 'draft-other',
        isOwnedByMe: false,
        customerLabel: 'Khách của người khác',
      );

      final state = SalesDraftListLoaded(
        items: [otherItem],
        isDefaultEmpty: false,
        totalCount: 1,
      );

      // Tab mine: không hiển thị "Tạo bởi"
      await tester.pumpWidget(_host(
        state: state,
        displayScope: SalesDraftScopeFilter.mine,
      ));
      await tester.pump();

      expect(find.textContaining('Tạo bởi:'), findsNothing);

      // Tab all: hiển thị "Tạo bởi: Người tạo"
      await tester.pumpWidget(_host(
        state: state,
        displayScope: SalesDraftScopeFilter.all,
      ));
      await tester.pump();

      expect(find.textContaining('Tạo bởi: Người tạo'), findsOneWidget);
    });

    testWidgets('scroll_end_calls_load_more', (tester) async {
      var loadMoreCalled = false;
      final items = List.generate(
        15,
        (i) => _draftVm(
          draftId: 'draft-$i',
          isOwnedByMe: true,
          customerLabel: 'Khách $i',
        ),
      );

      final state = SalesDraftListLoaded(
        items: items,
        isDefaultEmpty: false,
        hasMore: true,
        totalCount: 15,
      );

      await tester.pumpWidget(_host(
        state: state,
        displayScope: SalesDraftScopeFilter.mine,
        onLoadMore: () => loadMoreCalled = true,
      ));
      await tester.pump();

      // Cuộn xuống cuối
      await tester.drag(find.byType(ListView), const Offset(0, -1000));
      await tester.pumpAndSettle();

      expect(loadMoreCalled, isTrue);
    });

    testWidgets('tab_restores_from_cubit_scope', (tester) async {
      final fake = FakeSalesDraftRepository()
        ..totalCount = 1
        ..listEntries = [
          SalesDraftListEntry(
            draft: SalesOrderDraftDto(
              draftId: 'd-other',
              version: 1,
              status: SalesDraftStatus.active,
              storeId: 'store-1',
              savedAt: DateTime.utc(2026, 8, 1),
              savedByActorId: 'user-2',
              needsRevalidation: false,
              lines: const [],
              total: const MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
            ),
            createdByUserId: 'user-2',
            createdByName: 'Chị Lan',
          ),
        ];
      final cubit = _buildCubit(fake);
      addTearDown(cubit.close);

      await cubit.setScope(SalesDraftScopeFilter.all);

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: BlocProvider<SalesDraftListCubit>.value(
            value: cubit,
            child: const SalesDraftListPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Tạo bởi:'), findsOneWidget);
    });

    testWidgets('tab_change_calls_set_scope', (tester) async {
      final fake = FakeSalesDraftRepository()
        ..totalCount = 1
        ..listItems = [
          SalesOrderDraftDto(
            draftId: 'd1',
            version: 1,
            status: SalesDraftStatus.active,
            storeId: 'store-1',
            savedAt: DateTime.utc(2026, 8, 1),
            savedByActorId: 'user-1',
            needsRevalidation: false,
            lines: const [],
            total: const MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
          ),
        ];
      final cubit = _buildCubit(fake);
      addTearDown(cubit.close);

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: BlocProvider<SalesDraftListCubit>.value(
            value: cubit,
            child: const SalesDraftListPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(cubit.state.scope, SalesDraftScopeFilter.mine);

      await tester.tap(find.text('Tất cả đơn nháp'));
      await tester.pumpAndSettle();

      expect(cubit.state.scope, SalesDraftScopeFilter.all);
    });
  });
}

SalesDraftListCubit _buildCubit(FakeSalesDraftRepository fake) {
  return SalesDraftListCubit(
    repository: fake,
    executionContext: const _TestExecutionContext(),
    activeStoreContext: const _TestActiveStoreContext(),
  );
}

final class _TestExecutionContext implements IExecutionContext {
  const _TestExecutionContext();
  @override
  String get correlationId => 'corr-1';
  @override
  Future<String> requireTenantId() async => 'tenant-1';
  @override
  Future<String> requireUserId() async => 'user-1';
}

final class _TestActiveStoreContext implements ISalesActiveStoreContext {
  const _TestActiveStoreContext();
  @override
  String? get activeStoreId => 'store-1';
  @override
  Future<String> requireActiveStoreId() async => 'store-1';
}

Widget _host({
  required SalesDraftListState state,
  required SalesDraftScopeFilter displayScope,
  VoidCallback? onLoadMore,
}) {
  return MaterialApp(
    theme: VTheme.lightTheme,
    home: Scaffold(
      body: SizedBox(
        width: 390,
        height: 600,
        child: SalesDraftListBody(
          state: state,
          displayScope: displayScope,
          onRefresh: () async {},
          onRetry: () {},
          onTapDraft: (_) {},
          onDiscardDraft: (_) {},
          onLoadMore: onLoadMore,
        ),
      ),
    ),
  );
}

SalesDraftListItemVm _draftVm({
  required String draftId,
  required bool isOwnedByMe,
  required String customerLabel,
}) {
  return SalesDraftListItemVm(
    draftId: draftId,
    version: 1,
    updatedAt: DateTime.utc(2026, 8, 1),
    customerLabel: customerLabel,
    lineCount: 1,
    total: const MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
    uiStatus: SalesDraftUiStatus.composing,
    isOwnedByMe: isOwnedByMe,
    createdByName: 'Người tạo',
  );
}
