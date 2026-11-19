import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/sales/presentation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp/features/sales/data/models.dart';
import 'package:c45_shared_application/application.dart';

import '../../support/fake_sales_draft_repository.dart';

void main() {
  group('SalesDraftListCubit live list/cancel', () {
    test('load queries active store and maps server draft fields', () async {
      final fake = _repo(
        listItems: [
          _draft(
            draftId: 'draft-server-1',
            version: 3,
            savedAt: DateTime.utc(2026, 8, 1, 9, 15),
            savedByActorId: 'user-1',
            customer: const CustomerSnapshotDto(
              customerId: 'cust-1',
              displayName: 'Nguyễn Văn A',
              phoneNumber: '0901 111 222',
            ),
            orderNote: 'Giao chiều',
            lineCount: 2,
            totalMinor: 250000,
            needsRevalidation: true,
          ),
          _draft(
            draftId: 'draft-walk-in',
            version: 1,
            savedAt: DateTime.utc(2026, 8, 2, 10),
            savedByActorId: 'user-2',
            customer: null,
            orderNote: null,
            lineCount: 0,
            totalMinor: 0,
          ),
        ],
      );
      final cubit = _cubit(fake);
      addTearDown(cubit.close);

      await cubit.load(isRefresh: true);

      expect(fake.listCalls, hasLength(1));
      expect(fake.listCalls.single.storeId, 'store-1');
      expect(fake.listCalls.single.pageSize, 25);

      final loaded = cubit.state as SalesDraftListLoaded;
      expect(loaded.items, hasLength(2));

      final named = loaded.items.firstWhere((e) => e.draftId == 'draft-server-1');
      expect(named.updatedAt, DateTime.utc(2026, 8, 1, 9, 15));
      expect(named.customerLabel, 'Nguyễn Văn A');
      expect(named.phone, '0901 111 222');
      expect(named.note, 'Giao chiều');
      expect(named.createdByName, isNull);
      expect(named.isOwnedByMe, isTrue);
      expect(named.lineCount, 2);
      expect(named.total.amountMinor, 250000);
      expect(named.uiStatus, SalesDraftUiStatus.needsCheck);
      expect(named.version, 3);

      final walkIn = loaded.items.firstWhere((e) => e.draftId == 'draft-walk-in');
      expect(walkIn.customerLabel, 'Khách lẻ');
      expect(walkIn.phone, isNull);
      expect(walkIn.note, isNull);
      expect(walkIn.createdByName, isNull);
      expect(walkIn.isOwnedByMe, isFalse);
      expect(walkIn.lineCount, 0);
      expect(walkIn.uiStatus, SalesDraftUiStatus.composing);
    });

    test('totalCount ignores scope and keyword filters', () async {
      final fake = _repo(
        listItems: [
          _draft(
            draftId: 'draft-mine',
            version: 1,
            savedAt: DateTime.utc(2026, 8, 1),
            savedByActorId: 'user-1',
            customer: const CustomerSnapshotDto(
              customerId: 'cust-1',
              displayName: 'Khách A',
            ),
            lineCount: 1,
            totalMinor: 100000,
          ),
          _draft(
            draftId: 'draft-other',
            version: 1,
            savedAt: DateTime.utc(2026, 8, 2),
            savedByActorId: 'user-2',
            customer: const CustomerSnapshotDto(
              customerId: 'cust-2',
              displayName: 'Khách B',
            ),
            lineCount: 1,
            totalMinor: 100000,
          ),
        ],
      );
      final cubit = _cubit(fake);
      addTearDown(cubit.close);

      await cubit.load(isRefresh: true);
      expect(cubit.state.totalCount, 2);

      // Cubit giữ toàn bộ rows; scope lọc ở SalesDraftListBody theo displayScope.
      expect((cubit.state as SalesDraftListLoaded).items, hasLength(2));

      await cubit.searchByKeyword('Khách A');
      expect((cubit.state as SalesDraftListLoaded).items, hasLength(1));
      expect(cubit.state.totalCount, 2);

      await cubit.clearSearch();
      await cubit.discardDraft('draft-other', expectedVersion: 1);
      expect(cubit.state.totalCount, 1);
    });

    test('concurrent load calls issue a single query', () async {
      final fake = _repo(listItems: const []);
      final cubit = _cubit(fake);
      addTearDown(cubit.close);

      await Future.wait([cubit.load(), cubit.load()]);

      expect(fake.listCalls, hasLength(1));
    });

    test(
      'discardDraft sends cancel with version/store/idempotency and removes on success',
      () async {
        final fake = _repo(
          listItems: [
            _draft(
              draftId: 'draft-cancel-ok',
              version: 4,
              savedAt: DateTime.utc(2026, 8, 3),
              savedByActorId: 'user-1',
              customer: const CustomerSnapshotDto(
                customerId: 'cust-1',
                displayName: 'Khách A',
              ),
              lineCount: 1,
              totalMinor: 100000,
            ),
          ],
        );
        final cubit = _cubit(fake);
        addTearDown(cubit.close);

        await cubit.load(isRefresh: true);
        final ok = await cubit.discardDraft(
          'draft-cancel-ok',
          expectedVersion: 4,
        );

        expect(ok, isTrue);
        expect(fake.cancelCalls, hasLength(1));
        final command = fake.cancelCalls.single;
        expect(command.draftId, 'draft-cancel-ok');
        expect(command.storeId, 'store-1');
        expect(command.expectedVersion, 4);
        expect(command.idempotencyKey, isNotEmpty);
        expect(command.idempotencyKey, contains('draft-cancel-ok'));

        final loaded = cubit.state as SalesDraftListLoaded;
        expect(loaded.items, isEmpty);
        expect(loaded.needsReload, isFalse);
        expect(loaded.discardingDraftId, isNull);
      },
    );

    test('failed cancel retains row and clears in-flight id', () async {
      final fake = _repo(
        listItems: [
          _draft(
            draftId: 'draft-fail',
            version: 2,
            savedAt: DateTime.utc(2026, 8, 4),
            savedByActorId: 'user-1',
            customer: null,
            lineCount: 1,
            totalMinor: 50000,
          ),
        ],
        cancelError: const AppException(
          'SYSTEM_ERROR',
          serverMessage: 'Server error.',
        ),
      );
      final cubit = _cubit(fake);
      addTearDown(cubit.close);

      await cubit.load(isRefresh: true);
      final ok = await cubit.discardDraft('draft-fail', expectedVersion: 2);

      expect(ok, isFalse);
      final loaded = cubit.state as SalesDraftListLoaded;
      expect(loaded.items, hasLength(1));
      expect(loaded.items.single.draftId, 'draft-fail');
      expect(loaded.needsReload, isFalse);
      expect(loaded.discardingDraftId, isNull);
      expect(loaded.actionMessage, 'Không xóa được đơn nháp');
    });

    test('stale cancel retains row and reports reload-needed', () async {
      final fake = _repo(
        listItems: [
          _draft(
            draftId: 'draft-stale',
            version: 5,
            savedAt: DateTime.utc(2026, 8, 5),
            savedByActorId: 'user-1',
            customer: const CustomerSnapshotDto(
              customerId: 'cust-9',
              displayName: 'Khách B',
            ),
            lineCount: 1,
            totalMinor: 90000,
          ),
        ],
        cancelError: const AppException(
          'STALE_DATA',
          serverMessage: 'Draft version has changed.',
        ),
      );
      final cubit = _cubit(fake);
      addTearDown(cubit.close);

      await cubit.load(isRefresh: true);
      final ok = await cubit.discardDraft('draft-stale', expectedVersion: 5);

      expect(ok, isFalse);
      final loaded = cubit.state as SalesDraftListLoaded;
      expect(loaded.items, hasLength(1));
      expect(loaded.items.single.draftId, 'draft-stale');
      expect(loaded.needsReload, isTrue);
      expect(loaded.discardingDraftId, isNull);
      expect(loaded.actionMessage, 'Đơn nháp đã thay đổi. Vui lòng tải lại danh sách.');
    });

    test('duplicate discard while in-flight is ignored', () async {
      final fake = _repo(
        listItems: [
          _draft(
            draftId: 'draft-inflight',
            version: 1,
            savedAt: DateTime.utc(2026, 8, 6),
            savedByActorId: 'user-1',
            customer: null,
            lineCount: 1,
            totalMinor: 10000,
          ),
        ],
        cancelDelay: const Duration(milliseconds: 40),
      );
      final cubit = _cubit(fake);
      addTearDown(cubit.close);

      await cubit.load(isRefresh: true);
      final first = cubit.discardDraft('draft-inflight', expectedVersion: 1);
      final second = cubit.discardDraft('draft-inflight', expectedVersion: 1);
      final results = await Future.wait([first, second]);

      expect(fake.cancelCalls, hasLength(1));
      expect(results, containsAll([isTrue, isFalse]));
      expect(results.where((ok) => ok).length, 1);
    });

    test('cancel_reference_unavailable_needs_reload', () async {
      final fake = _repo(
        listItems: [_simple('draft-gone')],
        cancelError: const AppException('REFERENCE_UNAVAILABLE'),
      );
      final cubit = _cubit(fake);
      addTearDown(cubit.close);

      await cubit.load(isRefresh: true);
      expect(await cubit.discardDraft('draft-gone', expectedVersion: 1), isFalse);

      final loaded = cubit.state as SalesDraftListLoaded;
      expect(loaded.needsReload, isTrue);
      expect(loaded.actionMessage, 'Đơn nháp đã thay đổi. Vui lòng tải lại danh sách.');
    });

    test('cancel_sends_idempotency_key', () async {
      final fake = _repo(listItems: [_simple('draft-1', version: 3)]);
      final cubit = _cubit(fake);
      addTearDown(cubit.close);

      await cubit.load(isRefresh: true);
      await cubit.discardDraft('draft-1');

      expect(fake.cancelCalls.single.idempotencyKey, 'cancel:draft-1:v3');
      expect(fake.cancelCalls.single.expectedVersion, 3);
    });

    test('load_permission_denied_shows_6_4_message', () async {
      final fake = _repo(listItems: const [], listError: const AppException('NO_PERMISSION'));
      final cubit = _cubit(fake);
      addTearDown(cubit.close);

      await cubit.load(isRefresh: true);

      expect(
        cubit.state,
        isA<SalesDraftListBlocked>().having(
          (s) => s.message,
          'message',
          'Bạn không có quyền thực hiện thao tác này.',
        ),
      );
    });

    test('load_data_scope_denied_shows_6_4_message', () async {
      final fake = _repo(
        listItems: const [],
        listError: const AppException('DATA_SCOPE_DENIED', serverMessage: 'Store scope denied.'),
      );
      final cubit = _cubit(fake);
      addTearDown(cubit.close);

      await cubit.load(isRefresh: true);

      expect(
        cubit.state,
        isA<SalesDraftListBlocked>().having(
          (s) => s.message,
          'message',
          'Cửa hàng hiện tại không còn khả dụng.',
        ),
      );
    });

    test('load_other_error_never_shows_server_message', () async {
      final fake = _repo(
        listItems: const [],
        listError: const AppException(
          'SYSTEM_ERROR',
          serverMessage: 'Sales draft operation failed.',
        ),
      );
      final cubit = _cubit(fake);
      addTearDown(cubit.close);

      await cubit.load(isRefresh: true);

      expect(
        cubit.state,
        isA<SalesDraftListError>().having(
          (s) => s.message,
          'message',
          'Không thể tải danh sách đơn nháp',
        ),
      );
    });

    test('SalesDraftListItemVm.creatorLabel formats name, email, and rejects phone or uuid', () {
      final base = SalesDraftListItemVm(
        draftId: 'd1',
        version: 1,
        updatedAt: DateTime.utc(2026, 8, 1),
        customerLabel: 'Khách',
        lineCount: 1,
        total: const MoneyDto(amountMinor: 100, currencyCode: 'VND'),
        uiStatus: SalesDraftUiStatus.composing,
        createdByName: 'Nguyễn Văn An',
        isOwnedByMe: false,
      );

      expect(base.copyWith(createdByName: 'Nguyễn Văn An').creatorLabel, 'Nguyễn Văn An');
      expect(base.copyWith(createdByName: 'seller@example.com').creatorLabel, 'seller@example.com');
      expect(
        base
            .copyWith(createdByName: '3adba8f1-3fa6-4b2f-893e-5fa321abcdef', isOwnedByMe: true)
            .creatorLabel,
        isNull,
      );
      expect(
        base
            .copyWith(createdByName: '3adba8f1-3fa6-4b2f-893e-5fa321abcdef', isOwnedByMe: false)
            .creatorLabel,
        isNull,
      );
      expect(base.copyWith(createdByName: '0981287110', isOwnedByMe: true).creatorLabel, isNull);
      expect(base.copyWith(createdByName: '0981287110', isOwnedByMe: false).creatorLabel, isNull);
      expect(base.copyWith(createdByName: '+84981287110', isOwnedByMe: false).creatorLabel, isNull);
    });
  });
}

