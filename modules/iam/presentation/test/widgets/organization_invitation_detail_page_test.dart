import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_iam_presentation/presentation.dart';

void main() {
  testWidgets(
      'OrganizationInvitationDetailPage renders TA-D-05 pending status layout and action sheet',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: OrganizationInvitationDetailPage(
          invitation: InvitationUiModel(
            id: 'i2',
            email: 'banhang@minhphat.vn',
            role: 'Nhân viên bán hàng',
            statusDetail: 'Nhân viên bán hàng · Hết hạn sau 7 ngày',
            status: InvitationStatus.pending,
          ),
        ),
      ),
    );

    // Title & Summary card
    expect(find.text('Chi tiết lời mời'), findsWidgets);
    expect(find.text('banhang@minhphat.vn'), findsOneWidget);
    expect(find.text('Đang chờ'), findsOneWidget);
    expect(find.text('Nhân viên bán hàng · Thú y Minh Phát'), findsOneWidget);
    expect(find.text('Đang chờ người nhận phản hồi'), findsOneWidget);

    // Detail info card
    expect(find.text('Thông tin lời mời'), findsOneWidget);
    expect(find.text('Tổ chức'), findsOneWidget);
    expect(find.text('Thú y Minh Phát'), findsWidgets);
    expect(find.text('Ngày gửi'), findsOneWidget);
    expect(find.text('14/07/2026 · 17:05'), findsOneWidget);
    expect(find.text('Hết hạn'), findsOneWidget);
    expect(find.text('21/07/2026 · 17:05'), findsOneWidget);
    expect(find.text('Trạng thái email'), findsOneWidget);
    expect(find.text('Đã gửi'), findsOneWidget);

    // Notice box
    expect(find.text('Đang chờ người nhận'), findsOneWidget);
    expect(
      find.text(
          'Người nhận chưa chấp nhận lời mời. Có thể gửi lại hoặc thu hồi trong mục Thao tác.'),
      findsOneWidget,
    );

    // Bottom action button
    expect(find.text('Thao tác'), findsOneWidget);

    // Tap 'Thao tác' -> opens TA-O-01 Action Bottom Sheet
    await tester.tap(find.text('Thao tác'));
    await tester.pumpAndSettle();

    expect(find.text('Thao tác lời mời'), findsOneWidget);
    expect(find.text('Gửi lại lời mời'), findsOneWidget);
    expect(find.text('Sao chép liên kết'), findsNothing); // Option removed
    expect(find.text('Thu hồi lời mời'), findsOneWidget);

    // Tap 'Thu hồi lời mời' in TA-O-01 -> opens TA-O-02 Revoke Confirmation Sheet
    await tester.tap(find.text('Thu hồi lời mời'));
    await tester.pumpAndSettle();

    expect(find.text('Thu hồi lời mời?'), findsOneWidget);
    expect(
      find.text(
          'Người nhận sẽ không thể dùng liên kết hiện tại để tham gia tổ chức.'),
      findsOneWidget,
    );
    expect(find.text('Quay lại'), findsOneWidget);

    // Tap 'Quay lại' -> closes TA-O-02
    await tester.tap(find.text('Quay lại'));
    await tester.pumpAndSettle();

    expect(find.text('Thu hồi lời mời?'), findsNothing);
  });

  testWidgets(
      'OrganizationInvitationDetailPage renders TA-D-07 failed send status layout',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: OrganizationInvitationDetailPage(
          invitation: InvitationUiModel(
            id: 'i1',
            email: 'ketoan@minhphat.vn',
            role: 'Kế toán',
            statusDetail: 'Kế toán · Lỗi gửi',
            status: InvitationStatus.failed,
          ),
        ),
      ),
    );

    expect(find.text('ketoan@minhphat.vn'), findsOneWidget);
    expect(find.text('Lỗi gửi'), findsOneWidget);
    expect(find.text('Lời mời còn hiệu lực · Email chưa gửi'), findsOneWidget);
    expect(find.text('Ngày tạo'), findsOneWidget);
    expect(find.text('Gửi thất bại'), findsOneWidget);
    expect(find.text('Không gửi được email'), findsOneWidget);
    expect(
      find.text(
          'Lời mời vẫn còn hiệu lực. Hãy gửi lại email hoặc thu hồi lời mời.'),
      findsOneWidget,
    );
  });

  testWidgets(
      'OrganizationInvitationDetailPage renders TA-D-06 expiring status layout',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: OrganizationInvitationDetailPage(
          invitation: InvitationUiModel(
            id: 'i3',
            email: 'kho@minhphat.vn',
            role: 'Thủ kho',
            statusDetail: 'Thủ kho · Sắp hết hạn',
            status: InvitationStatus.expiring,
          ),
        ),
      ),
    );

    expect(find.text('kho@minhphat.vn'), findsOneWidget);
    expect(find.text('Sắp hết hạn'), findsWidgets);
    expect(find.text('Hết hạn trong 1 ngày'), findsOneWidget);
    expect(find.text('Ngày gửi'), findsOneWidget);
    expect(find.text('Đã gửi'), findsOneWidget);
    expect(
      find.text(
          'Lời mời sẽ hết hạn trong 1 ngày. Gửi lại để tạo lời mời mới với thời hạn mới.'),
      findsOneWidget,
    );
  });
}
