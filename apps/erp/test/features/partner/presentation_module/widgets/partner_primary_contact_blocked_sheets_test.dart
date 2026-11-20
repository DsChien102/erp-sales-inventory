import 'package:erp/features/partner/presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const expected =
      'Hồ sơ này đang là người liên hệ chính của “Công ty ABC”. '
      'Hãy đổi người liên hệ chính của tổ chức trước khi thực hiện chuyển đổi.';

  testWidgets('G7 (BR-46): transform blocked sheet wording is role-neutral', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PartnerTransformPrimaryContactBlockedSheet(
            organizationName: 'Công ty ABC',
          ),
        ),
      ),
    );

    expect(find.text(expected), findsOneWidget);
    expect(find.textContaining('Khách hàng này'), findsNothing);
  });

  testWidgets('G7 (BR-46): delete blocked sheet wording is role-neutral', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PartnerDeletePrimaryContactBlockedSheet(
            organizationName: 'Công ty ABC',
          ),
        ),
      ),
    );

    expect(
      find.text(
        'Hồ sơ này đang là người liên hệ chính của “Công ty ABC”. '
        'Hãy đổi hoặc gỡ người liên hệ chính trước khi xóa hồ sơ.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Khách hàng này'), findsNothing);
  });
}
