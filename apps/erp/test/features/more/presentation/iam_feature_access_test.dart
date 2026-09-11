import 'dart:async';

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
import 'package:vet45_shared_application/application.dart';

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
      expect(access.canViewReadiness, isTrue);
      expect(access.canActivateTenant, isTrue);
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
      iamModule: _StaticSessionModule(
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

  testWidgets(
    'UsersAndRolesPage shows owner entries without an unverified readiness banner',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final cubit = IamFeatureAccessCubit(
        iamModule: _StaticSessionModule(
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
      expect(find.text('Quyền sở hữu'), findsOneWidget);
      expect(find.text('Lịch sử quản trị'), findsOneWidget);
      expect(find.text('Cần hoàn tất'), findsNothing);
    },
  );

  testWidgets(
    'UsersAndRolesPage never flashes readiness banner while active state loads',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final module = _DelayedReadinessModule();

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: UsersAndRolesPage(iamModule: module),
        ),
      );
      await tester.pump();

      expect(find.text('Hồ sơ tổ chức'), findsOneWidget);
      expect(find.byKey(const Key('iam_readiness_hub_banner')), findsNothing);
      expect(find.text('Cần hoàn tất'), findsNothing);
      final skeletonFinder = find.byKey(const Key('iam_readiness_hub_banner_skeleton'));
      expect(skeletonFinder, findsOneWidget);
      final skeletonWidget = tester.widget<VSkeleton>(skeletonFinder);
      expect(skeletonWidget.height, 148);
      expect(skeletonWidget.borderRadius, VRadius.card);

      module.completeReadiness(
        TenantReadinessDto(
          tenantId: 'org-001',
          status: TenantLifecycleStatus.active,
          blockers: const [],
          warnings: const [],
          evaluatedAt: DateTime.utc(2026, 8, 25),
          tenantVersion: 3,
          canActivate: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('iam_readiness_hub_banner_skeleton')), findsNothing);
      expect(find.byKey(const Key('iam_readiness_hub_banner')), findsNothing);
      expect(find.text('Cần hoàn tất'), findsNothing);
    },
  );

  testWidgets(
    'UsersAndRolesPage banner body derives blocker count from readiness DTO',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final cubit = IamFeatureAccessCubit(
        iamModule: _SessionWithReadinessModule(
          session: const SessionDto(
            isAuthenticated: true,
            userId: 'owner-1',
            role: 'store_owner',
            isOwner: true,
            tenantId: 'org-001',
          ),
          readiness: TenantReadinessDto(
            tenantId: 'org-001',
            status: TenantLifecycleStatus.provisioning,
            blockers: const [
              TenantReadinessIssueCodes.contactEmailMissingOrInvalid,
              TenantReadinessIssueCodes.ownerEmailUnverified,
            ],
            warnings: const [],
            evaluatedAt: DateTime.utc(2026, 7, 31),
            tenantVersion: 1,
            canActivate: false,
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

      expect(find.byKey(const Key('iam_readiness_hub_banner')), findsOneWidget);
      expect(
        find.text(
          'Còn 2 điều kiện bắt buộc trước khi có thể bắt đầu vận hành.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'UsersAndRolesPage groups multiple profile blockers into a single unmet condition on banner',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final cubit = IamFeatureAccessCubit(
        iamModule: _SessionWithReadinessModule(
          session: const SessionDto(
            isAuthenticated: true,
            userId: 'owner-1',
            role: 'store_owner',
            isOwner: true,
            tenantId: 'org-001',
          ),
          readiness: TenantReadinessDto(
            tenantId: 'org-001',
            status: TenantLifecycleStatus.provisioning,
            blockers: const [
              TenantReadinessIssueCodes.contactEmailMissingOrInvalid,
              TenantReadinessIssueCodes.contactPhoneMissingOrInvalid,
              TenantReadinessIssueCodes.contactAddressMissing,
            ],
            warnings: const [],
            evaluatedAt: DateTime.utc(2026, 7, 31),
            tenantVersion: 1,
            canActivate: false,
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

      expect(find.byKey(const Key('iam_readiness_hub_banner')), findsOneWidget);
      expect(
        find.text(
          'Còn 1 điều kiện bắt buộc trước khi có thể bắt đầu vận hành.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'UsersAndRolesPage shows ready-to-activate banner from readiness DTO',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final cubit = IamFeatureAccessCubit(
        iamModule: _SessionWithReadinessModule(
          session: const SessionDto(
            isAuthenticated: true,
            userId: 'owner-1',
            role: 'store_owner',
            isOwner: true,
            tenantId: 'org-001',
          ),
          readiness: TenantReadinessDto(
            tenantId: 'org-001',
            status: TenantLifecycleStatus.provisioning,
            blockers: const [],
            warnings: const [],
            evaluatedAt: DateTime.utc(2026, 8, 4),
            tenantVersion: 2,
            canActivate: true,
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

      expect(find.byKey(const Key('iam_readiness_hub_banner')), findsOneWidget);
      expect(find.text('Sẵn sàng kích hoạt'), findsOneWidget);
      expect(find.text('Tổ chức đã sẵn sàng kích hoạt'), findsOneWidget);
      expect(
        find.text('Kích hoạt tổ chức để có thể bắt đầu vận hành.'),
        findsOneWidget,
      );
      expect(find.text('Tổ chức chưa hoàn tất thiết lập'), findsNothing);
    },
  );

  testWidgets(
    'UsersAndRolesPage hides readiness banner for active ready tenant',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final cubit = IamFeatureAccessCubit(
        iamModule: _SessionWithReadinessModule(
          session: const SessionDto(
            isAuthenticated: true,
            userId: 'owner-1',
            role: 'store_owner',
            isOwner: true,
            tenantId: 'org-001',
          ),
          readiness: TenantReadinessDto(
            tenantId: 'org-001',
            status: TenantLifecycleStatus.active,
            blockers: const [],
            warnings: const [],
            evaluatedAt: DateTime.utc(2026, 8, 4),
            tenantVersion: 3,
            canActivate: false,
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

      expect(find.byKey(const Key('iam_readiness_hub_banner')), findsNothing);
      expect(find.text('Cần hoàn tất'), findsNothing);
      expect(find.text('Sẵn sàng kích hoạt'), findsNothing);
    },
  );

  testWidgets(
    'UsersAndRolesPage hides readiness banner for active tenant with legal warning',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final cubit = IamFeatureAccessCubit(
        iamModule: _SessionWithReadinessModule(
          session: const SessionDto(
            isAuthenticated: true,
            userId: 'owner-1',
            role: 'store_owner',
            isOwner: true,
            tenantId: 'org-001',
          ),
          readiness: TenantReadinessDto(
            tenantId: 'org-001',
            status: TenantLifecycleStatus.active,
            blockers: const [],
            warnings: const [TenantReadinessIssueCodes.legalProfileMissing],
            evaluatedAt: DateTime.utc(2026, 8, 4),
            tenantVersion: 4,
            canActivate: false,
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

      expect(find.byKey(const Key('iam_readiness_hub_banner')), findsNothing);
      expect(find.text('Cần hoàn tất'), findsNothing);
      expect(find.textContaining('trước khi kích hoạt'), findsNothing);
    },
  );

  testWidgets(
    'UsersAndRolesPage hides readiness banner and skips readiness query without permission',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final module = _SessionWithoutReadinessPermissionModule(
        session: const SessionDto(
          isAuthenticated: true,
          userId: 'staff-1',
          role: 'staff',
          tenantId: 'org-001',
          permissions: [IamPermissions.memberView],
        ),
      );
      final cubit = IamFeatureAccessCubit(iamModule: module);
      await cubit.load();
      addTearDown(cubit.close);

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: UsersAndRolesPage(accessCubit: cubit),
        ),
      );
      await tester.pumpAndSettle();

      expect(module.readinessQueries, 0);
      expect(find.byKey(const Key('iam_readiness_hub_banner')), findsNothing);
    },
  );
}

final class _StaticSessionModule implements IIamModule {
  _StaticSessionModule(this.session);

  final SessionDto session;

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    throw UnsupportedError(command.runtimeType.toString());
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    if (query is GetCurrentSessionQuery) {
      return session as TResult;
    }
    throw UnsupportedError(query.runtimeType.toString());
  }
}

final class _SessionWithReadinessModule implements IIamModule {
  _SessionWithReadinessModule({
    required this.session,
    required this.readiness,
  });

  final SessionDto session;
  final TenantReadinessDto readiness;

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    throw UnsupportedError(command.runtimeType.toString());
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    if (query is GetCurrentSessionQuery) {
      return session as TResult;
    }
    if (query is GetTenantReadinessQuery) {
      return readiness as TResult;
    }
    throw UnsupportedError(query.runtimeType.toString());
  }
}

final class _DelayedReadinessModule implements IIamModule {
  final Completer<TenantReadinessDto> _readiness = Completer<TenantReadinessDto>();

  void completeReadiness(TenantReadinessDto readiness) {
    _readiness.complete(readiness);
  }

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    throw UnsupportedError(command.runtimeType.toString());
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    if (query is GetCurrentSessionQuery) {
      return const SessionDto(
            isAuthenticated: true,
            userId: 'owner-1',
            role: 'store_owner',
            isOwner: true,
            tenantId: 'org-001',
          )
          as TResult;
    }
    if (query is GetTenantReadinessQuery) {
      return await _readiness.future as TResult;
    }
    throw UnsupportedError(query.runtimeType.toString());
  }
}

final class _SessionWithoutReadinessPermissionModule implements IIamModule {
  _SessionWithoutReadinessPermissionModule({required this.session});

  final SessionDto session;
  int readinessQueries = 0;

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    throw UnsupportedError(command.runtimeType.toString());
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    if (query is GetCurrentSessionQuery) {
      return session as TResult;
    }
    if (query is GetTenantReadinessQuery) {
      readinessQueries++;
      throw UnsupportedError(query.runtimeType.toString());
    }
    throw UnsupportedError(query.runtimeType.toString());
  }
}
