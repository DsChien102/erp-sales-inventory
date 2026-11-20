import 'package:erp/features/inventory/data/supplier_program/supplier_program_models.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_repository.dart';
import 'package:erp/features/inventory/logic/supplier_program/program_list_cubit.dart';
import 'package:erp/features/inventory/logic/supplier_program/program_list_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSupplierProgramRepository extends Mock
    implements SupplierProgramRepository {}

void main() {
  group('ProgramListCubit', () {
    late MockSupplierProgramRepository mockRepository;

    final rowActive = ProgramRow(
      id: 'p1',
      name: 'Nobivac bậc SL',
      supplierId: 'sup-1',
      supplierName: 'Cty Thú Y Á Châu',
      kind: ProgramKind.tierDiscount,
      status: ProgramStatus.active,
      startedOn: DateTime(2026, 11, 10),
      productIds: const ['prod-1'],
      productCount: 1,
      commonUom: 'hộp',
      tiers: const [ProgramTier(minQty: 100, discountPercent: 3)],
      progressQty: 0,
    );

    final rowReached = ProgramRow(
      id: 'p2',
      name: 'Mốc 1.000 hộp Q4',
      supplierId: 'sup-2',
      supplierName: 'NCC A',
      kind: ProgramKind.volumeRebate,
      status: ProgramStatus.reached,
      startedOn: DateTime(2026, 10, 1),
      productIds: const ['prod-1', 'prod-2'],
      productCount: 2,
      commonUom: 'hộp',
      tiers: const [],
      targetQty: 1000,
      rebatePercent: 5,
      progressQty: 1000,
    );

    final rowEnded = ProgramRow(
      id: 'p3',
      name: 'Mua 10 tặng 1',
      supplierId: 'sup-1',
      supplierName: 'Cty Thú Y Á Châu',
      kind: ProgramKind.buyXGetY,
      status: ProgramStatus.ended,
      startedOn: DateTime(2026, 9, 1),
      productIds: const ['prod-2'],
      productCount: 1,
      commonUom: 'hộp',
      tiers: const [],
      buyQty: 10,
      freeQty: 1,
      progressQty: 0,
    );

    const options = ProgramFormOptions(
      suppliers: [
        SupplierOption(partnerId: 'sup-1', displayName: 'Cty Thú Y Á Châu'),
        SupplierOption(partnerId: 'sup-2', displayName: 'NCC A'),
      ],
      products: [
        ProductOption(
          productId: 'prod-1',
          name: 'Nobivac DHPPi',
          code: 'NOBI-01',
          baseUnitId: 'u-1',
          baseUom: 'hộp',
        ),
        ProductOption(
          productId: 'prod-2',
          name: 'Nobivac Rabies',
          code: 'NOBI-02',
          baseUnitId: 'u-1',
          baseUom: 'hộp',
        ),
      ],
    );

    setUp(() {
      mockRepository = MockSupplierProgramRepository();
      when(() => mockRepository.list()).thenAnswer(
        (_) async => [rowActive, rowReached, rowEnded],
      );
      when(() => mockRepository.formOptions()).thenAnswer((_) async => options);
    });

    test('list_default_active_filter', () async {
      final cubit = ProgramListCubit(repository: mockRepository);
      await cubit.load();

      expect(cubit.state.status, ProgramListStatus.ready);
      expect(cubit.state.statusFilter, ProgramStatus.active);
      expect(cubit.state.visible.map((e) => e.id).toList(), ['p1']);
    });

    test('list_counts_ignore_status_filter', () async {
      final cubit = ProgramListCubit(repository: mockRepository);
      await cubit.load();

      expect(cubit.state.count(ProgramStatus.active), 1);
      expect(cubit.state.count(ProgramStatus.reached), 1);
      expect(cubit.state.count(ProgramStatus.recorded), 0);
      expect(cubit.state.count(ProgramStatus.ended), 1);

      cubit.setStatus(ProgramStatus.ended);
      expect(cubit.state.count(ProgramStatus.active), 1);
      expect(cubit.state.count(ProgramStatus.reached), 1);
      expect(cubit.state.count(ProgramStatus.ended), 1);

      cubit.setSupplier('sup-1');
      expect(cubit.state.count(ProgramStatus.active), 1);
      expect(cubit.state.count(ProgramStatus.reached), 0);
      expect(cubit.state.count(ProgramStatus.ended), 1);
    });

    test('list_query_matches_unaccented', () async {
      final cubit = ProgramListCubit(repository: mockRepository);
      await cubit.load();

      cubit.setQuery('nobivac bac');
      expect(cubit.state.visible.map((e) => e.id).toList(), ['p1']);
    });

    test('list_initial_supplier_filter', () async {
      final cubit = ProgramListCubit(
        repository: mockRepository,
        initialSupplierId: 'sup-2',
      );
      await cubit.load();

      expect(cubit.state.supplierId, 'sup-2');
      expect(cubit.state.count(ProgramStatus.active), 0);
      expect(cubit.state.count(ProgramStatus.reached), 1);
    });

    test('list_clear_keeps_status', () async {
      final cubit = ProgramListCubit(repository: mockRepository);
      await cubit.load();

      cubit
        ..setStatus(ProgramStatus.ended)
        ..setSupplier('sup-2')
        ..setProduct('prod-1')
        ..setQuery('abc')
        ..clearFilters();

      expect(cubit.state.statusFilter, ProgramStatus.ended);
      expect(cubit.state.supplierId, isNull);
      expect(cubit.state.productId, isNull);
      expect(cubit.state.query, '');
    });

    test('list_empty_vs_filter_empty', () async {
      final cubit = ProgramListCubit(repository: mockRepository);
      await cubit.load();

      expect(cubit.state.status, ProgramListStatus.ready);
      expect(cubit.state.filterEmpty, isFalse);

      cubit.setStatus(ProgramStatus.recorded);
      expect(cubit.state.visible, isEmpty);
      expect(cubit.state.filterEmpty, isTrue);

      when(() => mockRepository.list()).thenAnswer((_) async => const []);
      await cubit.load();
      expect(cubit.state.status, ProgramListStatus.empty);
      expect(cubit.state.filterEmpty, isFalse);
    });
  });
}

