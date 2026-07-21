import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_application/testing.dart';
import 'package:vet45_pricing_presentation/presentation.dart';
import 'package:vet45_shared_application/application.dart';

import 'package:erp/features/pricing/presentation/pages/pricing_list_page.dart';
import 'package:erp/features/pricing/presentation/pages/pricing_detail_page.dart';
import 'package:erp/features/pricing/presentation/pages/pricing_form_page.dart';
import 'package:erp/features/pricing/presentation/pages/pricing_choose_method_page.dart';
import 'package:erp/features/pricing/presentation/pages/pricing_import_page.dart';
import 'package:erp/features/pricing/presentation/pages/pricing_history_page.dart';

class MockExecutionContext extends Mock implements IExecutionContext {}

void main() {
  late MockExecutionContext mockExecutionContext;

  setUp(() {
    mockExecutionContext = MockExecutionContext();
    when(() => mockExecutionContext.requireTenantId())
        .thenAnswer((_) async => 'test-tenant-id');

    final getIt = GetIt.instance;
    if (!getIt.isRegistered<IExecutionContext>()) {
      getIt.registerSingleton<IExecutionContext>(mockExecutionContext);
    }
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  Widget createTestWidget(Widget child) {
    return MaterialApp(
      theme: VTheme.lightTheme,
      home: Scaffold(body: child),
    );
  }

  Future<CustomerPriceRuleDetailDto> loadDetail({
    FakePricingScenario scenario = FakePricingScenario.ruleDetailActive,
    String ruleId = 'rule-1',
  }) {
    final module = FakePricingModule(scenario: scenario);
    return module.executeQueryAsync(
      GetCustomerPriceRuleDetailQuery(
        tenantId: 'test-tenant-id',
        ruleId: ruleId,
        businessDate: DateTime.utc(2026, 7, 16),
      ),
    );
  }

  // ── S2 / US-01 ──
  group('wgt_e02_u01 — PricingListPage (S2)', () {
    testWidgets('wgt_e02_u01_fr01_01 — danh sách + VSearchBar + VCard',
        (tester) async {
      GetIt.instance.registerSingleton<IPricingModule>(
        FakePricingModule(scenario: FakePricingScenario.searchRulesDefault),
      );

      await tester.pumpWidget(createTestWidget(const PricingListPage()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('wgt_e02_u01_fr01_01')), findsOneWidget);
      expect(find.text('Giá riêng / Nhớ giá'), findsOneWidget);
      expect(find.byType(VSearchBar), findsOneWidget);
      expect(find.byType(PriceRuleCard), findsWidgets);
      expect(find.byType(VCard), findsWidgets);
      expect(find.text('Khách hàng mẫu'), findsWidgets);
    });

    testWidgets('wgt_e02_u01_fr02_01 — empty state dùng VIcons', (tester) async {
      GetIt.instance.registerSingleton<IPricingModule>(
        FakePricingModule(scenario: FakePricingScenario.searchRulesEmpty),
      );

      await tester.pumpWidget(createTestWidget(const PricingListPage()));
      await tester.pumpAndSettle();

      expect(find.text('Chưa có giá riêng nào'), findsOneWidget);
      expect(find.byType(VEmptyState), findsOneWidget);
    });
  });

  // ── S4 / US-02 ──
  group('wgt_e02_u02 — PricingChooseMethodPage (S4)', () {
    testWidgets('wgt_e02_u02_fr01_01 — chọn phương thức thêm', (tester) async {
      await tester.pumpWidget(
        createTestWidget(const PricingChooseMethodPage()),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('wgt_e02_u02_fr01_01')), findsOneWidget);
      expect(find.text('Tạo thủ công'), findsOneWidget);
      expect(find.text('Nhập từ Excel'), findsOneWidget);
      expect(find.byType(VCard), findsWidgets);
    });
  });

  // ── S3 / US-03 ──
  group('wgt_e02_u03 — PricingDetailPage (S3)', () {
    testWidgets('wgt_e02_u03_fr01_01 — chi tiết + CTA Thao tác primary',
        (tester) async {
      GetIt.instance.registerSingleton<IPricingModule>(
        FakePricingModule(scenario: FakePricingScenario.ruleDetailActive),
      );

      await tester.pumpWidget(
        createTestWidget(const PricingDetailPage(ruleId: 'rule-1')),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('wgt_e02_u03_fr01_01')), findsOneWidget);
      final buttonFinder = find.byType(VButton);
      expect(buttonFinder, findsOneWidget);
      final vButton = tester.widget<VButton>(buttonFinder);
      expect(vButton.label, 'Thao tác');
      expect(vButton.variant, VButtonVariant.primary);
    });
  });

  // ── S1 / US-04 ──
  group('wgt_e02_u04 — PricingFormPage create (S1)', () {
    testWidgets('wgt_e02_u04_fr01_01 — form tạo dùng VMoneyField + VSection',
        (tester) async {
      GetIt.instance.registerSingleton<IPricingModule>(
        FakePricingModule(scenario: FakePricingScenario.createRuleOk),
      );

      await tester.pumpWidget(createTestWidget(const PricingFormPage()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('wgt_e02_u04_fr01_01')), findsOneWidget);
      expect(find.text('Tạo giá riêng'), findsOneWidget);
      expect(find.text('Thông tin áp dụng'), findsOneWidget);
      expect(find.text('Thời gian hiệu lực'), findsOneWidget);
      expect(find.byType(VMoneyField), findsOneWidget);
      expect(find.text('Hủy'), findsOneWidget);
      expect(find.text('Lưu'), findsOneWidget);
    });
  });

  // ── S8 / US-05 ──
  group('wgt_e02_u05 — PricingImportPage (S8)', () {
    testWidgets('wgt_e02_u05_fr01_01 — wizard import bước chọn file',
        (tester) async {
      GetIt.instance.registerSingleton<IPricingModule>(
        FakePricingModule(scenario: FakePricingScenario.importTemplateV1),
      );

      await tester.pumpWidget(createTestWidget(const PricingImportPage()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('wgt_e02_u05_fr01_01')), findsOneWidget);
      expect(find.text('Nhập từ Excel'), findsOneWidget);
      expect(find.byType(PriceRuleImportWizard), findsOneWidget);
    });
  });

  // ── S5 / US-06 ──
  group('wgt_e02_u06 — PricingFormPage edit (S5)', () {
    testWidgets('wgt_e02_u06_fr01_01 — form sửa với rule sẵn có', (tester) async {
      GetIt.instance.registerSingleton<IPricingModule>(
        FakePricingModule(scenario: FakePricingScenario.updateRuleOk),
      );
      final rule = await loadDetail();

      await tester.pumpWidget(
        createTestWidget(PricingFormPage(initialRule: rule)),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('wgt_e02_u06_fr01_01')), findsOneWidget);
      expect(find.text('Sửa giá riêng'), findsOneWidget);
      expect(find.byType(VMoneyField), findsOneWidget);
    });
  });

  // ── S6 / US-07 ──
  group('wgt_e02_u07 — PriceRuleDisableSheet (S6)', () {
    testWidgets('wgt_e02_u07_fr01_01 — sheet tắt giá riêng', (tester) async {
      final module = FakePricingModule(
        scenario: FakePricingScenario.disableRuleOk,
      );
      GetIt.instance.registerSingleton<IPricingModule>(module);
      final rule = await loadDetail();
      final cubit = PriceRuleDetailCubit(
        pricingModule: module,
        executionContext: mockExecutionContext,
      );

      await tester.pumpWidget(
        createTestWidget(
          PriceRuleDisableSheet(
            key: const Key('wgt_e02_u07_fr01_01'),
            rule: rule,
            cubit: cubit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('wgt_e02_u07_fr01_01')), findsOneWidget);
      expect(find.text('Tắt giá riêng?'), findsOneWidget);
      expect(find.byType(VTextField), findsOneWidget);
      await cubit.close();
    });
  });

  // ── S7 / US-08 ──
  group('wgt_e02_u08 — PriceRuleReenableSheet (S7)', () {
    testWidgets('wgt_e02_u08_fr01_01 — sheet bật lại giá riêng', (tester) async {
      final module = FakePricingModule(
        scenario: FakePricingScenario.reenableOk,
      );
      GetIt.instance.registerSingleton<IPricingModule>(module);
      final rule = await loadDetail(
        scenario: FakePricingScenario.ruleDetailDisabled,
      );
      final cubit = PriceRuleDetailCubit(
        pricingModule: module,
        executionContext: mockExecutionContext,
      );

      await tester.pumpWidget(
        createTestWidget(
          PriceRuleReenableSheet(
            key: const Key('wgt_e02_u08_fr01_01'),
            rule: rule,
            cubit: cubit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('wgt_e02_u08_fr01_01')), findsOneWidget);
      expect(find.text('Bật lại giá riêng?'), findsOneWidget);
      expect(find.byType(VBanner), findsOneWidget);
      await cubit.close();
    });
  });

  // ── S10 / US-10 ──
  group('wgt_e02_u10 — PricingHistoryPage (S10)', () {
    testWidgets('wgt_e02_u10_fr01_01 — timeline lịch sử + search',
        (tester) async {
      GetIt.instance.registerSingleton<IPricingModule>(
        FakePricingModule(scenario: FakePricingScenario.historyMixedSources),
      );

      await tester.pumpWidget(
        createTestWidget(const PricingHistoryPage(ruleId: 'rule-1')),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('wgt_e02_u10_fr01_01')), findsOneWidget);
      expect(find.text('Lịch sử giá riêng'), findsOneWidget);
      expect(find.byType(PriceRuleHistoryView), findsOneWidget);
      expect(find.byType(VSearchBar), findsOneWidget);
    });

    testWidgets('wgt_e02_u10_fr01_02 — no permission state', (tester) async {
      GetIt.instance.registerSingleton<IPricingModule>(
        FakePricingModule(scenario: FakePricingScenario.historyDenied),
      );

      await tester.pumpWidget(
        createTestWidget(const PricingHistoryPage(ruleId: 'rule-1')),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Bạn không có quyền xem lịch sử giá riêng'),
        findsOneWidget,
      );
    });
  });
}
