import 'package:erp/features/partner/logic/partner_list_state.dart';
import 'package:erp/features/partner/presentation/widgets/partner_sort_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

void main() {
  testWidgets('G4: sort sheet has exactly 4 choices and no role sort (BR-37)', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PartnerSortBottomSheet(
            initialSort: PartnerSortOption.updatedAtDesc,
          ),
        ),
      ),
    );

    final list = tester.widget<VChoiceList<PartnerSortOption>>(
      find.byType(VChoiceList<PartnerSortOption>),
    );
    expect(list.choices.map((c) => c.value).toList(), PartnerSortOption.values);
    expect(list.choices, hasLength(4));

    for (final label in [
      'Cập nhật gần nhất',
      'Cập nhật cũ nhất',
      'Tên A-Z',
      'Tên Z-A',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.textContaining('Vai trò giao dịch'), findsNothing);
  });
}
