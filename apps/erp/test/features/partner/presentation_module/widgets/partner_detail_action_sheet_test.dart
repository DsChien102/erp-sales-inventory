import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/features/partner/data/models/partner_models.dart';
import 'package:erp/features/partner/presentation.dart';

void main() {
  PartnerDetailDto personActive({
    List<PartnerAvailableAction> actions = const [
      PartnerAvailableAction.transform,
      PartnerAvailableAction.deactivate,
      PartnerAvailableAction.delete,
    ],
  }) {
    return PartnerDetailDto(
      partnerId: 'p-1',
      partnerType: PartnerType.person,
      status: PartnerStatus.active,
      displayName: 'Nguyễn Văn An',
      roles: const [PartnerRoleType.customer],
      availableActions: actions,
      expectedVersion: 1,
      personProfile: const PersonProfileDto(
        fullName: 'Nguyễn Văn An',
        phone: '0901234567',
      ),
    );
  }

  testWidgets('wgt_e02_u01_fr01_01: active person shows transform status delete', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PartnerDetailActionSheet(dto: personActive()),
        ),
      ),
    );

    expect(find.byKey(const Key('wgt_e02_u01_fr01_01')), findsOneWidget);
    expect(find.text('Thao tác hồ sơ'), findsOneWidget);
    expect(find.text('Chuyển thành tổ chức'), findsOneWidget);
    expect(find.text('Ngừng hoạt động'), findsOneWidget);
    expect(find.text('Xóa hồ sơ'), findsOneWidget);
    expect(find.text('Hủy'), findsOneWidget);
  });

  testWidgets('delete action pops PartnerDetailAction.delete', (tester) async {
    PartnerDetailAction? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                selected = await showModalBottomSheet<PartnerDetailAction>(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (_) => PartnerDetailActionSheet(
                    dto: personActive(),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('action_delete')));
    await tester.pumpAndSettle();
    expect(selected, PartnerDetailAction.delete);
  });

  testWidgets('hides transform for organization and shows reactivate when inactive', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PartnerDetailActionSheet(
            dto: PartnerDetailDto(
              partnerId: 'p-org',
              partnerType: PartnerType.organization,
              status: PartnerStatus.inactive,
              displayName: 'Công ty ABC',
              roles: const [PartnerRoleType.supplier],
              availableActions: const [
                PartnerAvailableAction.reactivate,
                PartnerAvailableAction.delete,
              ],
              expectedVersion: 2,
              organizationProfile: const OrganizationProfileDto(
                organizationType: OrganizationType.company,
                organizationName: 'Công ty ABC',
                phone: '02838225511',
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Chuyển thành tổ chức'), findsNothing);
    expect(find.text('Kích hoạt lại'), findsOneWidget);
    expect(
      find.text('Cho phép sử dụng lại trong hệ thống.'),
      findsOneWidget,
    );
    expect(find.byIcon(VIcons.power.value), findsOneWidget);
    expect(find.text('Ngừng hoạt động'), findsNothing);
    expect(find.text('Xóa hồ sơ'), findsOneWidget);
  });

  testWidgets('hides actions not in availableActions', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PartnerDetailActionSheet(
            dto: personActive(
              actions: const [PartnerAvailableAction.transform],
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('action_transform')), findsOneWidget);
    expect(find.byKey(const Key('action_toggle_status')), findsNothing);
    expect(find.byKey(const Key('action_delete')), findsNothing);
  });
}
