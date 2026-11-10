import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/inventory/data/core/inventory_error_codes.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_models.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_repository.dart';
import 'package:erp/features/inventory/logic/supplier_program/program_form_cubit.dart';
import 'package:erp/features/inventory/logic/supplier_program/program_form_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSupplierProgramRepository extends Mock
    implements SupplierProgramRepository {}

class FakeProgramPayload extends Fake implements ProgramPayload {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeProgramPayload());
  });

  group('ProgramFormCubit', () {
    late MockSupplierProgramRepository mockRepository;
    late int keySeq;

    const options = ProgramFormOptions(
      suppliers: [
        SupplierOption(
          partnerId: 'sup-overlap',
          displayName: 'NCC Trùng',
          activeProgram: (id: 'prog-active', name: 'Nobivac bậc SL'),
        ),
        SupplierOption(
          partnerId: 'sup-ok',
          displayName: 'NCC A',
        ),
      ],
      products: [
        ProductOption(
          productId: 'prod-1',
          name: 'Nobivac DHPPi',
          code: 'NOBI-01',
          baseUnitId: 'u-1',
          baseUom: 'hộp',
        ),
      ],
    );

    setUp(() {
      mockRepository = MockSupplierProgramRepository();
      keySeq = 0;
      when(() => mockRepository.formOptions()).thenAnswer((_) async => options);
    });

    test('form_prefill_supplier', () async {
      final cubit = ProgramFormCubit(repository: mockRepository);
      await cubit.startCreate(supplierId: 'sup-ok');

      expect(cubit.state.status, ProgramFormStatus.editing);
      expect(cubit.state.isEdit, isFalse);
      expect(cubit.state.draft.supplierId, 'sup-ok');
      expect(cubit.state.overlapping, isNull);
    });

    test('form_overlap_from_options', () async {
      final cubit = ProgramFormCubit(repository: mockRepository);
      await cubit.startCreate(supplierId: 'sup-overlap');

      expect(cubit.state.overlapping, isNotNull);
      expect(cubit.state.overlapping!.activeProgram!.id, 'prog-active');
      expect(
        cubit.state.overlapping!.activeProgram!.name,
        'Nobivac bậc SL',
      );
    });

    test('form_submit_invalid_no_rpc', () async {
      final cubit = ProgramFormCubit(repository: mockRepository);
      await cubit.startCreate();

      await cubit.submit();

      expect(cubit.state.showErrors, isTrue);
      expect(cubit.state.errors, isNotEmpty);
      verifyNever(
        () => mockRepository.create(
          idempotencyKey: any(named: 'idempotencyKey'),
          payload: any(named: 'payload'),
        ),
      );
    });

    test('submit_overlap_keeps_draft', () async {
      final cubit = ProgramFormCubit(repository: mockRepository);
      await cubit.startCreate(supplierId: 'sup-ok');
      cubit.update(
        (d) => d.copyWith(
          name: 'Chương trình mới',
          productIds: const ['prod-1'],
          tiers: const [(minQty: '100', percent: '3')],
        ),
      );
      final draftBefore = cubit.state.draft;

      when(
        () => mockRepository.create(
          idempotencyKey: any(named: 'idempotencyKey'),
          payload: any(named: 'payload'),
        ),
      ).thenThrow(
        const AppException(InventoryErrorCode.programOverlap),
      );

      await cubit.submit();

      expect(cubit.state.status, ProgramFormStatus.editing);
      expect(
        cubit.state.submitError,
        'NCC này đang có chương trình khác đang chạy. Kết thúc chương trình đó trước khi tạo chương trình mới.',
      );
      expect(cubit.state.draft.name, draftBefore.name);
      expect(cubit.state.draft.tiers, draftBefore.tiers);
    });

    test('form_submit_retry_same_key', () async {
      final cubit = ProgramFormCubit(
        repository: mockRepository,
        newKey: () => 'key-${++keySeq}',
      );
      await cubit.startCreate(supplierId: 'sup-ok');
      cubit.update(
        (d) => d.copyWith(
          name: 'Chương trình mới',
          productIds: const ['prod-1'],
          tiers: const [(minQty: '100', percent: '3')],
        ),
      );

      final capturedKeys = <String>[];
      var callCount = 0;
      when(
        () => mockRepository.create(
          idempotencyKey: any(named: 'idempotencyKey'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((inv) async {
        capturedKeys.add(inv.namedArguments[#idempotencyKey] as String);
        callCount++;
        if (callCount == 1) {
          throw const AppException(AppErrorCode.network);
        }
        return (id: 'prog-created', revision: 1);
      });

      await cubit.submit();
      expect(cubit.state.submitError, isNotNull);

      await cubit.submit();
      expect(capturedKeys, ['key-1', 'key-1']);
      expect(cubit.state.savedProgramId, 'prog-created');
    });

    test('form_edit_locked', () async {
      final lockedDetail = ProgramDetail(
        row: ProgramRow(
          id: 'p1',
          name: 'Bậc SL',
          supplierId: 'sup-ok',
          supplierName: 'NCC A',
          kind: ProgramKind.tierDiscount,
          status: ProgramStatus.active,
          startedOn: DateTime(2026, 11, 10),
          productIds: const ['prod-1'],
          productCount: 1,
          commonUom: 'hộp',
          tiers: const [ProgramTier(minQty: 100, discountPercent: 3)],
          progressQty: 0,
        ),
        revision: 1,
        isLocked: true,
        products: const [],
        receipts: const [],
        baseAmountVnd: 0,
      );

      when(() => mockRepository.get('p1')).thenAnswer((_) async => lockedDetail);

      final cubit = ProgramFormCubit(repository: mockRepository);
      await cubit.startEdit('p1');

      expect(cubit.state.isEdit, isTrue);
      expect(cubit.state.status, ProgramFormStatus.locked);
    });

    test('form_version_conflict_flag', () async {
      final editableDetail = ProgramDetail(
        row: ProgramRow(
          id: 'p1',
          name: 'Bậc SL',
          supplierId: 'sup-ok',
          supplierName: 'NCC A',
          kind: ProgramKind.tierDiscount,
          status: ProgramStatus.active,
          startedOn: DateTime(2026, 11, 10),
          productIds: const ['prod-1'],
          productCount: 1,
          commonUom: 'hộp',
          tiers: const [ProgramTier(minQty: 100, discountPercent: 3)],
          progressQty: 0,
        ),
        revision: 2,
        isLocked: false,
        products: const [],
        receipts: const [],
        baseAmountVnd: 0,
      );

      when(() => mockRepository.get('p1'))
          .thenAnswer((_) async => editableDetail);
      when(
        () => mockRepository.update(
          idempotencyKey: any(named: 'idempotencyKey'),
          id: 'p1',
          expectedRevision: 2,
          payload: any(named: 'payload'),
        ),
      ).thenThrow(
        const AppException(InventoryErrorCode.versionConflict),
      );

      final cubit = ProgramFormCubit(repository: mockRepository);
      await cubit.startEdit('p1');
      cubit.update((d) => d.copyWith(name: 'Bậc SL mới'));
      await cubit.submit();

      expect(cubit.state.versionConflict, isTrue);
      expect(
        cubit.state.submitError,
        'Chương trình đã được sửa ở nơi khác. Tải lại để xem bản mới.',
      );
    });
  });
}
