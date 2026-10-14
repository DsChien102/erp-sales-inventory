import 'package:erp/core/di/injection.dart';
import 'package:erp/features/inventory/data/models/valuation_cost_source.dart';
import 'package:erp/features/inventory/data/models/valuation_direct_basis_draft.dart';
import 'package:erp/features/inventory/data/valuation_repository.dart';
import 'package:erp/features/inventory/logic/valuation_session_cubit.dart';
import 'package:erp/features/inventory/presentation/pages/valuation_queue_page.dart';
import 'package:erp/features/inventory/presentation/pages/valuation_result_page.dart';
import 'package:erp/features/inventory/presentation/pages/valuation_review_page.dart';
import 'package:erp/features/inventory/presentation/pages/valuation_workspace_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

void main() {
  setUp(() async {
    await getIt.reset();
    getIt.registerLazySingleton<ValuationRepository>(() => ValuationRepository());
  });

  tearDown(() async {
    await getIt.reset();
  });
  group('BJ-03 Receipt Valuation Logic & Calculation', () {
    test('Cost composition formula calculates correct actual unit price', () {
      const source = ValuationCostSource(
        id: 'PO-1',
        label: 'PO Test',
        unitPrice: 100000,
        fxRate: 1.0,
        unitLineDiscount: 5000,
        unitDocDiscount: 2000,
        unitKnownCost: 3000,
        unitNonDeductibleVat: 1000,
      );

      // Formula: 100000 - 5000 - 2000 + 3000 + 1000 = 97000
      expect(source.unitActual, 97000);
    });

    test('ValuationRepository filters and saves direct basis for Quick Receipt',
        () async {
      final repo = ValuationRepository();

      // Check queue
      final allQueue = await repo.getQueue();
      expect(allQueue.length, 4);

      final readyQueue = await repo.getQueue(filter: 'READY');
      expect(readyQueue.any((r) => r.id == 'VAL03-R1'), isFalse);
      expect(readyQueue.any((r) => r.id == 'VAL03-R3'), isTrue);

      // Check quick receipt VAL03-R2
      final r2 = await repo.getReceiptValuation('VAL03-R2');
      expect(r2.groups.first.unitActual, isNull);

      // Save direct basis
      final updatedR2 = await repo.saveDirectBasis(
        receiptId: 'VAL03-R2',
        groupId: 'VAL03-G3',
        draft: ValuationDirectBasisDraft(
          unitPrice: 50000,
          taxMode: ValuationTaxMode.excluded,
          taxAmount: 5000,
          source: 'Báo giá nhà cung cấp',
          date: DateTime(2026, 9, 24),
          reason: 'Hàng nhập nhanh thiếu PO',
        ),
      );

      expect(updatedR2.groups.first.unitActual, 55000);
      expect(updatedR2.groups.first.isSelected, isTrue);

      // Confirm valuation
      final result = await repo.confirmValuation(
        receiptId: 'VAL03-R2',
        selectedGroupIds: ['VAL03-G3'],
      );

      expect(result.lines.length, 1);
      expect(result.totalValue, 55000 * 50);
      expect(result.remainingPendingCount, 0);
    });
  });

  group('BJ-03 UI Pages & Interactions', () {
    testWidgets('ValuationQueuePage (SCR-014) renders queue and filter chips',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: const ValuationQueuePage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hàng chờ xác lập giá trị'), findsOneWidget);
      expect(find.text('Tất cả'), findsOneWidget);
      expect(find.text('Có thể xác lập'), findsOneWidget);
      expect(find.text('Cần xử lý'), findsOneWidget);

      expect(find.text('PN-260816-04'), findsOneWidget);
      expect(find.text('Cần đối chiếu'), findsOneWidget);
    });

    testWidgets(
        'ValuationWorkspacePage (SCR-015) renders groups and selection summary',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = ValuationRepository();
      final cubit = ValuationSessionCubit(repository: repo);
      addTearDown(cubit.close);

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: BlocProvider.value(
            value: cubit,
            child: const ValuationWorkspacePage(receiptId: 'VAL03-R1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Xác lập giá trị nhập ban đầu'), findsOneWidget);
      expect(find.text('PN-260816-04'), findsOneWidget);
      expect(find.text('Nobivac DHPPi'), findsOneWidget);
      expect(find.text('Amoxicillin LA'), findsOneWidget);
      expect(find.text('Cần đối chiếu'), findsOneWidget);

      // Select ready group
      await tester.tap(find.text('Nobivac DHPPi'));
      await tester.pumpAndSettle();

      expect(find.text('Đã chọn 1 dòng'), findsOneWidget);
      expect(find.text('Rà soát'), findsOneWidget);
    });

    testWidgets('ValuationReviewPage (SCR-017) renders review summary',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = ValuationRepository();
      final cubit = ValuationSessionCubit(repository: repo);
      addTearDown(cubit.close);

      await cubit.loadReceipt('VAL03-R3');
      cubit.toggleGroupSelection('VAL03-G4');
      cubit.prepareReview();

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: BlocProvider.value(
            value: cubit,
            child: const ValuationReviewPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Rà soát giá trị nhập ban đầu'), findsOneWidget);
      expect(find.text('Vaccine Canine X'), findsOneWidget);
      expect(find.text('Giá trị sẽ ghi'), findsOneWidget);
      expect(find.text('Tổng giá trị nhập ban đầu'), findsOneWidget);
      expect(find.text('Xác nhận giá trị'), findsOneWidget);
    });

    testWidgets('ValuationResultPage (SCR-019) renders result hero and note',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = ValuationRepository();
      final cubit = ValuationSessionCubit(repository: repo);
      addTearDown(cubit.close);

      await cubit.loadReceipt('VAL03-R1');
      cubit.toggleGroupSelection('VAL03-G1');
      await cubit.confirmValuation();

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: BlocProvider.value(
            value: cubit,
            child: const ValuationResultPage(receiptId: 'VAL03-R1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Đã xác lập giá trị nhập ban đầu'), findsOneWidget);
      expect(find.text('Cần cập nhật'), findsOneWidget);
      expect(find.text('Còn hàng chờ giá trị'), findsOneWidget);
      expect(find.text('Tiếp tục xử lý'), findsOneWidget);
    });
  });
}
