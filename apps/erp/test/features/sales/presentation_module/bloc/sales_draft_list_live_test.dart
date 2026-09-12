import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:erp/features/sales/presentation.dart';
import 'package:vet45_shared_application/application.dart';

void main() {
  group('SalesDraftListCubit live list/cancel', () {
    test('load queries active store and maps server draft fields', () async {
      final module = _RecordingSalesModule(
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
      final cubit = _cubit(module);
      addTearDown(cubit.close);

      await cubit.load(isRefresh: true);

      expect(module.queries, hasLength(1));
      final query = module.queries.single as ListSalesOrderDraftsQuery;
      expect(query.storeId, 'store-1');
      expect(query.tenantId, 'tenant-1');
      expect(query.actorId, 'user-1');

      final loaded = cubit.state as SalesDraftListLoaded;
      expect(loaded.items, hasLength(2));

      final named = loaded.items.firstWhere((e) => e.draftId == 'draft-server-1');
      expect(named.updatedAt, DateTime.utc(2026, 8, 1, 9, 15));
      expect(named.customerLabel, 'Nguyễn Văn A');
      expect(named.phone, '0901 111 222');
      expect(named.note, 'Giao chiều');
      expect(named.createdByName, 'user-1');
      expect(named.isOwnedByMe, isTrue);
      expect(named.lineCount, 2);
      expect(named.total.amountMinor, 250000);
      expect(named.uiStatus, SalesDraftUiStatus.needsCheck);
      expect(named.version, 3);

      final walkIn = loaded.items.firstWhere((e) => e.draftId == 'draft-walk-in');
      expect(walkIn.customerLabel, 'Khách lẻ');
      expect(walkIn.phone, isNull);
      expect(walkIn.note, isNull);
      expect(walkIn.createdByName, 'user-2');
      expect(walkIn.isOwnedByMe, isFalse);
      expect(walkIn.lineCount, 0);
      expect(walkIn.uiStatus, SalesDraftUiStatus.composing);
    });

    test('totalCount ignores scope and keyword filters', () async {
      final module = _RecordingSalesModule(
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
      final cubit = _cubit(module);
      addTearDown(cubit.close);

      await cubit.load(isRefresh: true);
      expect(cubit.state.totalCount, 2);

      // Cubit giữ toàn bộ rows; scope lọc ở SalesDraftListBody theo displayScope.
      expect((cubit.state as SalesDraftListLoaded).items, hasLength(2));

      await cubit.searchByKeyword('Khách A');
      expect((cubit.state as SalesDraftListLoaded).items, hasLength(1));
      expect(cubit.state.totalCount, 2);

      cubit.clearSearch();
      await cubit.discardDraft('draft-other', expectedVersion: 1);
      expect(cubit.state.totalCount, 1);
    });

    test('concurrent load calls issue a single query', () async {
      final module = _RecordingSalesModule(listItems: const []);
      final cubit = _cubit(module);
      addTearDown(cubit.close);

      await Future.wait([cubit.load(), cubit.load()]);

      expect(module.queries.whereType<ListSalesOrderDraftsQuery>(), hasLength(1));
    });

    test(
      'discardDraft sends cancel with version/store/idempotency and removes on success',
      () async {
        final module = _RecordingSalesModule(
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
        final cubit = _cubit(module);
        addTearDown(cubit.close);

        await cubit.load(isRefresh: true);
        final ok = await cubit.discardDraft(
          'draft-cancel-ok',
          expectedVersion: 4,
        );

        expect(ok, isTrue);
        expect(module.commands, hasLength(1));
        final command = module.commands.single as CancelSalesOrderDraftCommand;
        expect(command.draftId, 'draft-cancel-ok');
        expect(command.storeId, 'store-1');
        expect(command.expectedVersion, 4);
        expect(command.tenantId, 'tenant-1');
        expect(command.actorId, 'user-1');
        expect(command.idempotencyKey, isNotEmpty);
        expect(command.idempotencyKey, contains('draft-cancel-ok'));

        final loaded = cubit.state as SalesDraftListLoaded;
        expect(loaded.items, isEmpty);
        expect(loaded.needsReload, isFalse);
        expect(loaded.discardingDraftId, isNull);
      },
    );

    test('failed cancel retains row and clears in-flight id', () async {
      final module = _RecordingSalesModule(
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
        cancelError: const SalesContractException(
          'REFERENCE_UNAVAILABLE',
          message: 'Không hủy được đơn nháp',
        ),
      );
      final cubit = _cubit(module);
      addTearDown(cubit.close);

      await cubit.load(isRefresh: true);
      final ok = await cubit.discardDraft('draft-fail', expectedVersion: 2);

      expect(ok, isFalse);
      final loaded = cubit.state as SalesDraftListLoaded;
      expect(loaded.items, hasLength(1));
      expect(loaded.items.single.draftId, 'draft-fail');
      expect(loaded.needsReload, isFalse);
      expect(loaded.discardingDraftId, isNull);
      expect(loaded.actionMessage, contains('Không hủy được'));
    });

    test('stale cancel retains row and reports reload-needed', () async {
      final module = _RecordingSalesModule(
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
        cancelError: const SalesContractException(
          'STALE_DATA',
          message: 'Đơn nháp đã thay đổi',
        ),
      );
      final cubit = _cubit(module);
      addTearDown(cubit.close);

      await cubit.load(isRefresh: true);
      final ok = await cubit.discardDraft('draft-stale', expectedVersion: 5);

      expect(ok, isFalse);
      final loaded = cubit.state as SalesDraftListLoaded;
      expect(loaded.items, hasLength(1));
      expect(loaded.items.single.draftId, 'draft-stale');
      expect(loaded.needsReload, isTrue);
      expect(loaded.discardingDraftId, isNull);
      expect(loaded.actionMessage, isNotNull);
    });

    test('duplicate discard while in-flight is ignored', () async {
      final module = _RecordingSalesModule(
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
      final cubit = _cubit(module);
      addTearDown(cubit.close);

      await cubit.load(isRefresh: true);
      final first = cubit.discardDraft('draft-inflight', expectedVersion: 1);
      final second = cubit.discardDraft('draft-inflight', expectedVersion: 1);
      final results = await Future.wait([first, second]);

      expect(module.commands, hasLength(1));
      expect(results, containsAll([isTrue, isFalse]));
      expect(results.where((ok) => ok).length, 1);
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
      expect(base.copyWith(createdByName: '3adba8f1-3fa6-4b2f-893e-5fa321abcdef', isOwnedByMe: true).creatorLabel, isNull);
      expect(base.copyWith(createdByName: '3adba8f1-3fa6-4b2f-893e-5fa321abcdef', isOwnedByMe: false).creatorLabel, isNull);
      expect(base.copyWith(createdByName: '0981287110', isOwnedByMe: true).creatorLabel, isNull);
      expect(base.copyWith(createdByName: '0981287110', isOwnedByMe: false).creatorLabel, isNull);
      expect(base.copyWith(createdByName: '+84981287110', isOwnedByMe: false).creatorLabel, isNull);
    });

    test('SalesDraftListCubit resolves actor name using actorNameResolver', () async {
      final module = _RecordingSalesModule(
        listItems: [
          _draft(
            draftId: 'draft-named',
            version: 1,
            savedAt: DateTime.utc(2026, 8, 1),
            savedByActorId: 'user-1',
            customer: null,
            lineCount: 1,
            totalMinor: 10000,
          ),
          _draft(
            draftId: 'draft-email',
            version: 1,
            savedAt: DateTime.utc(2026, 8, 2),
            savedByActorId: 'user-2',
            customer: null,
            lineCount: 1,
            totalMinor: 10000,
          ),
        ],
      );

      final cubit = SalesDraftListCubit(
        salesModule: module,
        executionContext: const _ExecutionContext(),
        activeStoreContext: const _ActiveStoreContext(),
        actorNameResolver: (actorId) async {
          if (actorId == 'user-1') return 'Nguyễn Văn An';
          if (actorId == 'user-2') return 'user2@example.com';
          return null;
        },
      );
      addTearDown(cubit.close);

      await cubit.load(isRefresh: true);
      final loaded = cubit.state as SalesDraftListLoaded;

      final item1 = loaded.items.firstWhere((e) => e.draftId == 'draft-named');
      expect(item1.createdByName, 'Nguyễn Văn An');
      expect(item1.creatorLabel, 'Nguyễn Văn An');

      final item2 = loaded.items.firstWhere((e) => e.draftId == 'draft-email');
      expect(item2.createdByName, 'user2@example.com');
      expect(item2.creatorLabel, 'user2@example.com');
    });
  });
}

SalesDraftListCubit _cubit(_RecordingSalesModule module) {
  return SalesDraftListCubit(
    salesModule: module,
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

final class _RecordingSalesModule implements ISalesModule {
  _RecordingSalesModule({
    required this.listItems,
    this.cancelError,
    this.cancelDelay,
  });

  final List<SalesOrderDraftDto> listItems;
  final Object? cancelError;
  final Duration? cancelDelay;
  final List<Object> queries = <Object>[];
  final List<Object> commands = <Object>[];

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) async {
    commands.add(command);
    final delay = cancelDelay;
    if (delay != null) {
      await Future<void>.delayed(delay);
    }
    final error = cancelError;
    if (error != null) {
      throw error;
    }
    final cancel = command as CancelSalesOrderDraftCommand;
    return _draft(
          draftId: cancel.draftId,
          version: cancel.expectedVersion + 1,
          savedAt: DateTime.utc(2026, 8, 7),
          savedByActorId: 'user-1',
          customer: null,
          lineCount: 0,
          totalMinor: 0,
        )
        as TResult;
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    queries.add(query);
    if (query is ListSalesOrderDraftsQuery) {
      return PagedSalesOrderDraftListDto(
            page: OpaqueCursorPageDto<SalesOrderDraftDto>(
              items: listItems,
              hasMore: false,
            ),
          )
          as TResult;
    }
    throw StateError('Unexpected query $query');
  }
}

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
