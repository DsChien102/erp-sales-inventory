import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/inventory/data/core/inventory_error_codes.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_models.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_repository.dart';
import 'package:erp/features/inventory/logic/supplier_program/program_detail_cubit.dart';
import 'package:erp/features/inventory/logic/supplier_program/program_detail_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSupplierProgramRepository extends Mock
    implements SupplierProgramRepository {}

void main() {
  group('ProgramDetailCubit', () {
    late MockSupplierProgramRepository mockRepository;

    ProgramDetail buildDetail({
      required ProgramStatus status,
      required bool isLocked,
      int revision = 1,
    }) {
      return ProgramDetail(
        row: ProgramRow(
          id: 'p1',
          name: 'Mốc 1.000 hộp Q4',
          supplierId: 'sup-1',
          supplierName: 'NCC A',
          kind: ProgramKind.volumeRebate,
          status: status,
          startedOn: DateTime(2026, 11, 10),
          productIds: const ['prod-1'],
          productCount: 1,
          commonUom: 'hộp',
          tiers: const [],
          targetQty: 1000,
          rebatePercent: 5,
          progressQty: 400,
        ),
        revision: revision,
        isLocked: isLocked,
        products: const [],
        receipts: const [],
        baseAmountVnd: 40000000,
      );
    }

    setUp(() {
      mockRepository = MockSupplierProgramRepository();
    });

    test('detail_can_edit_end_matrix', () {
      for (final status in ProgramStatus.values) {
        for (final isLocked in [false, true]) {
          final st = ProgramDetailState(
            status: ProgramDetailStatus.ready,
            data: buildDetail(status: status, isLocked: isLocked),
          );
          final isEffective =
              status == ProgramStatus.active || status == ProgramStatus.reached;
          expect(
            st.canEdit,
            isEffective && !isLocked,
            reason: 'canEdit for $status / locked=$isLocked',
          );
          expect(
            st.canEnd,
            isEffective,
            reason: 'canEnd for $status / locked=$isLocked',
          );
        }
      }
    });

    test('detail_end_reloads', () async {
      final activeDetail = buildDetail(
        status: ProgramStatus.active,
        isLocked: false,
        revision: 1,
      );
      final endedDetail = buildDetail(
        status: ProgramStatus.ended,
        isLocked: false,
        revision: 2,
      );

      var getCalls = 0;
      when(() => mockRepository.get('p1')).thenAnswer((_) async {
        getCalls++;
        return getCalls == 1 ? activeDetail : endedDetail;
      });
      when(
        () => mockRepository.end(
          idempotencyKey: any(named: 'idempotencyKey'),
          id: 'p1',
          expectedRevision: 1,
        ),
      ).thenAnswer((_) async => 2);

      final cubit = ProgramDetailCubit(repository: mockRepository);
      await cubit.load('p1');
      expect(cubit.state.data!.row.status, ProgramStatus.active);

      final ok = await cubit.end();
      expect(ok, isTrue);
      expect(cubit.state.data!.row.status, ProgramStatus.ended);
      expect(cubit.state.data!.revision, 2);
    });

    test('detail_not_found_on_context_invalid', () async {
      when(() => mockRepository.get('missing')).thenThrow(
        const AppException(InventoryErrorCode.contextInvalid),
      );

      final cubit = ProgramDetailCubit(repository: mockRepository);
      await cubit.load('missing');

      expect(cubit.state.status, ProgramDetailStatus.notFound);
    });
  });
}
