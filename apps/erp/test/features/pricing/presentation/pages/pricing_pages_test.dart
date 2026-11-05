import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/pricing/data/customer_price_rule_repository.dart';
import 'package:erp/features/pricing/data/models.dart';
import 'package:erp/features/pricing/data/pricing_errors.dart';
import 'package:erp/features/pricing/presentation.dart';
import 'package:erp/features/pricing/presentation/pages/pricing_detail_page.dart';
import 'package:erp/features/pricing/presentation/pages/pricing_form_page.dart';
import 'package:erp/features/pricing/presentation/pages/pricing_history_page.dart';
import 'package:erp/features/pricing/presentation/pages/pricing_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../support/fake_customer_price_rule_repository.dart';
import '../../support/fake_pricing_backend.dart';
import '../../support/pricing_detail_dto_builder.dart';

void main() {
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
    final repo = FakeCustomerPriceRuleRepository(detailScenario: scenario);
    return repo.getDetail(
      ruleId: ruleId,
      businessDate: DateTime.utc(2026, 7, 16),
    );
  }

  // ── S2 / US-01 ──
  group('wgt_e02_u01 — PricingListPage (S2)', () {
    testWidgets('wgt_e02_u01_fr01_01 — danh sách + VSearchBar + VCard', (tester) async {
      GetIt.instance.registerSingleton<CustomerPriceRuleRepository>(
        FakeCustomerPriceRuleRepository(
          searchScenario: FakePricingScenario.searchRulesDefault,
        ),
      );

      await tester.pumpWidget(createTestWidget(const PricingListPage()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('wgt_e02_u01_fr01_01')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('wgt_e02_u01_fr01_01')),
          matching: find.text('Giá riêng'),
        ),
        findsWidgets,
      );
      expect(find.byType(VSearchBar), findsOneWidget);
      expect(find.byType(PriceRuleCard), findsWidgets);
      expect(find.byType(VCard), findsWidgets);
      expect(find.text('Khách hàng mẫu'), findsWidgets);
      expect(find.text('90.000đ'), findsWidgets);
    });

    testWidgets('wgt_e02_u01_fr02_01 — empty state dùng VIcons', (tester) async {
      GetIt.instance.registerSingleton<CustomerPriceRuleRepository>(
        FakeCustomerPriceRuleRepository(
          searchScenario: FakePricingScenario.searchRulesEmpty,
        ),
      );

      await tester.pumpWidget(createTestWidget(const PricingListPage()));
      await tester.pumpAndSettle();

      expect(find.text('Chưa có giá riêng nào'), findsOneWidget);
      expect(find.text('Tạo giá riêng để bắt đầu.'), findsOneWidget);
      expect(find.byType(VEmptyState), findsOneWidget);
    });

    testWidgets(
      'wgt_e02_u01_fr03_01 — offline error uses designed retry state',
      (tester) async {
        final repo = _SystemErrorPricingRepository();
        GetIt.instance.registerSingleton<CustomerPriceRuleRepository>(repo);

        await tester.pumpWidget(createTestWidget(const PricingListPage()));
        await tester.pumpAndSettle();

        expect(find.text('Không tải được danh sách'), findsOneWidget);
        expect(
          find.text('Vui lòng kiểm tra kết nối internet\nhoặc thử lại sau.'),
          findsOneWidget,
        );
        expect(find.text('Thử lại'), findsOneWidget);
        expect(find.byType(VSearchBar), findsNothing);
        expect(find.byType(VFloatingActionButton), findsNothing);

        final emptyState = tester.widget<VEmptyState>(find.byType(VEmptyState));
        expect(emptyState.icon, VIcons.cloudOff);
        expect(emptyState.tone, VComponentTone.danger);

        await tester.tap(find.text('Thử lại'));
        await tester.pumpAndSettle();
        expect(repo.queryCount, 2);
      },
    );

    testWidgets('h2_filter_sheet_chips — sheet co dung cac chip theo quy tac', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => PriceRuleFilterBottomSheet.show(
                context,
                initial: PriceRuleAdvancedFilter.empty,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Bộ lọc giá riêng'), findsOneWidget);
      expect(find.text('Trùng rule'), findsNothing);
      expect(find.text('Dữ liệu lỗi'), findsNothing);
      expect(find.text('Từ đơn hàng'), findsNothing);
      expect(find.text('Migration'), findsNothing);
      expect(find.text('Tùy chọn'), findsNothing);

      expect(find.text('Nhập Excel'), findsOneWidget);
      expect(find.text('Dưới giá sàn'), findsOneWidget);
      expect(find.text('Tạo thủ công'), findsOneWidget);
      expect(find.text('7 ngày gần đây'), findsOneWidget);
      expect(find.text('30 ngày gần đây'), findsOneWidget);
    });

    testWidgets('h8_list_title — header shows title and total count', (tester) async {
      GetIt.instance.registerSingleton<CustomerPriceRuleRepository>(
        FakeCustomerPriceRuleRepository(
          searchScenario: FakePricingScenario.searchRulesDefault,
        ),
      );

      await tester.pumpWidget(createTestWidget(const PricingListPage()));
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (w) => w is VPageScaffold && w.title == 'Giá riêng',
        ),
        findsOneWidget,
      );
      expect(find.text('2 giá riêng'), findsOneWidget);
    });
  });

  // ── S3 / US-03 ──
  group('wgt_e02_u03 — PricingDetailPage (S3)', () {
    testWidgets('wgt_e02_u03_fr01_01 — chi tiết + CTA Thao tác primary', (tester) async {
      GetIt.instance.registerSingleton<CustomerPriceRuleRepository>(
        FakeCustomerPriceRuleRepository(
          detailScenario: FakePricingScenario.ruleDetailActive,
        ),
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
      expect(find.text('90.000 đ'), findsOneWidget);
    });
  });

  // ── S1 / US-04 ──
  group('wgt_e02_u04 — PricingFormPage create (S1)', () {
    testWidgets('wgt_e02_u04_fr01_01 — form tạo dùng VMoneyField + VSection', (tester) async {
      GetIt.instance.registerSingleton<CustomerPriceRuleRepository>(
        FakeCustomerPriceRuleRepository(
          createScenario: FakePricingScenario.createRuleOk,
        ),
      );

      await tester.pumpWidget(createTestWidget(const PricingFormPage()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('wgt_e02_u04_fr01_01')), findsOneWidget);
      expect(find.text('Tạo giá riêng'), findsOneWidget);
      expect(find.text('Thông tin áp dụng'), findsOneWidget);
      expect(find.text('Thời gian hiệu lực'), findsOneWidget);
      expect(find.byType(VMoneyField), findsOneWidget);
      expect(find.byKey(const Key('input_price_rule_note')), findsOneWidget);
      expect(find.byType(VTextFormField), findsOneWidget);
      expect(find.text('Hủy'), findsOneWidget);
      expect(find.text('Lưu'), findsOneWidget);

      final moneyField = tester.widget<VMoneyField>(find.byType(VMoneyField));
      moneyField.onChanged?.call(100000);
      await tester.pump();

      final formContext = tester.element(find.byType(PriceRuleFormBody));
      final cubit = formContext.read<PriceRuleFormCubit>();
      final state = cubit.state as PriceRuleFormEditing;
      expect(state.rulePriceMinor, 100000);
    });

    testWidgets('SC-06 — dirty Hủy mở leave confirmation (VConfirmDialog)', (tester) async {
      GetIt.instance.registerSingleton<CustomerPriceRuleRepository>(
        FakeCustomerPriceRuleRepository(
          createScenario: FakePricingScenario.createRuleOk,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Navigator(
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (_) => const PricingFormPage(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final formContext = tester.element(find.byType(PriceRuleFormBody));
      formContext.read<PriceRuleFormCubit>().updatePrice(100000);
      await tester.pump();

      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();

      expect(find.text('Rời khỏi màn hình?'), findsOneWidget);
      expect(find.byType(VConfirmDialog), findsOneWidget);
      expect(find.byKey(const Key('wgt_e02_u04_fr01_01')), findsOneWidget);
    });

    testWidgets('SC-06 — dirty back mở leave confirmation', (tester) async {
      GetIt.instance.registerSingleton<CustomerPriceRuleRepository>(
        FakeCustomerPriceRuleRepository(
          createScenario: FakePricingScenario.createRuleOk,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Navigator(
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (_) => const PricingFormPage(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final formContext = tester.element(find.byType(PriceRuleFormBody));
      formContext.read<PriceRuleFormCubit>().updatePrice(100000);
      await tester.pump();

      await tester.tap(find.byKey(const Key('btn_price_rule_form_back')));
      await tester.pumpAndSettle();

      expect(find.text('Rời khỏi màn hình?'), findsOneWidget);
      expect(find.byType(VConfirmDialog), findsOneWidget);
    });

    testWidgets('SC-06 — dirty system back (maybePop) mở leave confirmation', (tester) async {
      GetIt.instance.registerSingleton<CustomerPriceRuleRepository>(
        FakeCustomerPriceRuleRepository(
          createScenario: FakePricingScenario.createRuleOk,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => VButton(
                label: 'Open form',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const PricingFormPage(),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open form'));
      await tester.pumpAndSettle();

      tester.element(find.byType(PriceRuleFormBody)).read<PriceRuleFormCubit>().updatePrice(100000);
      await tester.pumpAndSettle();

      final formContext = tester.element(find.byType(PriceRuleFormBody));
      expect(
        (formContext.read<PriceRuleFormCubit>().state as PriceRuleFormEditing).isDirty,
        isTrue,
      );

      final popScope = tester.widget<PopScope<Object?>>(
        find.byType(PopScope<Object?>).first,
      );
      expect(popScope.canPop, isFalse);

      await Navigator.of(formContext).maybePop();
      await tester.pumpAndSettle();

      expect(find.text('Rời khỏi màn hình?'), findsOneWidget);
      expect(find.byType(VConfirmDialog), findsOneWidget);
      expect(find.byKey(const Key('wgt_e02_u04_fr01_01')), findsOneWidget);
    });

    testWidgets('SC-06 — clean Hủy thoát ngay không hỏi', (tester) async {
      GetIt.instance.registerSingleton<CustomerPriceRuleRepository>(
        FakeCustomerPriceRuleRepository(
          createScenario: FakePricingScenario.createRuleOk,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => VButton(
                label: 'Open form',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const PricingFormPage(),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open form'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('wgt_e02_u04_fr01_01')), findsOneWidget);

      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();

      expect(find.text('Rời khỏi màn hình?'), findsNothing);
      expect(find.byKey(const Key('wgt_e02_u04_fr01_01')), findsNothing);
      expect(find.text('Open form'), findsOneWidget);
    });
  });

  // ── S5 / US-06 ──
  group('wgt_e02_u06 — PricingFormPage edit (S5)', () {
    testWidgets('wgt_e02_u06_fr01_01 — form sửa với rule sẵn có', (tester) async {
      GetIt.instance.registerSingleton<CustomerPriceRuleRepository>(
        FakeCustomerPriceRuleRepository(
          updateScenario: FakePricingScenario.updateRuleOk,
        ),
      );
      final rule = await loadDetail();

      await tester.pumpWidget(
        createTestWidget(PricingFormPage(initialRule: rule)),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('wgt_e02_u06_fr01_01')), findsOneWidget);
      expect(find.text('Sửa giá riêng'), findsOneWidget);
      expect(find.byType(VMoneyField), findsOneWidget);
      final moneyField = tester.widget<VMoneyField>(find.byType(VMoneyField));
      expect(moneyField.controller?.text, '90,000');
    });

    testWidgets('SC-06 — dirty Hủy trên form sửa mở leave confirmation', (tester) async {
      GetIt.instance.registerSingleton<CustomerPriceRuleRepository>(
        FakeCustomerPriceRuleRepository(
          updateScenario: FakePricingScenario.updateRuleOk,
        ),
      );
      final rule = await loadDetail();

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Navigator(
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (_) => PricingFormPage(initialRule: rule),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final formContext = tester.element(find.byType(PriceRuleFormBody));
      formContext.read<PriceRuleFormCubit>().updatePrice(rule.price.amountMinor + 5000);
      await tester.pump();

      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();

      expect(find.text('Rời khỏi màn hình?'), findsOneWidget);
      expect(find.byType(VConfirmDialog), findsOneWidget);
      expect(find.byKey(const Key('wgt_e02_u06_fr01_01')), findsOneWidget);
    });
  });

  // ── S6 / US-07 ──
  group('wgt_e02_u07 — PriceRuleDisableSheet (S6)', () {
    testWidgets('wgt_e02_u07_fr01_01 — sheet tắt giá riêng', (tester) async {
      final repo = FakeCustomerPriceRuleRepository(
        disableScenario: FakePricingScenario.disableRuleOk,
      );
      GetIt.instance.registerSingleton<CustomerPriceRuleRepository>(repo);
      final rule = await loadDetail();
      final cubit = PriceRuleDetailCubit(repository: repo);

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
      final repo = FakeCustomerPriceRuleRepository(
        reenableScenario: FakePricingScenario.reenableOk,
      );
      GetIt.instance.registerSingleton<CustomerPriceRuleRepository>(repo);
      final rule = await loadDetail(
        scenario: FakePricingScenario.ruleDetailDisabled,
      );
      final cubit = PriceRuleDetailCubit(repository: repo);

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

    testWidgets('h9_reenable_overwrite_text', (tester) async {
      final repo = FakeCustomerPriceRuleRepository(
        reenableScenario: FakePricingScenario.reenableOk,
      );
      GetIt.instance.registerSingleton<CustomerPriceRuleRepository>(repo);
      final rule = await loadDetail(
        scenario: FakePricingScenario.ruleDetailDisabled,
      );
      final cubit = PriceRuleDetailCubit(repository: repo);

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

      expect(
        find.text(
          'Bật lại giá riêng này sẽ tự động ghi đè (xoá) giá riêng trùng (nếu có).',
        ),
        findsOneWidget,
      );
      await cubit.close();
    });

    testWidgets('t93_reenable_below_floor_checkbox', (tester) async {
      final repo = FakeCustomerPriceRuleRepository(
        reenablePrecheckScenario: FakePricingScenario.reenablePrecheckWarning,
      );
      GetIt.instance.registerSingleton<CustomerPriceRuleRepository>(repo);
      final rule = await loadDetail(
        scenario: FakePricingScenario.ruleDetailDisabled,
      );
      final cubit = PriceRuleDetailCubit(repository: repo);

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

      expect(
        find.text('Tôi xác nhận bật lại giá dưới giá sàn'),
        findsOneWidget,
      );
      final buttonFinder = find.widgetWithText(VButton, 'Bật lại giá riêng');
      expect(tester.widget<VButton>(buttonFinder).onPressed, isNull);

      await tester.tap(find.text('Tôi xác nhận bật lại giá dưới giá sàn'));
      await tester.pumpAndSettle();

      expect(tester.widget<VButton>(buttonFinder).onPressed, isNotNull);
      await cubit.close();
    });
  });

  group('wgt_e02_u03 — PriceRuleActionSheet available actions', () {
    testWidgets('t93_action_sheet_available_actions', (tester) async {
      final rule = buildPricingDetailDto(
        availableActions: const [
          CustomerPriceRuleAvailableActions.edit,
          CustomerPriceRuleAvailableActions.history,
        ],
      );

      await tester.pumpWidget(
        createTestWidget(
          PriceRuleActionSheet(rule: rule),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sửa giá riêng'), findsOneWidget);
      expect(find.text('Lịch sử áp dụng & thay đổi'), findsOneWidget);
      expect(find.text('Tắt giá riêng'), findsNothing);
      expect(find.text('Bật lại giá riêng'), findsNothing);
    });
  });

  // ── S10 / US-10 ──
  group('wgt_e02_u10 — PricingHistoryPage (S10)', () {
    testWidgets('wgt_e02_u10_fr01_01 — timeline lịch sử + search', (tester) async {
      GetIt.instance.registerSingleton<CustomerPriceRuleRepository>(
        FakeCustomerPriceRuleRepository(
          historyScenario: FakePricingScenario.historyMixedSources,
        ),
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
      GetIt.instance.registerSingleton<CustomerPriceRuleRepository>(
        FakeCustomerPriceRuleRepository(
          historyScenario: FakePricingScenario.historyDenied,
        ),
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

final class _SystemErrorPricingRepository extends FakeCustomerPriceRuleRepository {
  int queryCount = 0;

  @override
  Future<CustomerPriceRuleSearchResultDto> search({
    required DateTime businessDate,
    String? q,
    CustomerPriceRuleQuickFilter quickFilter = CustomerPriceRuleQuickFilter.all,
    List<CustomerPriceRuleDerivedStatus> statuses = const [],
    List<CustomerPriceRuleSourceType> sources = const [],
    String? customerId,
    String? productId,
    String? cursor,
    int limit = 20,
    PriceRuleSortOption sort = PriceRuleSortOption.updatedAtDesc,
    PriceRuleUpdatedWithin? updatedWithin,
  }) async {
    queryCount++;
    throw const AppException(PricingErrorCodes.systemError);
  }
}
