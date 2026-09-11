import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:admin/features/iam/presentation.dart';
import 'package:admin/features/iam/presentation/users/widgets/member_card.dart';

MemberUiModel _member(MemberStatus status) => MemberUiModel(
      id: 'mem-1',
      name: 'Nguyen Van A',
      email: 'a@example.com',
      role: 'accountant',
      status: status,
    );

Future<void> _pump(WidgetTester tester, MemberStatus status) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: VTheme.lightTheme,
      home: Scaffold(body: MemberCard(member: _member(status))),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('MemberCard status badge', () {
    testWidgets('active shows Hoạt động', (tester) async {
      await _pump(tester, MemberStatus.active);
      expect(find.text('Hoạt động'), findsOneWidget);
    });

    testWidgets('suspended shows Tạm ngừng', (tester) async {
      await _pump(tester, MemberStatus.suspended);
      expect(find.text('Tạm ngừng'), findsOneWidget);
    });

    testWidgets('removed shows Đã loại, not Tạm ngừng', (tester) async {
      await _pump(tester, MemberStatus.removed);
      expect(find.text('Đã loại'), findsOneWidget);
      expect(find.text('Tạm ngừng'), findsNothing);
    });
  });
}
