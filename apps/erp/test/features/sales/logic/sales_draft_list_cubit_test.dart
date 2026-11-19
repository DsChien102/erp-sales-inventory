import 'dart:async';

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/sales/data/models/sales_draft_list_page.dart';
import 'package:erp/features/sales/logic/sales_draft_list_cubit.dart';
import 'package:erp/features/sales/logic/sales_draft_list_state.dart';
import 'package:erp/features/sales/presentation/models/sales_order_draft/sales_draft_list_item_vm.dart';
import 'package:erp/features/sales/presentation/support/i_sales_active_store_context.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp/features/sales/data/models.dart';
import 'package:c45_shared_application/application.dart';

import '../support/fake_sales_draft_repository.dart';

void main() {
  group('SalesDraftListCubit Task 0 behavior baseline', () {
    test('load_blocked_on_no_permission', () async {
      final fake = FakeSalesDraftRepository()
        ..listError = const AppException('NO_PERMISSION');
      final cubit = _buildCubit(fake);
      addTearDown(cubit.close);

      await cubit.load(isRefresh: true);

      expect(cubit.state, isA<SalesDraftListBlocked>());
      final blocked = cubit.state as SalesDraftListBlocked;
      expect(blocked.message, 'Bạn không có quyền thực hiện thao tác này.');
    });

    test('load_error_message', () async {
      final fake = FakeSalesDraftRepository()
        ..listError = const AppException('SYSTEM_ERROR', serverMessage: 'Server crashed');
      final cubit = _buildCubit(fake);
      addTearDown(cubit.close);

      await cubit.load(isRefresh: true);

      expect(cubit.state, isA<SalesDraftListError>());
      final error = cubit.state as SalesDraftListError;
      expect(error.message, 'Không thể tải danh sách đơn nháp');
    });

    test('search_filters_loaded_rows', () async {
      final fake = FakeSalesDraftRepository()
        ..listItems = [
          _draft(
            draftId: 'draft-1',
            customerName: 'An Bình',
            phone: '0901234567',
            note: 'Giao sáng',
          ),
          _draft(
            draftId: 'draft-2',
            customerName: 'Bảo Long',
            phone: '0987654321',
            note: 'Khách VIP',
          ),
        ];
      final cubit = _buildCubit(fake);
      addTearDown(cubit.close);

      await cubit.load(isRefresh: true);
      expect((cubit.state as SalesDraftListLoaded).items, hasLength(2));

      // Tìm theo tên khách
      await cubit.searchByKeyword('Bình');
      expect((cubit.state as SalesDraftListLoaded).items, hasLength(1));
      expect((cubit.state as SalesDraftListLoaded).items.first.draftId, 'draft-1');

      // Tìm theo SĐT
      await cubit.searchByKeyword('0987');
      expect((cubit.state as SalesDraftListLoaded).items, hasLength(1));
      expect((cubit.state as SalesDraftListLoaded).items.first.draftId, 'draft-2');

      // Tìm theo ghi chú
      await cubit.searchByKeyword('sáng');
      expect((cubit.state as SalesDraftListLoaded).items, hasLength(1));
      expect((cubit.state as SalesDraftListLoaded).items.first.draftId, 'draft-1');

      // Không khớp
      await cubit.searchByKeyword('Không tồn tại');
      expect((cubit.state as SalesDraftListLoaded).items, isEmpty);
    });

    test('creator_label_rejects_uuid', () {
      final vmWithUuid = SalesDraftListItemVm(
        draftId: 'd1',
        version: 1,
        updatedAt: DateTime.utc(2026, 8, 1),
        customerLabel: 'Khách',
        lineCount: 1,
        total: const MoneyDto(amountMinor: 100, currencyCode: 'VND'),
        uiStatus: SalesDraftUiStatus.composing,
        createdByName: 'a5710600-c97d-411f-8fe0-c8e5473724ff',
        isOwnedByMe: false,
      );
      expect(vmWithUuid.creatorLabel, isNull);

      final vmWithName = vmWithUuid.copyWith(createdByName: 'Nguyễn Văn A');
      expect(vmWithName.creatorLabel, 'Nguyễn Văn A');
    });

    test('maps_walk_in_and_needs_check', () async {
      final fake = FakeSalesDraftRepository()
        ..listItems = [
          _draft(
            draftId: 'draft-walk-in',
            customerName: null,
            needsRevalidation: false,
          ),
          _draft(
            draftId: 'draft-needs-check',
            customerName: 'Khách C',
            needsRevalidation: true,
          ),
        ];
      final cubit = _buildCubit(fake);
      addTearDown(cubit.close);

      await cubit.load(isRefresh: true);
      final loaded = cubit.state as SalesDraftListLoaded;
      expect(loaded.items, hasLength(2));

      final walkIn = loaded.items.firstWhere((i) => i.draftId == 'draft-walk-in');
      expect(walkIn.customerLabel, 'Khách lẻ');
      expect(walkIn.uiStatus, SalesDraftUiStatus.composing);

      final needsCheck = loaded.items.firstWhere((i) => i.draftId == 'draft-needs-check');
      expect(needsCheck.customerLabel, 'Khách C');
      expect(needsCheck.uiStatus, SalesDraftUiStatus.needsCheck);
    });

    test('first_load_uses_page_25_and_scope_mine', () async {
      final fake = FakeSalesDraftRepository();
      final cubit = _buildCubit(fake);
      addTearDown(cubit.close);

      await cubit.load();

      expect(fake.listCalls, hasLength(1));
      final call = fake.listCalls.first;
      expect(call.pageSize, 25);
      expect(call.createdByUserId, 'user-1');
      expect(call.search, isNull);
      expect(call.cursor, isNull);
    });

    test('set_scope_all_sends_null', () async {
      final fake = FakeSalesDraftRepository();
      final cubit = _buildCubit(fake);
      addTearDown(cubit.close);

      await cubit.load();
      await cubit.setScope(SalesDraftScopeFilter.all);

      expect(fake.listCalls, hasLength(2));
      final call = fake.listCalls.last;
      expect(call.createdByUserId, isNull);
    });

    test('set_scope_mine_sends_created_by', () async {
      final fake = FakeSalesDraftRepository();
      final cubit = _buildCubit(fake);
      addTearDown(cubit.close);

      await cubit.load();
      await cubit.setScope(SalesDraftScopeFilter.all);
      expect(fake.listCalls.last.createdByUserId, isNull);

      await cubit.setScope(SalesDraftScopeFilter.mine);
      expect(fake.listCalls.last.createdByUserId, 'user-1');
    });

    test('search_reloads_with_server_param', () async {
      final fake = FakeSalesDraftRepository();
      final cubit = _buildCubit(fake);
      addTearDown(cubit.close);

      await cubit.load();
      await cubit.searchByKeyword('an');

      expect(fake.listCalls, hasLength(2));
      final call = fake.listCalls.last;
      expect(call.search, 'an');
      expect(call.cursor, isNull);
    });

    test('load_more_appends_next_page', () async {
      final fake = FakeSalesDraftRepository()
        ..listItems = [_draft(draftId: 'd1'), _draft(draftId: 'd2')]
        ..hasMore = true
        ..nextCursor = 'c1';

      final cubit = _buildCubit(fake);
      addTearDown(cubit.close);

      await cubit.load();
      expect((cubit.state as SalesDraftListLoaded).items, hasLength(2));

      fake
        ..listItems = [_draft(draftId: 'd3')]
        ..hasMore = false
        ..nextCursor = null;

      await cubit.loadMore();

      expect(fake.listCalls, hasLength(2));
      expect(fake.listCalls.last.cursor, 'c1');
      final loaded = cubit.state as SalesDraftListLoaded;
      expect(loaded.items, hasLength(3));
      expect(loaded.hasMore, isFalse);
    });

    test('load_more_ignored_when_no_more', () async {
      final fake = FakeSalesDraftRepository()
        ..listItems = [_draft(draftId: 'd1')]
        ..hasMore = false;

      final cubit = _buildCubit(fake);
      addTearDown(cubit.close);

      await cubit.load();
      await cubit.loadMore();

      expect(fake.listCalls, hasLength(1));
    });

    test('load_more_error_keeps_items', () async {
      final fake = FakeSalesDraftRepository()
        ..listItems = [_draft(draftId: 'd1')]
        ..hasMore = true
        ..nextCursor = 'c1';

      final cubit = _buildCubit(fake);
      addTearDown(cubit.close);

      await cubit.load();
      expect((cubit.state as SalesDraftListLoaded).items, hasLength(1));

      fake.listError = const AppException('NETWORK_ERROR');
      await cubit.loadMore();

      final loaded = cubit.state as SalesDraftListLoaded;
      expect(loaded.items, hasLength(1));
      expect(loaded.isLoadingMore, isFalse);
      expect(loaded.loadMoreError, isNotNull);
    });

    test('stale_response_after_scope_change_is_dropped', () async {
      final fake = FakeSalesDraftRepository();
      var slowCallFinished = false;
      fake.onListPage = (call) {
        if (call.createdByUserId == 'user-1' && !slowCallFinished) {
          // Slow first response
          return SalesDraftListPage(
            items: [
              SalesDraftListEntry(
                draft: _draft(draftId: 'mine-old'),
                createdByUserId: 'user-1',
              ),
            ],
            hasMore: false,
            totalCount: 1,
          );
        }
        return SalesDraftListPage(
          items: [
            SalesDraftListEntry(
              draft: _draft(draftId: 'all-new'),
              createdByUserId: 'user-2',
            ),
          ],
          hasMore: false,
          totalCount: 1,
        );
      };

      final cubit = _buildCubit(fake);
      addTearDown(cubit.close);

      final f1 = cubit.load();
      final f2 = cubit.setScope(SalesDraftScopeFilter.all);
      slowCallFinished = true;
      await Future.wait([f1, f2]);

      final loaded = cubit.state as SalesDraftListLoaded;
      expect(loaded.items.single.draftId, 'all-new');
    });

    test('creator_label_uses_server_name', () async {
      final fake = FakeSalesDraftRepository()
        ..listEntries = [
          SalesDraftListEntry(
            draft: _draft(draftId: 'd-other'),
            createdByUserId: 'user-2',
            createdByName: 'Chị Lan Kế Toán',
          ),
        ];

      final cubit = _buildCubit(fake);
      addTearDown(cubit.close);

      await cubit.load();
      final loaded = cubit.state as SalesDraftListLoaded;
      expect(loaded.items.single.creatorLabel, 'Chị Lan Kế Toán');
    });

    test('discard_reference_unavailable_needs_reload', () async {
      final fake = FakeSalesDraftRepository()
        ..listItems = [_draft(draftId: 'd1')]
        ..cancelError = const AppException('REFERENCE_UNAVAILABLE');

      final cubit = _buildCubit(fake);
      addTearDown(cubit.close);

      await cubit.load();
      final ok = await cubit.discardDraft('d1');

      expect(ok, isFalse);
      final loaded = cubit.state as SalesDraftListLoaded;
      expect(loaded.needsReload, isTrue);
      expect(loaded.actionMessage, 'Đơn nháp đã thay đổi. Vui lòng tải lại danh sách.');
    });

    test('total_count_ignores_scope_and_search', () async {
      final fake = FakeSalesDraftRepository()
        ..totalCount = 40
        ..listItems = [_draft(draftId: 'd1', customerName: 'An')];

      final cubit = _buildCubit(fake);
      addTearDown(cubit.close);

      await cubit.load();
      expect(cubit.state.totalCount, 40);

      await cubit.setScope(SalesDraftScopeFilter.all);
      expect(cubit.state.totalCount, 40);

      await cubit.searchByKeyword('An');
      expect(cubit.state.totalCount, 40);
    });

    test('load_more_keeps_total_count', () async {
      final fake = FakeSalesDraftRepository()
        ..totalCount = 40
        ..hasMore = true
        ..nextCursor = 'c1'
        ..listItems = [_draft(draftId: 'd1')];

      final cubit = _buildCubit(fake);
      addTearDown(cubit.close);

      await cubit.load();
      expect(cubit.state.totalCount, 40);

      fake.hasMore = false;
      fake.nextCursor = null;
      fake.listItems = [_draft(draftId: 'd2')];

      await cubit.loadMore();
      expect(cubit.state.totalCount, 40);
      final loaded = cubit.state as SalesDraftListLoaded;
      expect(loaded.items, hasLength(2));
    });

    test('discard_decrements_total_count', () async {
      final fake = FakeSalesDraftRepository()
        ..totalCount = 40
        ..listItems = [_draft(draftId: 'd1')];

      final cubit = _buildCubit(fake);
      addTearDown(cubit.close);

      await cubit.load();
      expect(cubit.state.totalCount, 40);

      final ok = await cubit.discardDraft('d1');
      expect(ok, isTrue);
      expect(cubit.state.totalCount, 39);
    });

    test('scope_change_while_first_page_in_flight', () async {
      final fake = FakeSalesDraftRepository();
      final gate1 = Completer<void>();
      var callIndex = 0;
      fake.onListPage = (call) {
        callIndex++;
        if (callIndex == 1) {
          return SalesDraftListPage(
            items: [
              SalesDraftListEntry(
                draft: _draft(draftId: 'mine-1'),
                createdByUserId: 'user-1',
              ),
            ],
            hasMore: false,
            totalCount: 2,
          );
        }
        return SalesDraftListPage(
          items: [
            SalesDraftListEntry(
              draft: _draft(draftId: 'all-2'),
              createdByUserId: 'user-2',
            ),
          ],
          hasMore: false,
          totalCount: 2,
        );
      };
      fake.onListGate = () async {
        if (callIndex == 0) {
          await gate1.future;
        }
      };

      final cubit = _buildCubit(fake);
      addTearDown(cubit.close);

      final loadFuture = cubit.load();
      await Future<void>.delayed(Duration.zero);
      final scopeFuture = cubit.setScope(SalesDraftScopeFilter.all);

      gate1.complete();
      await loadFuture;
      await scopeFuture;

      expect(fake.listCalls, hasLength(2));
      expect(fake.listCalls[1].createdByUserId, isNull);
      expect(cubit.state, isA<SalesDraftListLoaded>());
      final loaded = cubit.state as SalesDraftListLoaded;
      expect(loaded.scope, SalesDraftScopeFilter.all);
      expect(loaded.items.single.draftId, 'all-2');
    });

    test('search_while_first_page_in_flight', () async {
      final fake = FakeSalesDraftRepository();
      final gate1 = Completer<void>();
      var callIndex = 0;
      fake.onListPage = (call) {
        callIndex++;
        if (callIndex == 1) {
          return SalesDraftListPage(
            items: [
              SalesDraftListEntry(
                draft: _draft(draftId: 'mine-1'),
                createdByUserId: 'user-1',
              ),
            ],
            hasMore: false,
            totalCount: 2,
          );
        }
        return SalesDraftListPage(
          items: [
            SalesDraftListEntry(
              draft: _draft(draftId: 'search-2', customerName: 'an'),
              createdByUserId: 'user-1',
            ),
          ],
          hasMore: false,
          totalCount: 2,
        );
      };
      fake.onListGate = () async {
        if (callIndex == 0) {
          await gate1.future;
        }
      };

      final cubit = _buildCubit(fake);
      addTearDown(cubit.close);

      final loadFuture = cubit.load();
      await Future<void>.delayed(Duration.zero);
      final searchFuture = cubit.searchByKeyword('an');

      gate1.complete();
      await loadFuture;
      await searchFuture;

      expect(fake.listCalls, hasLength(2));
      expect(fake.listCalls[1].search, 'an');
      expect(cubit.state, isA<SalesDraftListLoaded>());
      final loaded = cubit.state as SalesDraftListLoaded;
      expect(loaded.query, 'an');
      expect(loaded.items.single.draftId, 'search-2');
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

SalesOrderDraftDto _draft({
  required String draftId,
  String? customerName,
  String? phone,
  String? note,
  bool needsRevalidation = false,
}) {
  return SalesOrderDraftDto(
    draftId: draftId,
    version: 1,
    status: SalesDraftStatus.active,
    storeId: 'store-1',
    customer: customerName != null
        ? CustomerSnapshotDto(
            customerId: 'cust-$draftId',
            displayName: customerName,
            phoneNumber: phone,
          )
        : null,
    orderNote: note,
    savedAt: DateTime.utc(2026, 8, 1),
    savedByActorId: 'user-1',
    needsRevalidation: needsRevalidation,
    lines: const [],
    total: const MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
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
