import 'package:erp/features/more/presentation/bloc/iam_feature_access_cubit.dart';
import 'package:erp/features/more/presentation/bloc/iam_feature_access_state.dart';
import 'package:erp/features/more/presentation/pages/more_page.dart';
import 'package:erp/features/more/presentation/pages/users_and_roles_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_domain/domain.dart';
import 'package:erp/features/iam/presentation.dart';

import '../../iam/support/iam_module_repositories.dart';

void main() {
  group('IamFeatureAccessState permissions', () {
    test('maps SessionDto.hasPermission for active capabilities', () {
      const session = SessionDto(
        isAuthenticated: true,
        userId: 'u1',
        role: 'staff',
        permissions: [IamPermissions.memberView],
      );
      const access = IamFeatureAccessState(
        status: IamLoadStatus.success,
        session: session,
      );

      expect(access.canViewMembers, isTrue);
      expect(access.canInviteMembers, isFalse);
      expect(access.canViewTenantAudit, isFalse);
      // Hub "Người dùng & vai trò" là owner-only — member thường không mở được.
      expect(access.canOpenIamHub, isFalse);
    });

    test('owner role grants all mapped permissions via hasPermission', () {
      const session = SessionDto(
        isAuthenticated: true,
        userId: 'owner-1',
        role: 'store_owner',
        isOwner: true,
        permissions: [],
      );
      const access = IamFeatureAccessState(
        status: IamLoadStatus.success,
        session: session,
      );

      expect(access.canViewMembers, isTrue);
      expect(access.canInviteMembers, isTrue);
      expect(access.canUpdateMemberStatus, isTrue);
      expect(access.canRemoveMember, isTrue);
      expect(access.canViewTenantProfile, isTrue);
      expect(access.canUpdateTenantProfile, isTrue);
      expect(access.canUpdateLegalProfile, isTrue);
      expect(access.canViewTenantAudit, isTrue);
      expect(access.canOpenIamHub, isTrue);
    });
  });

  testWidgets('MorePage hides IAM hub without open capability', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cubit = IamFeatureAccessCubit(
      session: sessionFromDto(
        const SessionDto(
          isAuthenticated: true,
          userId: 'u1',
          role: 'staff',
          permissions: [],
        ),
      ),
    );
    await cubit.load();
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: Scaffold(
          body: MorePage(accessCubit: cubit),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Người dùng & vai trò'), findsNothing);
    expect(find.text('Tài khoản của tôi'), findsOneWidget);
  });

  testWidgets('MorePage shows the platform group only for a platform admin', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cubit = IamFeatureAccessCubit(
      session: sessionFromDto(
        const SessionDto(isAuthenticated: true, userId: 'u1', role: 'staff', permissions: []),
      ),
    );
    await cubit.load();
    addTearDown(cubit.close);

    Future<void> pumpMore({required bool isPlatformAdmin}) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: MorePage(accessCubit: cubit, isPlatformAdmin: isPlatformAdmin),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await pumpMore(isPlatformAdmin: false);
    expect(find.text('QUẢN TRỊ NỀN TẢNG'), findsNothing);
    expect(find.byKey(const Key('more_platform_organizations')), findsNothing);

    await pumpMore(isPlatformAdmin: true);
    expect(find.text('QUẢN TRỊ NỀN TẢNG'), findsOneWidget);
    expect(find.text('Tổ chức'), findsOneWidget);
    expect(find.text('Tạm ngừng, khôi phục, đóng, chuyển chủ sở hữu'), findsOneWidget);
    // Đăng xuất vẫn là mục cuối.
    expect(find.text('Đăng xuất'), findsOneWidget);
  });

  testWidgets('MorePage keeps personal actions when tenant is blocked', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cubit = IamFeatureAccessCubit(
      session: sessionFromDto(
        const SessionDto(
          isAuthenticated: true,
          userId: 'owner-1',
          role: 'store_owner',
          isOwner: true,
          permissions: [],
        ),
      ),
    );
    await cubit.load();
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: Scaffold(
          body: MorePage(
            accessCubit: cubit,
            tenantBlocked: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Đăng xuất'), findsOneWidget);
    expect(find.text('Tài khoản của tôi'), findsOneWidget);

    final logoutCard = tester.widget<VCard>(
      find.ancestor(
        of: find.text('Đăng xuất'),
        matching: find.byType(VCard),
      ).first,
    );
    expect(logoutCard.onTap, isNotNull);

    final settingsCard = tester.widget<VCard>(
      find.ancestor(
        of: find.text('Thiết lập'),
        matching: find.byType(VCard),
      ).first,
    );
    expect(settingsCard.onTap, isNull);

    final pricingCard = tester.widget<VCard>(
      find.ancestor(
        of: find.text('Giá riêng / Nhớ giá'),
        matching: find.byType(VCard),
      ).first,
    );
    expect(pricingCard.onTap, isNull);

    final usersCard = tester.widget<VCard>(
      find.ancestor(
        of: find.text('Người dùng & vai trò'),
        matching: find.byType(VCard),
      ).first,
    );
    expect(usersCard.onTap, isNull);
  });

  testWidgets('MorePage keeps the IAM hub disabled when the tenant is blocked', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: Scaffold(
          body: MorePage(
            session: sessionFromDto(
              const SessionDto(
                isAuthenticated: true,
                userId: 'owner-1',
                role: 'store_owner',
                isOwner: true,
                tenantId: 'org-001',
                permissions: [],
              ),
            ),
            tenantBlocked: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Người dùng & vai trò'), findsOneWidget);

    final usersCard = tester.widget<VCard>(
      find.ancestor(
        of: find.text('Người dùng & vai trò'),
        matching: find.byType(VCard),
      ).first,
    );
    expect(usersCard.onTap, isNull);
  });

  testWidgets(
    'UsersAndRolesPage shows owner entries and hides ownership',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final cubit = IamFeatureAccessCubit(
        session: sessionFromDto(
          const SessionDto(
            isAuthenticated: true,
            userId: 'owner-1',
            role: 'store_owner',
            isOwner: true,
          ),
        ),
      );
      await cubit.load();
      addTearDown(cubit.close);

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: UsersAndRolesPage(accessCubit: cubit),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hồ sơ tổ chức'), findsOneWidget);
      expect(find.text('Người dùng'), findsOneWidget);
      expect(find.text('Vai trò'), findsOneWidget);
      expect(find.text('Quyền sở hữu'), findsNothing);
      expect(find.text('Lịch sử quản trị'), findsOneWidget);
      expect(find.text('Cần hoàn tất'), findsNothing);
    },
  );
}
