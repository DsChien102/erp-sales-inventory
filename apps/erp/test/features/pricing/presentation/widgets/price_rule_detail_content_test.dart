import 'package:erp/features/pricing/data/models.dart';
import 'package:erp/features/pricing/presentation/widgets/price_rule_detail_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../support/pricing_detail_dto_builder.dart';

void main() {
  group('B3 — price rule detail content behavioral preservation', () {
    testWidgets('b3_disabled_info_rows', (tester) async {
      final rule = buildPricingDetailDto(
        persistedStatus: CustomerPriceRuleStatus.disabled,
        derivedStatus: CustomerPriceRuleDerivedStatus.disabled,
        disabledAt: DateTime.utc(2026, 7, 16),
        disabledBy: 'fake-user-1',
        disabledReason: 'Hết hợp đồng',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: PriceRuleDetailContent(rule: rule),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Giá riêng đã tắt'), findsOneWidget);
      expect(find.text('Người tắt'), findsOneWidget);
      expect(find.text('Thời gian'), findsOneWidget);
      expect(find.text('Lý do'), findsOneWidget);
      expect(find.text('Hết hợp đồng'), findsOneWidget);
    });

    testWidgets('b3_source_labels', (tester) async {
      final manualRule = buildPricingDetailDto(
        sourceType: CustomerPriceRuleSourceType.manual,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: PriceRuleDetailContent(rule: manualRule),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tạo thủ công'), findsOneWidget);

      final excelRule = buildPricingDetailDto(
        sourceType: CustomerPriceRuleSourceType.excelImport,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: PriceRuleDetailContent(rule: excelRule),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Nhập Excel'), findsOneWidget);
    });
  });

  group('H6 & H7 — disabled by name & migration label', () {
    testWidgets('h6_disabled_by_name', (tester) async {
      final ruleWithName = buildPricingDetailDto(
        persistedStatus: CustomerPriceRuleStatus.disabled,
        derivedStatus: CustomerPriceRuleDerivedStatus.disabled,
        disabledBy: 'fake-user-1',
        disabledByName: 'Nguyễn Lan',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: PriceRuleDetailContent(rule: ruleWithName),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nguyễn Lan'), findsOneWidget);
      expect(find.text('fake-user-1'), findsNothing);

      final ruleWithoutName = buildPricingDetailDto(
        persistedStatus: CustomerPriceRuleStatus.disabled,
        derivedStatus: CustomerPriceRuleDerivedStatus.disabled,
        disabledBy: null,
        disabledByName: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: PriceRuleDetailContent(rule: ruleWithoutName),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('—'), findsWidgets);
    });

    testWidgets('h7_migration_label', (tester) async {
      final migrationRule = buildPricingDetailDto(
        sourceType: CustomerPriceRuleSourceType.migration,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: PriceRuleDetailContent(rule: migrationRule),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hệ thống'), findsOneWidget);
      expect(find.text('Migration'), findsNothing);
    });
  });
}

