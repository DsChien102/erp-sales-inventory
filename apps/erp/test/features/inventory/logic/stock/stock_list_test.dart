import 'dart:async';

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/inventory/data/stock/stock_models.dart';
import 'package:erp/features/inventory/data/stock/stock_repository.dart';
import 'package:erp/features/inventory/logic/stock/stale_watcher.dart';
import 'package:erp/features/inventory/logic/stock/stock_detail_cubit.dart';
import 'package:erp/features/inventory/logic/stock/stock_detail_state.dart';
import 'package:erp/features/inventory/logic/stock/stock_list_cubit.dart';
import 'package:erp/features/inventory/logic/stock/stock_list_rules.dart';
import 'package:erp/features/inventory/logic/stock/stock_list_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockStockRepository extends Mock implements StockRepository {}

List<StockOverviewItem> _fixtureProducts() => const [
      StockOverviewItem(
        productId: 'INV-NOB',
        name: 'Nobivac DHPPi',
        code: 'SP-000184',
        barcode: '8938500001012',
        uom: 'hộp',
        isLotTracked: true,
        physical: 120,
        available: 118,
        hasExpired: false,
        hasNearExpiry: true,
        threshold: 30,
      ),
      StockOverviewItem(
        productId: 'INV-AMX',
        name: 'Amox 500',
        code: 'SP-000066',
        barcode: '8938500004068',
        uom: 'hộp',
        isLotTracked: false,
        physical: 48,
        available: 46,
        hasExpired: false,
        hasNearExpiry: false,
        threshold: 50,
      ),
      StockOverviewItem(
        productId: 'INV-ENRO',
        name: 'Enrofloxacin 10%',
        code: 'SP-000091',
        barcode: '8938500005096',
        uom: 'chai',
        isLotTracked: false,
        physical: 0,
        available: 0,
        hasExpired: false,
        hasNearExpiry: false,
        threshold: 10,
      ),
      StockOverviewItem(
        productId: 'INV-TYLO',
        name: 'Tylosin 20%',
        code: 'SP-000122',
        barcode: '8938500006123',
        uom: 'lọ',
        isLotTracked: true,
        physical: 14,
        available: 3,
        hasExpired: true,
        hasNearExpiry: false,
        threshold: 8,
      ),
      StockOverviewItem(
        productId: 'INV-OXY',
        name: 'Oxytetracycline LA',
        code: 'SP-000147',
        barcode: '8938500007144',
        uom: 'chai',
        isLotTracked: false,
        physical: 12,
        available: 11,
        hasExpired: false,
        hasNearExpiry: false,
        threshold: null,
      ),
    ];

StockOverview _fixtureOverview({DateTime? asOf}) => StockOverview(
      asOf: asOf ?? DateTime(2026, 9, 17, 21, 30),
      warehouseName: 'Kho trung tâm',
      products: _fixtureProducts(),
    );

