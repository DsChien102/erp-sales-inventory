import 'dart:typed_data';

import 'package:erp/features/pricing/presentation/services/pricing_import_file_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_application/testing.dart';
import 'package:vet45_pricing_presentation/presentation.dart';

import '../../pricing_e2e_harness.dart';

void main() {
  tearDown(() async {
    await tearDownPricingE2E();
  });

  group('e2e_e02_u05 — import (S8)', () {
    testWidgets('downloads the backend template through the file service', (
      tester,
    ) async {
      await setUpPricingE2E();
      final fileService = _FakePricingImportFileService();

      await tester.pumpWidget(
        buildPricingRouter(
          initialLocation: '/pricing/import',
          importFileService: fileService,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tải file mẫu import giá riêng'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(fileService.savedTemplate?.fileName, 'customer_price_rules_v1.xlsx');
      expect(
        fileService.savedTemplate?.bytes,
        Uint8List.fromList(const [0x50, 0x4B, 0x03, 0x04]),
      );
      expect(tester.widget<VToast>(find.byType(VToast)).type, VToastType.success);
    });

    testWidgets('canceling the save dialog does not show an error toast', (
      tester,
    ) async {
      await setUpPricingE2E();
      final fileService = _FakePricingImportFileService(saveResult: false);
      await tester.pumpWidget(
        buildPricingRouter(
          initialLocation: '/pricing/import',
          importFileService: fileService,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tải file mẫu import giá riêng'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(fileService.savedTemplate, isNotNull);
      expect(find.byType(VToast), findsNothing);
    });

    testWidgets(
      'e2e_e02_u05_fr01_01: start preview then confirm partial result',
      (tester) async {
        await setUpPricingE2E(
          importStartScenario: FakePricingScenario.importReadyMixed,
          importConfirmScenario: FakePricingScenario.importConfirmPartial,
        );

        await tester.pumpWidget(
          buildPricingRouter(initialLocation: '/pricing/import'),
        );
        await tester.pumpAndSettle();

        expect(findByWgtKey('wgt_e02_u05_fr01_01'), findsOneWidget);

        final cubit = tester
            .element(findByWgtKey('wgt_e02_u05_fr01_01'))
            .read<PriceRuleImportCubit>();

        await cubit.startImport(
          fileName: CustomerPriceRuleImportTemplateDto.fileNameV1,
          fileBytes: Uint8List.fromList(const [0x50, 0x4B, 0x03, 0x04]),
        );
        await tester.pumpAndSettle();

        expect(find.byType(PriceRuleImportPreviewView), findsOneWidget);
        expect(find.textContaining('Hộp 10 liều'), findsOneWidget);
        expect(find.textContaining('Đơn vị quy đổi'), findsOneWidget);

        cubit.proceedToConfirm();
        await tester.pumpAndSettle();

        await cubit.confirmImport(acknowledgeWarningRows: true);
        await tester.pumpAndSettle();

        expect(find.byType(PriceRuleImportResultView), findsOneWidget);
      },
    );

    testWidgets('back from preview confirms and cancels the current batch', (
      tester,
    ) async {
      final module = await setUpPricingE2E();
      await tester.pumpWidget(
        buildPricingRouter(initialLocation: '/pricing/import'),
      );
      await tester.pumpAndSettle();
      final cubit = tester
          .element(findByWgtKey('wgt_e02_u05_fr01_01'))
          .read<PriceRuleImportCubit>();
      await cubit.startImport(
        fileName: CustomerPriceRuleImportTemplateDto.fileNameV1,
        fileBytes: Uint8List.fromList(const [0x50, 0x4B]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Quay lại'));
      await tester.pumpAndSettle();
      expect(find.text('Hủy import?'), findsOneWidget);
      await tester.tap(find.text('Tiếp tục import'));
      await tester.pumpAndSettle();
      expect(find.byType(PriceRuleImportPreviewView), findsOneWidget);
      expect(
        module.commands.whereType<CancelCustomerPriceRuleImportCommand>(),
        isEmpty,
      );

      await tester.tap(find.text('Quay lại'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hủy import').last);
      await tester.pumpAndSettle();

      expect(find.byType(PriceRuleImportChooseFileView), findsOneWidget);
      expect(
        module.commands.whereType<CancelCustomerPriceRuleImportCommand>(),
        hasLength(1),
      );
    });
  });

  group('e2e_e02_u10 — history (S10)', () {
    testWidgets(
      'e2e_e02_u10_fr01_01: detail opens history timeline',
      (tester) async {
        await setUpPricingE2E(
          detailScenario: FakePricingScenario.ruleDetailActive,
          historyScenario: FakePricingScenario.historyMixedSources,
        );

        await tester.pumpWidget(
          buildPricingRouter(initialLocation: '/pricing/fake-rule-1'),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Thao tác'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Lịch sử áp dụng & thay đổi'));
        await tester.pumpAndSettle();

        expect(findByWgtKey('wgt_e02_u10_fr01_01'), findsOneWidget);
        expect(find.text('Lịch sử giá riêng'), findsOneWidget);
        expect(find.byType(PriceRuleHistoryView), findsOneWidget);
      },
    );

    testWidgets(
      'e2e_e02_u10_fr01_02: history denied shows permission empty',
      (tester) async {
        await setUpPricingE2E(
          historyScenario: FakePricingScenario.historyDenied,
        );

        await tester.pumpWidget(
          buildPricingRouter(
            initialLocation: '/pricing/fake-rule-1/history',
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Bạn không có quyền xem lịch sử giá riêng'),
          findsOneWidget,
        );
      },
    );
  });
}

final class _FakePricingImportFileService implements PricingImportFileService {
  _FakePricingImportFileService({this.saveResult = true});

  final bool saveResult;
  CustomerPriceRuleImportTemplateDto? savedTemplate;

  @override
  Future<PricingImportPickedFile?> pickXlsx() async => null;

  @override
  Future<bool> saveTemplate(CustomerPriceRuleImportTemplateDto template) async {
    savedTemplate = template;
    return saveResult;
  }

  @override
  Future<bool> saveImportLog({
    required String fileName,
    required Uint8List bytes,
  }) async => saveResult;

  @override
  Uint8List buildImportLogXlsx({
    required List<CustomerPriceRuleImportRowPreviewDto> rows,
  }) => Uint8List.fromList(const [0x50, 0x4B]);
}