SalesOrderDraftDto _simple(String id, {int version = 1}) => _draft(
  draftId: id,
  version: version,
  savedAt: DateTime.utc(2026, 8, 1),
  savedByActorId: 'user-1',
  customer: null,
  lineCount: 1,
  totalMinor: 10000,
);

SalesDraftListCubit _cubit(FakeSalesDraftRepository fake) {
  return SalesDraftListCubit(
    repository: fake,
    executionContext: const _ExecutionContext(),
    activeStoreContext: const _ActiveStoreContext(),
  );
}

SalesOrderDraftDto _draft({
  required String draftId,
  required int version,
  required DateTime savedAt,
  required String savedByActorId,
  required CustomerSnapshotDto? customer,
  required int lineCount,
  required int totalMinor,
  String? orderNote,
  bool needsRevalidation = false,
}) {
  final lines = List<SalesOrderDraftLineDto>.generate(
    lineCount,
    (index) => SalesOrderDraftLineDto(
      lineId: '$draftId-line-$index',
      productId: 'prod-$index',
      productSku: 'SKU-$index',
      productName: 'SP $index',
      productUnitId: 'pu-$index',
      unitCode: 'U',
      unitName: 'Đơn vị',
      quantity: const QuantityDto(quantityMicros: 1000000),
      appliedUnitPrice: const MoneyDto(amountMinor: 10000, currencyCode: 'VND'),
      lineTotal: const MoneyDto(amountMinor: 10000, currencyCode: 'VND'),
    ),
  );
  return SalesOrderDraftDto(
    draftId: draftId,
    version: version,
    status: SalesDraftStatus.active,
    storeId: 'store-1',
    customer: customer,
    orderNote: orderNote,
    savedAt: savedAt,
    savedByActorId: savedByActorId,
    needsRevalidation: needsRevalidation,
    lines: lines,
    total: MoneyDto(amountMinor: totalMinor, currencyCode: 'VND'),
  );
}

FakeSalesDraftRepository _repo({
  required List<SalesOrderDraftDto> listItems,
  Object? cancelError,
  Object? listError,
  Duration? cancelDelay,
}) => FakeSalesDraftRepository()
  ..listItems = listItems
  ..cancelError = cancelError
  ..listError = listError
  ..cancelDelay = cancelDelay;

final class _ExecutionContext implements IExecutionContext {
  const _ExecutionContext();

  @override
  String get correlationId => 'corr-1';

  @override
  Future<String> requireTenantId() async => 'tenant-1';

  @override
  Future<String> requireUserId() async => 'user-1';
}

final class _ActiveStoreContext implements ISalesActiveStoreContext {
  const _ActiveStoreContext();

  @override
  String? get activeStoreId => 'store-1';

  @override
  Future<String> requireActiveStoreId() async => 'store-1';
}
