import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_partner_presentation/presentation.dart';

void main() {
  final partner = PartnerDetailDto(
    partnerId: 'p-person-1',
    partnerType: PartnerType.person,
    status: PartnerStatus.active,
    displayName: 'Nguyễn Văn An',
    roles: const [PartnerRoleType.customer],
    availableActions: const [PartnerAvailableAction.transform],
    expectedVersion: 1,
    personProfile: const PersonProfileDto(
      fullName: 'Nguyễn Văn An',
      phone: '0901 234 567',
    ),
  );

  Widget buildSubject({
    ValueChanged<OrganizationProfileInput>? onContinue,
    VoidCallback? onCancel,
    OrganizationProfileInput? initialValue,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: PartnerTransformStepOneView(
          partner: partner,
          onCancel: onCancel ?? () {},
          onContinue: onContinue ?? (_) {},
          initialValue: initialValue,
        ),
      ),
    );
  }

  testWidgets('wgt_e01_u06_fr02_01 renders fields and current person', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());

    expect(find.text('Thông tin tổ chức (mới)'), findsOneWidget);
    expect(find.text('Thông tin tổ chức'), findsOneWidget);
    expect(find.text('Xem trước'), findsOneWidget);
    expect(find.text('Xác nhận'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is RichText && widget.text.toPlainText() == 'Loại tổ chức *',
      ),
      findsOneWidget,
    );
    expect(find.text('Chọn loại tổ chức'), findsOneWidget);
    expect(find.text('Nguyễn Văn An'), findsOneWidget);
    expect(find.text('0901 234 567'), findsOneWidget);
    expect(
      find.text('Cá nhân hiện tại sẽ được lưu làm người liên hệ chính'),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('transform_organization_name')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('transform_phone')), findsOneWidget);
    expect(find.byKey(const Key('transform_email')), findsOneWidget);
    expect(find.byKey(const Key('transform_tax_code')), findsOneWidget);
  });

  testWidgets('wgt_e01_u06_fr03_01 enables continue after required fields', (
    tester,
  ) async {
    OrganizationProfileInput? submitted;
    await tester.pumpWidget(
      buildSubject(onContinue: (value) => submitted = value),
    );

    await tester.tap(find.byKey(const Key('transform_organization_type')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Công ty').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('transform_organization_name')),
      'Công ty TNHH An Phát',
    );
    await tester.enterText(
      find.byKey(const Key('transform_phone')),
      '028 3822 5511',
    );
    await tester.pump();

    expect(
      tester.widget<VButton>(find.byKey(const Key('transform_continue'))).onPressed,
      isNotNull,
    );
    await tester.ensureVisible(find.byKey(const Key('transform_continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('transform_continue')));

    expect(submitted?.organizationType, OrganizationType.company);
    expect(submitted?.organizationName, 'Công ty TNHH An Phát');
    expect(submitted?.phone, '028 3822 5511');
  });

  testWidgets(
    'wgt_e01_u06_fr05_01 shows blocking banner and field errors on invalid continue',
    (tester) async {
      var submitCount = 0;
      await tester.pumpWidget(
        buildSubject(onContinue: (_) => submitCount++),
      );

      await tester.ensureVisible(find.byKey(const Key('transform_continue')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('transform_continue')));
      await tester.pump();

      expect(find.byKey(const Key('transform_blocking_banner')), findsOneWidget);
      expect(
        find.text(
          'Không thể chuyển đổi khi thiếu thông tin bắt buộc hoặc dữ liệu bị trùng.',
        ),
        findsOneWidget,
      );
      expect(find.text('Vui lòng chọn loại tổ chức'), findsOneWidget);
      expect(find.text('Vui lòng nhập tên tổ chức'), findsOneWidget);
      expect(find.text('Số điện thoại không hợp lệ'), findsOneWidget);
      expect(
        tester.widget<VButton>(find.byKey(const Key('transform_continue'))).onPressed,
        isNull,
      );
      expect(submitCount, 0);
    },
  );

  testWidgets('wgt_e01_u06_fr06_01 cancel leaves without submitting', (
    tester,
  ) async {
    var cancelled = false;
    var submitCount = 0;
    await tester.pumpWidget(
      buildSubject(
        onCancel: () => cancelled = true,
        onContinue: (_) => submitCount++,
      ),
    );

    await tester.ensureVisible(find.byKey(const Key('transform_cancel')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('transform_cancel')));

    expect(cancelled, isTrue);
    expect(submitCount, 0);
  });

  testWidgets('transform fields use separate labels and compact controls', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());

    final nameField = find.descendant(
      of: find.byKey(const Key('transform_organization_name')),
      matching: find.byType(TextField),
    );
    final phoneField = find.descendant(
      of: find.byKey(const Key('transform_phone')),
      matching: find.byType(TextField),
    );

    expect(tester.widget<TextField>(nameField).decoration?.label, isNull);
    expect(tester.getSize(nameField).height, 48);
    expect(tester.getSize(nameField).width, tester.getSize(phoneField).width);
    expect(
      find.byKey(const Key('transform_organization_name_label')),
      findsOneWidget,
    );
  });

  testWidgets('stepper has connectors and actions follow the contact card', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildSubject());

    expect(find.byKey(const Key('transform_step_connector_1')), findsOneWidget);
    expect(find.byKey(const Key('transform_step_connector_2')), findsOneWidget);
    expect(
      find.ancestor(
        of: find.byKey(const Key('transform_cancel')),
        matching: find.byType(SingleChildScrollView),
      ),
      findsOneWidget,
    );
    expect(
      find.ancestor(
        of: find.byKey(const Key('transform_continue')),
        matching: find.byType(SafeArea),
      ),
      findsOneWidget,
    );
    await tester.ensureVisible(find.byKey(const Key('transform_continue')));
    await tester.pumpAndSettle();
    expect(find.text('Nguyễn Văn An'), findsOneWidget);
    expect(find.byKey(const Key('transform_cancel')), findsOneWidget);
    expect(find.byKey(const Key('transform_continue')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('restores organization draft when returning from preview', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(
        initialValue: const OrganizationProfileInput(
          organizationType: OrganizationType.businessHousehold,
          organizationName: 'Hộ kinh doanh An Phát',
          phone: '0909 111 222',
        ),
      ),
    );

    expect(find.text('Hộ kinh doanh'), findsOneWidget);
    expect(find.text('Hộ kinh doanh An Phát'), findsOneWidget);
    expect(find.text('0909 111 222'), findsOneWidget);
  });
}
