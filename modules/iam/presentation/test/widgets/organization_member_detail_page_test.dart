import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_iam_presentation/src/users/models/user_ui_model.dart';
import 'package:vet45_iam_presentation/src/users/views/organization_member_detail_page.dart';

void main() {
  const sampleMember = MemberUiModel(
    id: 'mem-1',
    name: 'Nguyễn Văn Minh',
    email: 'minh@minhphat.vn',
    role: 'Nhân viên bán hàng',
    status: MemberStatus.active,
    identityText: 'Chỉ đọc',
    joinedDate: '12/07/2026',
    lastActiveDate: '14/07/2026 · 09:18',
    dataVersion: 'v8',
  );

  testWidgets(
      'OrganizationMemberDetailPage renders member details and handles action bottom sheet',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OrganizationMemberDetailPage(member: sampleMember),
      ),
    );
    await tester.pumpAndSettle();

    // Verify title & summary
    expect(find.text('Chi tiết thành viên'), findsOneWidget);
    expect(find.text('Nguyễn Văn Minh'), findsOneWidget);
    expect(find.text('minh@minhphat.vn · Nhân viên bán hàng'), findsOneWidget);
    expect(find.text('Danh tính Chỉ đọc'), findsOneWidget);
    expect(find.text('Hoạt động'), findsOneWidget);

    // Verify section cards & detail rows
    expect(find.text('Thông tin thành viên'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('minh@minhphat.vn'), findsOneWidget);
    expect(find.text('Vai trò hiện hành'), findsOneWidget);
    expect(find.text('Nhân viên bán hàng'), findsOneWidget);
    expect(find.text('Danh tính'), findsOneWidget);
    expect(find.text('Chỉ đọc'), findsOneWidget);

    expect(find.text('Trạng thái truy cập'), findsOneWidget);
    expect(find.text('Ngày tham gia'), findsOneWidget);
    expect(find.text('12/07/2026'), findsOneWidget);
    expect(find.text('Hoạt động gần nhất'), findsOneWidget);
    expect(find.text('14/07/2026 · 09:18'), findsOneWidget);
    expect(find.text('Phiên bản dữ liệu'), findsOneWidget);
    expect(find.text('v8'), findsOneWidget);

    // Tap Thao tác -> opens action bottom sheet
    await tester.tap(find.text('Thao tác'));
    await tester.pumpAndSettle();

    expect(find.text('Thao tác thành viên'), findsOneWidget);
    expect(find.text('Thay đổi vai trò'), findsOneWidget);
    expect(find.text('Tạm ngừng thành viên'), findsOneWidget);
    expect(find.text('Loại khỏi tổ chức'), findsOneWidget);

    // Tap 'Tạm ngừng thành viên' -> opens confirmation bottom sheet
    await tester.tap(find.text('Tạm ngừng thành viên'));
    await tester.pumpAndSettle();

    expect(find.text('Tạm ngừng thành viên?'), findsOneWidget);
    expect(find.text('Thành viên mất quyền truy cập tới khi được kích hoạt lại.'), findsOneWidget);

    // Tap 'Tạm ngừng' -> updates status to suspended & shows VToast and VBanner
    await tester.tap(find.text('Tạm ngừng').last);
    await tester.pumpAndSettle();

    expect(find.text('Đã tạm ngừng thành viên.'), findsOneWidget);
    expect(find.text('Quyền truy cập đã tạm ngừng'), findsOneWidget);
    expect(find.text('Tạm ngừng lúc'), findsOneWidget);

    // Tap Thao tác -> opens action bottom sheet for suspended user
    await tester.tap(find.text('Thao tác'));
    await tester.pumpAndSettle();

    expect(find.text('Kích hoạt lại'), findsOneWidget);

    // Tap 'Kích hoạt lại' -> opens confirmation bottom sheet
    await tester.tap(find.text('Kích hoạt lại'));
    await tester.pumpAndSettle();

    expect(find.text('Kích hoạt lại thành viên?'), findsOneWidget);
    expect(find.text('Quyền truy cập sẽ được khôi phục theo vai trò hiện hành.'), findsOneWidget);

    // Tap 'Kích hoạt lại' in confirmation sheet -> updates status to active
    await tester.tap(find.text('Kích hoạt lại').last);
    await tester.pumpAndSettle();

    expect(find.text('Đã kích hoạt lại thành viên.'), findsOneWidget);
    expect(find.text('Hoạt động'), findsOneWidget);

    // Tap Thao tác -> opens action bottom sheet to test 'Loại khỏi tổ chức'
    await tester.tap(find.text('Thao tác'));
    await tester.pumpAndSettle();

    expect(find.text('Loại khỏi tổ chức'), findsOneWidget);

    // Tap 'Loại khỏi tổ chức' -> opens TA-O-05 Remove Confirmation sheet
    await tester.tap(find.text('Loại khỏi tổ chức'));
    await tester.pumpAndSettle();

    expect(find.text('Loại thành viên khỏi tổ chức?'), findsOneWidget);
    expect(
      find.text('Membership sẽ kết thúc vĩnh viễn. Người này cần lời mời mới nếu quay lại.'),
      findsOneWidget,
    );

    // Tap 'Loại thành viên' button in confirmation sheet
    await tester.tap(find.text('Loại thành viên').last);
    await tester.pumpAndSettle();

    expect(find.text('Đã loại thành viên khỏi tổ chức.'), findsOneWidget);
    expect(find.text('Thành viên đã được loại'), findsOneWidget);
    expect(find.text('Đã loại'), findsOneWidget);
    expect(find.text('Đã loại lúc'), findsOneWidget);
    expect(find.text('14/07/2026 · 09:45'), findsOneWidget);
    expect(find.text('Vai trò trước đó'), findsOneWidget);
    expect(find.text('Thao tác'), findsNothing);
  });
}
