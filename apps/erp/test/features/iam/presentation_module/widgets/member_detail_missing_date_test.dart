import 'package:erp/features/iam/logic/user_ui_model.dart';
import 'package:erp/features/iam/presentation/users/widgets/member_detail_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/features/iam/data/models/tenant_member.dart';

void main() {
  testWidgets('missing pause and removal times render an em dash', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: const Scaffold(
          body: MemberDetailBody(
            detailStatus: MembershipStatus.inactive,
            member: MemberUiModel(
              id: 'm1',
              name: 'An',
              email: 'an@example.com',
              role: 'Thủ kho',
              status: MemberStatus.suspended,
            ),
          ),
        ),
      ),
    );

    expect(find.text('—'), findsWidgets);
    expect(find.textContaining('14/07/2026'), findsNothing);
    expect(find.text('Phiên bản dữ liệu'), findsNothing);
    expect(find.text('Lê Thị Lan'), findsNothing);
  });
}
