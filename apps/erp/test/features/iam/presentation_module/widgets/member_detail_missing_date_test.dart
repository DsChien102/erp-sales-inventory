import 'package:erp/features/iam/logic/member_ui_mapper.dart';
import 'package:erp/features/iam/logic/user_ui_model.dart';
import 'package:erp/features/iam/presentation/users/widgets/member_detail_narrow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/features/iam/data/models/tenant_member.dart';

void main() {
  testWidgets('missing pause and removal times render an em dash', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: const Scaffold(
          body: MemberDetailNarrow(
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

  testWidgets('missing lastActivityAt renders an em dash instead of joinedAt (Q17)', (tester) async {
    final mapped = MemberUiMapper.fromDetail(
      TenantMemberDetail.fromJson({
        'membership_id': 'mem-1',
        'tenant_id': 'org-1',
        'user_id': 'user-1',
        'display_name': 'An',
        'email': 'an@example.com',
        'role': 'staff',
        'role_label': 'Nhân viên',
        'is_owner': false,
        'is_sole_owner': false,
        'status': 'active',
        'version': 1,
        'joined_at': '2026-01-02T00:00:00Z',
        'last_activity_at': null,
      }),
    );

    expect(mapped.lastActiveDate, isEmpty);

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: Scaffold(
          body: MemberDetailNarrow(
            member: mapped,
          ),
        ),
      ),
    );

    expect(find.text('—'), findsOneWidget);
  });
}
