import 'package:erp/features/more/presentation/bloc/iam_feature_access_cubit.dart';
import 'package:erp/features/more/presentation/pages/users_and_roles_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_application/application.dart';

void main() {
  testWidgets(
    'UsersAndRolesPage renders all hub cards from the design',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final cubit = IamFeatureAccessCubit(
        iamModule: _OwnerSessionModule(),
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

      expect(find.text('Người dùng & vai trò'), findsWidgets);
      expect(find.text('Cần hoàn tất'), findsOneWidget);
      expect(find.text('Hồ sơ tổ chức'), findsOneWidget);
      expect(find.text('Người dùng'), findsOneWidget);
      expect(find.text('Vai trò'), findsOneWidget);
      expect(find.text('Quyền sở hữu'), findsOneWidget);
      expect(find.text('Lịch sử quản trị'), findsOneWidget);
    },
  );

  testWidgets('UsersAndRolesPage shows coming soon toast for roles and ownership', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cubit = IamFeatureAccessCubit(iamModule: _OwnerSessionModule());
    await cubit.load();
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: UsersAndRolesPage(accessCubit: cubit),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Vai trò'));
    await tester.pumpAndSettle();
    expect(find.text('Chức năng làm sau'), findsOneWidget);

    await tester.tap(find.text('Quyền sở hữu'));
    await tester.pumpAndSettle();
    expect(find.text('Chức năng làm sau'), findsWidgets);
  });
}

final class _OwnerSessionModule implements IIamModule {
  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    throw UnsupportedError(command.runtimeType.toString());
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    return const SessionDto(
          isAuthenticated: true,
          userId: 'owner-1',
          role: 'owner',
        )
        as TResult;
  }
}
