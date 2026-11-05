import 'package:erp/features/pricing/presentation.dart';
import 'package:erp/features/pricing/presentation/widgets/price_rule_history_timeline_tile.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../pricing_e2e_harness.dart';

void main() {
  tearDown(() async {
    await tearDownPricingE2E();
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
      'history_page_activity_sheet_shows_floor_diff',
      (tester) async {
        await setUpPricingE2E(
          historyScenario: FakePricingScenario.historyMixedSources,
        );

        await tester.pumpWidget(
          buildPricingRouter(
            initialLocation: '/pricing/fake-rule-1/history',
          ),
        );
        await tester.pumpAndSettle();

        final updatedTile = find.ancestor(
          of: find.textContaining('bbbbbbbb'),
          matching: find.byType(PriceRuleHistoryTimelineTile),
        );
        await tester.ensureVisible(updatedTile.first);
        await tester.tap(updatedTile.first);
        await tester.pumpAndSettle();

        expect(find.byType(PriceRuleActivityDetailSheet), findsOneWidget);
        expect(find.text('Quyền hạn chế'), findsNothing);
        expect(find.text('Ẩn theo quyền 🔒'), findsNothing);
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
