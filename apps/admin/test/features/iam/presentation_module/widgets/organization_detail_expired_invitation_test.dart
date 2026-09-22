import 'package:admin/features/iam/presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('expired owner invitation shows the expired warning', (tester) async {
    const organization = OrganizationUiModel(
      id: 'tenant-1',
      name: 'Anh Quỳnh',
      code: '4e3d55f4',
      status: OrganizationStatus.settingUp,
      ownerName: 'Quỳnh Chí Long',
      ownerEmail: 'dosychien9@gmail.com',
      ownerInvitationEmail: 'dosychien9@gmail.com',
      ownerInvitationState: 'expired',
      unverifiedEmail: true,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OrganizationDetailAlerts(organization: organization),
        ),
      ),
    );

    expect(find.text('Lời mời hết hạn'), findsOneWidget);
    expect(find.text('Email Chủ sở hữu chưa xác minh'), findsNothing);
  });
}
