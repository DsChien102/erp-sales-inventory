import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/features/pricing/presentation.dart';

void main() {
  Widget buildSubject({
    required String oldPriceLabel,
    required String newPriceLabel,
    required String oldFromLabel,
    required String newFromLabel,
    required String oldToLabel,
    required String newToLabel,
    required ValueChanged<String?> onConfirm,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: PriceRuleSaveConfirmSheet(
          oldPriceLabel: oldPriceLabel,
          newPriceLabel: newPriceLabel,
          oldFromLabel: oldFromLabel,
          newFromLabel: newFromLabel,
          oldToLabel: oldToLabel,
          newToLabel: newToLabel,
          onConfirm: onConfirm,
        ),
      ),
    );
  }

  testWidgets('PriceRuleSaveConfirmSheet displays VCard details and header',
      (tester) async {
    String? confirmedReason;

    await tester.pumpWidget(
      buildSubject(
        oldPriceLabel: '95.000đ',
        newPriceLabel: '100.200đ',
        oldFromLabel: '10/07/2026',
        newFromLabel: '10/07/2026',
        oldToLabel: 'Không giới hạn',
        newToLabel: '31/12/2026',
        onConfirm: (reason) => confirmedReason = reason,
      ),
    );

    expect(find.text('Lưu thay đổi?'), findsOneWidget);
    expect(find.text('Bạn có chắc muốn cập nhật giá riêng này?'), findsOneWidget);
    expect(find.byType(VCard), findsOneWidget);
    expect(find.text('Giá riêng:'), findsOneWidget);
    expect(find.text('95.000đ'), findsOneWidget);
    expect(find.text('100.200đ'), findsOneWidget);
    expect(find.text('Đến ngày:'), findsOneWidget);
    expect(find.text('Không giới hạn'), findsOneWidget);
    expect(find.text('31/12/2026'), findsOneWidget);
    expect(find.text('Nhập lý do thay đổi...'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Sửa giá niêm yết mới');
    await tester.pump();

    expect(find.text('20/200'), findsOneWidget);

    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pump();

    expect(confirmedReason, 'Sửa giá niêm yết mới');
  });
}
