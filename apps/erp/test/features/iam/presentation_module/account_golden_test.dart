// Golden 10-8k: Tài khoản của tôi (ID-21) & Chỉnh sửa thông tin (ID-22) ở 390 và 1280.
// Ảnh: docs/refactor/plans/P10/img/10-8k/flutter-<ca>-<rộng>.png
import 'dart:async';

import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/iam/data/account_repository.dart';
import 'package:erp/features/iam/data/models/my_account.dart';
import 'package:erp/features/iam/presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../receivable/presentation/receivable_test_harness.dart';
import '../support/iam_test_session.dart';
import '../support/scripted_iam_repositories.dart';

const _me = MyAccountUiModel(
  lastName: 'Nguyễn Thị',
  firstName: 'Lan',
  email: 'lan@anphat.vn',
  emailStatus: 'Đã xác minh',
  phoneNumber: '0912 345 678',
  isOwner: true,
);

const _staff = MyAccountUiModel(
  lastName: 'Nguyễn Thị',
  firstName: 'Lan',
  email: 'lan@anphat.vn',
  emailStatus: 'Đã xác minh',
  phoneNumber: '0912 345 678',
  isOwner: false,
);

const _noPhone = MyAccountUiModel(
  lastName: 'Nguyễn Thị',
  firstName: 'Lan',
  email: 'lan@anphat.vn',
  emailStatus: 'Đã xác minh',
  phoneNumber: '',
  isOwner: true,
);

Future<void> _captureAccount(
  WidgetTester tester, {
  required int width,
  required String name,
  required Widget page,
  Future<void> Function()? act,
}) async {
  final phone = width == 390;
  final view = tester.view;
  view.physicalSize = phone ? const Size(390, 844) : const Size(1280, 800);
  view.devicePixelRatio = 1;
  if (phone) {
    view.padding = const FakeViewPadding(top: 30, bottom: 34);
    view.viewPadding = const FakeViewPadding(top: 30, bottom: 34);
  }
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);
  addTearDown(tester.view.resetViewPadding);

  final key = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: VTheme.lightTheme,
      // Bọc cả Navigator để ảnh có sheet / hộp thoại nằm trên lớp phủ.
      builder: (context, child) => RepaintBoundary(key: key, child: child),
      home: page,
    ),
  );
  await tester.pump();
  await tester.pump();
  if (act != null) await act();
  await expectLater(
    find.byKey(key),
    matchesGoldenFile(
      '${repoRoot()}/docs/refactor/plans/P10/img/10-8k/flutter-$name-$width.png',
    ),
  );
}

void main() {
  setUpAll(() async {
    await loadInterFont();
  });

  for (final width in const [390, 1280]) {
    testWidgets('account__owner $width', (tester) async {
      await _captureAccount(
        tester,
        width: width,
        name: 'account__owner',
        page: const MyAccountPage(data: _me),
      );
    });

    testWidgets('account__staff $width', (tester) async {
      await _captureAccount(
        tester,
        width: width,
        name: 'account__staff',
        page: const MyAccountPage(data: _staff),
      );
    });

    testWidgets('account__no-phone $width', (tester) async {
      await _captureAccount(
        tester,
        width: width,
        name: 'account__no-phone',
        page: const MyAccountPage(data: _noPhone),
      );
    });

    testWidgets('account__error $width', (tester) async {
      final repo = ScriptedAccountRepository()
        ..getError = const AppException(AppErrorCode.network);
      final session = testSessionController(isOwner: true);
      addTearDown(session.close);
      final cubit = MyAccountCubit(accountRepository: repo, session: session);
      addTearDown(cubit.close);
      await _captureAccount(
        tester,
        width: width,
        name: 'account__error',
        page: MyAccountPage(cubit: cubit),
        act: () async {
          await cubit.load();
          await tester.pump();
        },
      );
    });

    testWidgets('account__logout $width', (tester) async {
      await _captureAccount(
        tester,
        width: width,
        name: 'account__logout',
        page: const MyAccountPage(data: _me),
        act: () async {
          await tester.tap(find.text('Đăng xuất'));
          await tester.pumpAndSettle();
        },
      );
    });

    testWidgets('account__toast-logout-failed $width', (tester) async {
      await _captureAccount(
        tester,
        width: width,
        name: 'account__toast-logout-failed',
        page: MyAccountPage(
          data: _me,
          onLogout: () async {
            final ctx = tester.element(find.byType(MyAccountPage));
            VToast.show(
              ctx,
              title: 'Đăng xuất thất bại',
              message: 'Không thể đóng phiên trên máy.',
              type: VToastType.danger,
            );
          },
        ),
        act: () async {
          await tester.tap(find.text('Đăng xuất'));
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(VButton, 'Đăng xuất').last);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
        },
      );
    });

    testWidgets('account-edit__default $width', (tester) async {
      await _captureAccount(
        tester,
        width: width,
        name: 'account-edit__default',
        page: const EditMyAccountPage(data: _me),
      );
    });

    testWidgets('account-edit__errors $width', (tester) async {
      await _captureAccount(
        tester,
        width: width,
        name: 'account-edit__errors',
        page: const EditMyAccountPage(data: _me),
        act: () async {
          final fields = find.byType(TextField);
          await tester.enterText(fields.at(0), '');
          await tester.enterText(fields.at(1), '');
          await tester.enterText(fields.at(2), '0912 34');
          await tester.pump();
          await tester.tap(find.widgetWithText(VButton, 'Lưu thay đổi'));
          await tester.pump();
          // Chữ gợi ý hiện lại có hiệu ứng mờ dần; chờ hết để ảnh có gợi ý.
          await tester.pump(const Duration(milliseconds: 300));
        },
      );
    });

    testWidgets('account-edit__submitting $width', (tester) async {
      final repo = _HangingAccountRepository();
      final cubit = MyAccountEditCubit(accountRepository: repo);
      addTearDown(cubit.close);
      await cubit.load();
      await _captureAccount(
        tester,
        width: width,
        name: 'account-edit__submitting',
        page: EditMyAccountPage(cubit: cubit),
        act: () async {
          await tester.enterText(find.byType(TextField).at(2), '0987 111 222');
          await tester.pump();
          await tester.tap(find.widgetWithText(VButton, 'Lưu thay đổi'));
          await tester.pump();
        },
      );
    });

    testWidgets('account-edit__discard $width', (tester) async {
      await _captureAccount(
        tester,
        width: width,
        name: 'account-edit__discard',
        page: const EditMyAccountPage(data: _me),
        act: () async {
          await tester.enterText(find.byType(TextField).at(2), '0987 111 222');
          await tester.pump();
          await tester.tap(find.widgetWithText(VButton, 'Hủy'));
          await tester.pumpAndSettle();
        },
      );
    });
  }
}

final class _HangingAccountRepository implements AccountRepository {
  final _inner = ScriptedAccountRepository(
    profile: const MyAccount(
      userId: 'lan',
      email: 'lan@anphat.vn',
      givenName: 'Lan',
      familyName: 'Nguyễn Thị',
      phone: '0912 345 678',
      emailVerified: true,
    ),
  );

  @override
  Future<MyAccount> getMyAccount() => _inner.getMyAccount();

  @override
  Future<MyAccount> updateMyAccount({
    String? avatarReference,
    required String givenName,
    required String familyName,
    String? phone,
  }) {
    return Completer<MyAccount>().future;
  }
}
