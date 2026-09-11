import 'package:admin/features/organizations/presentation/pages/organizations_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/testing.dart';
import 'package:admin/features/iam/presentation.dart';
import 'package:admin/features/iam/testing.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );
  }

  group('OrganizationDetailPage Widget Tests (4 Design Variants)', () {
    testWidgets('PA-D-02: renders Detail Page for Setting Up status (ASC Commerce)',
        (tester) async {
      final ascCommerceOrg = FakeOrganizationData.sampleOrganizations.firstWhere(
        (o) => o.code == 'TEN-000138',
      );

      await tester.pumpWidget(buildTestableWidget(
        OrganizationDetailPage(organization: ascCommerceOrg),
      ));
      await tester.pumpAndSettle();

      // Top bar & Header
      expect(find.text('Chi tiết tổ chức'), findsOneWidget);
      expect(find.text('Đang thiết lập'), findsOneWidget);
      expect(find.text('ASC Commerce'), findsOneWidget);
      expect(find.text('TEN-000138'), findsOneWidget);

      // Warning Banners
      expect(find.text('Email Chủ sở hữu chưa xác minh'), findsOneWidget);
      expect(find.text('Hồ sơ cơ bản chưa hoàn thiện'), findsOneWidget);

      // Owner Card
      expect(find.text('Chủ sở hữu'), findsOneWidget);
      expect(find.text('Lê Thị Lan'), findsOneWidget);
      expect(find.text('lan@gmail.com'), findsOneWidget);

      // Platform Info
      expect(find.text('Thông tin nền tảng'), findsOneWidget);
      expect(find.text('Ngày khởi tạo'), findsOneWidget);

      // Bottom Bar
      expect(find.text('Thao tác'), findsOneWidget);
    });

    testWidgets('PA-D-03: renders Detail Page for Active status with Members (Mậu Hiền)',
        (tester) async {
      final mauHienOrg = FakeOrganizationData.sampleOrganizations.firstWhere(
        (o) => o.code == 'TEN-000142',
      );

      await tester.pumpWidget(buildTestableWidget(
        OrganizationDetailPage(organization: mauHienOrg),
      ));
      await tester.pumpAndSettle();

      // Header & Badge
      expect(find.text('Đang hoạt động'), findsOneWidget);
      expect(find.text('Mậu Hiền'), findsOneWidget);

      // Members section
      expect(find.text('Thành viên tổ chức'), findsNWidgets(3));
      expect(find.text('3 thành viên'), findsOneWidget);
      expect(find.text('Lê Thị Lan'), findsOneWidget);
      expect(find.text('Trần Thị Hoa'), findsOneWidget);
      expect(find.text('Nguyễn Văn Minh'), findsOneWidget);

      // Platform info
      expect(find.text('Kích hoạt lúc'), findsOneWidget);
      expect(find.text('Hoạt động gần nhất'), findsOneWidget);
      expect(find.text('v12'), findsOneWidget);
    });

    testWidgets('PA-D-04: renders Detail Page for Suspended status (VietVet Trading)',
        (tester) async {
      final vietVetOrg = FakeOrganizationData.sampleOrganizations.firstWhere(
        (o) => o.code == 'TEN-000095',
      );

      await tester.pumpWidget(buildTestableWidget(
        OrganizationDetailPage(organization: vietVetOrg),
      ));
      await tester.pumpAndSettle();

      // Header & Badge
      expect(find.text('Đã tạm ngừng'), findsOneWidget);
      expect(find.text('VietVet Trading'), findsOneWidget);

      // Red Alert Banner
      expect(find.text('Quyền vận hành đã bị chặn'), findsOneWidget);

      // Platform info
      expect(find.text('Tạm ngừng lúc'), findsOneWidget);
      expect(find.text('Tùng Nguyễn'), findsOneWidget);
      expect(find.text('Rà soát rủi ro truy cập'), findsOneWidget);
    });

    testWidgets('PA-D-05: renders Detail Page for Closed status (Hải Phòng Vet)',
        (tester) async {
      final haiPhongOrg = FakeOrganizationData.sampleOrganizations.firstWhere(
        (o) => o.code == 'TEN-000041',
      );

      await tester.pumpWidget(buildTestableWidget(
        OrganizationDetailPage(organization: haiPhongOrg),
      ));
      await tester.pumpAndSettle();

      // Header & Badge
      expect(find.text('Đã đóng'), findsOneWidget);
      expect(find.text('Hải Phòng Vet'), findsOneWidget);

      // Red Alert Banner
      expect(find.text('Tổ chức đã đóng vĩnh viễn'), findsOneWidget);

      // Platform info
      expect(find.text('Đóng lúc'), findsOneWidget);
      expect(find.text('Nhân viên vận hành nền tảng'), findsOneWidget);
      expect(find.text('Kết thúc hợp đồng dịch vụ'), findsOneWidget);

      // Bottom Bar should be hidden for Closed status
      expect(find.text('Thao tác'), findsNothing);
    });

    testWidgets('Navigation: opens detail page when tapping on organization list item & pops back',
        (tester) async {
      final module = FakeIamModule(scenario: FakeIamScenario.tenantsSearchOk);
      await tester.pumpWidget(buildTestableWidget(
        OrganizationsPage(iamModule: module),
      ));
      await tester.pumpAndSettle();

      // Tap on ASC Commerce card item
      await tester.tap(find.text('ASC Commerce'));
      await tester.pumpAndSettle();

      // Verify Detail page is shown
      expect(find.text('Chi tiết tổ chức'), findsOneWidget);
      expect(find.text('TEN-000138'), findsOneWidget);

      // Tap back button
      await tester.tap(find.byType(IconButton).first);
      await tester.pumpAndSettle();

      // Verify returned to organization list page
      expect(find.byType(VSearchBar), findsOneWidget);
      expect(find.text('Mậu Hiên'), findsOneWidget);
    });
  });
}
