import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:admin/features/iam/presentation/organizations/models/organization_ui_model.dart';
import 'package:admin/features/iam/presentation/organizations/widgets/organization_filter_bottom_sheet.dart';
import 'package:admin/features/iam/presentation/organizations/widgets/organization_search_bar.dart';

void main() {
  testWidgets('OrganizationFilterBottomSheet renders correctly with default criteria',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OrganizationFilterBottomSheet(
            initialCriteria: const OrganizationFilterCriteria(),
          ),
        ),
      ),
    );

    expect(find.text('Bộ lọc tổ chức nền tảng'), findsOneWidget);
    expect(find.text('Trạng thái'), findsOneWidget);
    expect(find.text('Vòng đời'), findsOneWidget);
    expect(find.text('Mức hoàn thiện'), findsOneWidget);
    expect(find.text('Đặt lại'), findsOneWidget);
    expect(find.text('Áp dụng'), findsOneWidget);
  });

  testWidgets('Selecting a chip updates internal state and clicking Áp dụng returns new criteria',
      (tester) async {
    OrganizationFilterCriteria? appliedCriteria;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showVBottomSheet(
                    context: context,
                    child: OrganizationFilterBottomSheet(
                      initialCriteria: const OrganizationFilterCriteria(),
                      onApply: (criteria) {
                        appliedCriteria = criteria;
                      },
                    ),
                  );
                },
                child: const Text('Open Filter'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Filter'));
    await tester.pumpAndSettle();

    // Tap 'Hoạt động' chip in Trạng thái
    await tester.tap(find.text('Hoạt động'));
    await tester.pumpAndSettle();

    // Tap Áp dụng
    await tester.tap(find.text('Áp dụng'));
    await tester.pumpAndSettle();

    expect(appliedCriteria, isNotNull);
    expect(appliedCriteria!.status, OrganizationStatus.active);
    expect(appliedCriteria!.isFilterActive, isTrue);
  });

  testWidgets('OrganizationSearchBar renders active green state when isFilterActive is true',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OrganizationSearchBar(
            isFilterActive: true,
          ),
        ),
      ),
    );

    expect(find.byType(VIconBox), findsOneWidget);
    final iconBox = tester.widget<VIconBox>(find.byType(VIconBox));
    expect(iconBox.icon, VIcons.tune);
  });
}
