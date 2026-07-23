import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_presentation/presentation.dart';
import 'package:vet45_iam_presentation/src/users/widgets/invitation_filter_bottom_sheet.dart';
import 'package:vet45_iam_presentation/src/users/widgets/member_filter_bottom_sheet.dart';

void main() {
  testWidgets('OrganizationUsersPage renders member tab by default (TA-D-01)', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: OrganizationUsersPage(),
      ),
    );

    // Header & title
    expect(find.text('Người dùng'), findsWidgets);
    expect(find.text('3 thành viên'), findsOneWidget);

    // Search bar
    expect(find.byType(VSearchBar), findsOneWidget);

    // Filter chips for member tab
    expect(find.text('Tất cả'), findsWidgets);
    expect(find.text('Hoạt động'), findsWidgets);
    expect(find.text('Tạm ngừng'), findsWidgets);

    // Member list items
    expect(find.text('Nguyễn Văn Minh'), findsOneWidget);
    expect(find.text('minh@minhphat.vn · Nhân viên bán hàng'), findsOneWidget);
    expect(find.text('Phạm Ngọc Mai'), findsOneWidget);
    expect(find.text('mai@minhphat.vn · Thủ kho'), findsOneWidget);
    expect(find.text('Trần Thị Hoa'), findsOneWidget);
    expect(find.text('hoa@minhphat.vn · Kế toán'), findsOneWidget);
  });

  testWidgets('OrganizationUsersPage switches to invitation tab (TA-D-02)', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: OrganizationUsersPage(),
      ),
    );

    // Tap 'Lời mời' tab
    await tester.tap(find.text('Lời mời'));
    await tester.pumpAndSettle();

    // Subtitle counter updates
    expect(find.text('3 lời mời'), findsOneWidget);

    // Invitation items present
    expect(find.text('ketoan@minhphat.vn'), findsOneWidget);
    expect(find.text('Kế toán · Đã tạo · Chưa gửi được email'), findsOneWidget);
    expect(find.text('banhang@minhphat.vn'), findsOneWidget);
    expect(find.text('Nhân viên bán hàng · Hết hạn sau 7 ngày'), findsOneWidget);
    expect(find.text('kho@minhphat.vn'), findsOneWidget);
    expect(find.text('Thủ kho · Hết hạn trong 1 ngày'), findsOneWidget);

    // Badges present
    expect(find.text('Lỗi gửi'), findsOneWidget);
    expect(find.text('Đang chờ'), findsWidgets);
    expect(find.text('Sắp hết hạn'), findsWidgets);
  });

  testWidgets('OrganizationUsersPage filter chips filter members correctly', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: OrganizationUsersPage(),
      ),
    );

    // Tap 'Tạm ngừng' filter chip
    await tester.tap(find.text('Tạm ngừng').first);
    await tester.pumpAndSettle();

    // Only 1 member matched
    expect(find.text('Trần Thị Hoa'), findsOneWidget);
    expect(find.text('Nguyễn Văn Minh'), findsNothing);
    expect(find.text('1 thành viên'), findsOneWidget);
  });

  testWidgets('OrganizationUsersPage renders empty state TA-S-01 when members list is empty', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: OrganizationUsersPage(
          initialMembers: [],
          initialInvitations: [],
        ),
      ),
    );

    // Empty state heading & subtitle
    expect(find.text('Chưa có thành viên khác'), findsOneWidget);
    expect(find.text('Mời thêm người dùng để cùng vận hành tổ chức.'), findsOneWidget);
    expect(find.text('Mời thành viên'), findsWidgets);
  });

  testWidgets(
    'OrganizationUsersPage renders no search result state TA-S-02 when query matches nothing',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: OrganizationUsersPage(),
        ),
      );

      // Search query with no match
      await tester.enterText(find.byType(TextField), 'unknown_email_search');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // Title & subtitle for 0 search result
      expect(find.text('0 kết quả'), findsOneWidget);
      expect(find.text('Không tìm thấy kết quả'), findsOneWidget);
      expect(find.text('Thử từ khóa khác hoặc xóa bộ lọc đang áp dụng.'), findsOneWidget);
      expect(find.text('Xóa bộ lọc'), findsOneWidget);

      // Tap 'Xóa bộ lọc' clears search
      await tester.tap(find.text('Xóa bộ lọc'));
      await tester.pumpAndSettle();

      expect(find.text('3 thành viên'), findsOneWidget);
      expect(find.text('Nguyễn Văn Minh'), findsOneWidget);
    },
  );

  testWidgets('OrganizationUsersPage renders error state TA-S-03 when hasError is true', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    bool retryCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationUsersPage(
          hasError: true,
          onRetry: () {
            retryCalled = true;
          },
        ),
      ),
    );

    // Header & Error card
    expect(find.text('Không tải được'), findsOneWidget);
    expect(find.text('Không thể tải danh sách'), findsOneWidget);
    expect(find.text('Đã xảy ra lỗi khi tải thành viên. Vui lòng thử lại.'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);

    // Tap 'Thử lại'
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();

    expect(retryCalled, isTrue);
    expect(find.text('3 thành viên'), findsOneWidget);
  });

  testWidgets('Revoking invitation from list page returns to list page with VToast', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: OrganizationUsersPage(),
      ),
    );

    // Switch to Lời mời tab
    await tester.tap(find.text('Lời mời'));
    await tester.pumpAndSettle();

    // Tap an invitation card -> opens Detail Page
    await tester.tap(find.text('banhang@minhphat.vn'));
    await tester.pumpAndSettle();

    expect(find.text('Chi tiết lời mời'), findsWidgets);

    // Tap Thao tác -> Thu hồi lời mời -> Confirm
    await tester.tap(find.text('Thao tác'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thu hồi lời mời'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thu hồi lời mời').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Returned to List Page & VToast shown
    expect(find.text('Người dùng'), findsWidgets);
    expect(find.text('Đã thu hồi lời mời.'), findsOneWidget);
  });

  testWidgets(
    'Creating invitation then revoking from detail page returns to list page with VToast',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: OrganizationUsersPage(),
        ),
      );

      // Switch to Lời mời tab where FAB is visible
      await tester.tap(find.text('Lời mời'));
      await tester.pumpAndSettle();

      // Tap FAB (+) -> opens Invite Member page
      await tester.tap(find.byWidgetPredicate((w) => w is VIcon && w.icon == VIcons.add));
      await tester.pumpAndSettle();

      expect(find.text('Mời thành viên'), findsWidgets);

      // Enter email & submit -> opens Detail Page with Toast
      await tester.enterText(find.byType(TextField), 'newinvite@minhphat.vn');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gửi lời mời'));
      await tester.pumpAndSettle();

      expect(find.text('Chi tiết lời mời'), findsWidgets);
      expect(find.text('newinvite@minhphat.vn'), findsWidgets);
      expect(find.text('Đã gửi lời mời thành công.'), findsOneWidget);

      // Tap Thao tác -> Thu hồi lời mời -> Confirm
      await tester.tap(find.text('Thao tác'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thu hồi lời mời'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thu hồi lời mời').last);
      await tester.pumpAndSettle();

      // Returned to List Page & VToast shown
      expect(find.text('Người dùng'), findsWidgets);
      expect(find.text('Đã thu hồi lời mời.'), findsOneWidget);
    },
  );

  testWidgets(
    'OrganizationUsersPage filter button opens MemberFilterBottomSheet and InvitationFilterBottomSheet',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OrganizationUsersPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap filter button on Member tab -> opens TA-BS-01
      await tester.tap(find.byType(IconButton).first);
      await tester.pumpAndSettle();

      expect(find.text('Bộ lọc thành viên'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(MemberFilterBottomSheet),
          matching: find.text('Hoạt động'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(MemberFilterBottomSheet),
          matching: find.text('Áp dụng'),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Invitation tab
      await tester.tap(find.text('Lời mời'));
      await tester.pumpAndSettle();

      // Tap filter button on Invitation tab -> opens TA-BS-02
      await tester.tap(find.byType(IconButton).first);
      await tester.pumpAndSettle();

      expect(find.text('Bộ lọc lời mời'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(InvitationFilterBottomSheet),
          matching: find.text('Áp dụng'),
        ),
      );
      await tester.pumpAndSettle();
    },
  );

  testWidgets('OrganizationUsersPage handles pull to refresh', (WidgetTester tester) async {
    bool retried = false;
    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationUsersPage(
          onRetry: () {
            retried = true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Perform pull to refresh drag
    await tester.fling(find.byType(ListView).first, const Offset(0, 300), 1000);
    await tester.pumpAndSettle();

    expect(retried, isTrue);
  });

  testWidgets('Tapping MemberCard in OrganizationUsersPage opens OrganizationMemberDetailPage', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OrganizationUsersPage(),
      ),
    );
    await tester.pumpAndSettle();

    // Tap first MemberCard
    await tester.tap(find.text('Nguyễn Văn Minh'));
    await tester.pumpAndSettle();

    expect(find.text('Chi tiết thành viên'), findsOneWidget);
    expect(find.text('Nguyễn Văn Minh'), findsWidgets);
    expect(find.text('Thông tin thành viên'), findsOneWidget);
    expect(find.text('Trạng thái truy cập'), findsOneWidget);
  });

  testWidgets('OrganizationUsersPage renders unauthorized empty state when isUnauthorized is true', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OrganizationUsersPage(
          isUnauthorized: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chưa cấp quyền'), findsOneWidget);
    expect(find.text('Bạn không có quyền quản lý'), findsOneWidget);
    expect(
      find.text('Liên hệ Chủ tổ chức hoặc Quản trị viên để được cấp quyền phù hợp.'),
      findsOneWidget,
    );
    expect(find.text('Quay lại'), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is VIcon && w.icon == VIcons.add), findsNothing);
  });
}