void main() {
  late _MockStockRepository mockRepository;

  setUp(() {
    mockRepository = _MockStockRepository();
  });

  group('stock_list_rules', () {
    test('all_sorted_by_urgency', () {
      final visible = visibleProducts(
        _fixtureProducts(),
        StockFilter.all,
        '',
      );
      expect(
        visible.map((p) => p.productId).toList(),
        ['INV-ENRO', 'INV-TYLO', 'INV-AMX', 'INV-NOB', 'INV-OXY'],
      );
    });

    test('chip_counts_ignore_search', () async {
      when(() => mockRepository.loadOverview())
          .thenAnswer((_) async => _fixtureOverview());
      final cubit = StockListCubit(repository: mockRepository);
      await cubit.load();
      cubit.setQuery('amox');

      expect(cubit.state.visible, hasLength(1));
      expect(filterCount(_fixtureProducts(), StockFilter.low), 2);
      expect(filterCount(_fixtureProducts(), StockFilter.all), 5);
    });

    test('search_matches_barcode', () {
      final visible = visibleProducts(
        _fixtureProducts(),
        StockFilter.all,
        '8938500004068',
      );
      expect(visible.map((p) => p.productId).toList(), ['INV-AMX']);
    });

    test('filter_keeps_original_order', () {
      // In original list: INV-AMX is at index 1, INV-TYLO is at index 3 (both have LOW indicator)
      final visible = visibleProducts(
        _fixtureProducts(),
        StockFilter.low,
        '',
      );
      expect(
        visible.map((p) => p.productId).toList(),
        ['INV-AMX', 'INV-TYLO'],
      );
    });
  });

  group('StockListCubit & StaleWatcher', () {
    test('empty_status_when_no_products', () async {
      when(() => mockRepository.loadOverview()).thenAnswer(
        (_) async => StockOverview(
          asOf: DateTime(2026, 9, 17, 21, 30),
          warehouseName: 'Kho trung tâm',
          products: const [],
        ),
      );
      final cubit = StockListCubit(repository: mockRepository);
      await cubit.load();
      expect(cubit.state.status, StockListStatus.empty);
    });

    test('denied_on_no_permission', () async {
      when(() => mockRepository.loadOverview()).thenThrow(
        const AppException('PERMISSION_DENIED', serverMessage: 'Denied'),
      );
      final cubit = StockListCubit(repository: mockRepository);
      await cubit.load();
      expect(cubit.state.status, StockListStatus.denied);
    });

    test('stale_after_five_minutes_on_resume', () async {
      final baseTime = DateTime(2026, 9, 17, 21, 30);
      var currentNow = baseTime;
      final watcher = StaleWatcher(now: () => currentNow);

      when(() => mockRepository.loadOverview())
          .thenAnswer((_) async => _fixtureOverview(asOf: baseTime));

      final cubit = StockListCubit(
        repository: mockRepository,
        stale: watcher,
      );
      await cubit.load();
      expect(cubit.state.stale, isFalse);

      // +4 minutes -> false
      currentNow = baseTime.add(const Duration(minutes: 4));
      cubit.checkStale();
      expect(cubit.state.stale, isFalse);

      // +5 minutes 1 second -> true
      currentNow = baseTime.add(const Duration(minutes: 5, seconds: 1));
      cubit.checkStale();
      expect(cubit.state.stale, isTrue);
    });

    test('refresh_clears_stale_and_keeps_filter', () async {
      final baseTime = DateTime(2026, 9, 17, 21, 30);
      var currentNow = baseTime.add(const Duration(minutes: 6));
      var asOfToReturn = baseTime;

      when(() => mockRepository.loadOverview())
          .thenAnswer((_) async => _fixtureOverview(asOf: asOfToReturn));

      final cubit = StockListCubit(
        repository: mockRepository,
        stale: StaleWatcher(now: () => currentNow),
      );
      await cubit.load();
      cubit.setFilter(StockFilter.low);
      cubit.checkStale();
      expect(cubit.state.stale, isTrue);

      asOfToReturn = currentNow;
      await cubit.refresh();
      expect(cubit.state.stale, isFalse);
      expect(cubit.state.filter, StockFilter.low);
    });

    test('selected_falls_back_to_first_visible', () async {
      when(() => mockRepository.loadOverview())
          .thenAnswer((_) async => _fixtureOverview());
      final cubit = StockListCubit(repository: mockRepository);
      await cubit.load();

      // Default selected is first visible in ALL (INV-ENRO)
      expect(cubit.state.selected?.productId, 'INV-ENRO');

      // Select INV-AMX
      cubit.select('INV-AMX');
      expect(cubit.state.selected?.productId, 'INV-AMX');

      // Filter by EXPIRED -> INV-AMX is hidden, falls back to first visible (INV-TYLO)
      cubit.setFilter(StockFilter.expired);
      expect(cubit.state.selected?.productId, 'INV-TYLO');
    });
  });

  group('StockDetailCubit', () {
    test('detail_load_and_refresh', () async {
      final baseTime = DateTime(2026, 9, 17, 21, 30);
      var currentNow = baseTime;
      var asOfToReturn = baseTime;

      when(() => mockRepository.loadDetail('INV-NOB')).thenAnswer(
        (_) async => StockDetail(
          asOf: asOfToReturn,
          warehouseName: 'Kho trung tâm',
          isOwner: true,
          productId: 'INV-NOB',
          name: 'Nobivac DHPPi',
          code: 'SP-000184',
          uom: 'hộp',
          isLotTracked: true,
          physical: 120,
          available: 118,
          expiredQuantity: 0,
        ),
      );

      final cubit = StockDetailCubit(
        repository: mockRepository,
        stale: StaleWatcher(now: () => currentNow),
      );
      await cubit.load('INV-NOB');
      expect(cubit.state.status, StockDetailStatus.ready);
      expect(cubit.state.data?.productId, 'INV-NOB');
      expect(cubit.state.stale, isFalse);

      currentNow = baseTime.add(const Duration(minutes: 6));
      cubit.checkStale();
      expect(cubit.state.stale, isTrue);

      asOfToReturn = currentNow;
      await cubit.refresh();
      expect(cubit.state.stale, isFalse);
      expect(cubit.state.data?.asOf, currentNow);
    });

    StockDetail detailOf(String id) => StockDetail(
          asOf: DateTime(2026, 9, 17, 21, 30),
          warehouseName: 'Kho trung tâm',
          isOwner: true,
          productId: id,
          name: 'SP $id',
          code: id,
          uom: 'hộp',
          isLotTracked: false,
          physical: 1,
          available: 1,
          expiredQuantity: 0,
        );

    test('load_other_product_clears_old_data', () async {
      final pendingB = Completer<StockDetail>();
      when(() => mockRepository.loadDetail('A'))
          .thenAnswer((_) async => detailOf('A'));
      when(() => mockRepository.loadDetail('B'))
          .thenAnswer((_) => pendingB.future);

      final cubit = StockDetailCubit(repository: mockRepository);
      await cubit.load('A');
      expect(cubit.state.data?.productId, 'A');

      final loadingB = cubit.load('B');
      expect(cubit.state.status, StockDetailStatus.loading);
      expect(cubit.state.productId, 'B');
      expect(cubit.state.data, isNull);

      pendingB.complete(detailOf('B'));
      await loadingB;
      expect(cubit.state.data?.productId, 'B');
    });

    test('late_response_ignored', () async {
      final pendingA = Completer<StockDetail>();
      when(() => mockRepository.loadDetail('A'))
          .thenAnswer((_) => pendingA.future);
      when(() => mockRepository.loadDetail('B'))
          .thenAnswer((_) async => detailOf('B'));

      final cubit = StockDetailCubit(repository: mockRepository);
      final loadingA = cubit.load('A');
      await cubit.load('B');
      expect(cubit.state.data?.productId, 'B');

      pendingA.complete(detailOf('A'));
      await loadingA;
      expect(cubit.state.status, StockDetailStatus.ready);
      expect(cubit.state.data?.productId, 'B');
    });
  });
}
