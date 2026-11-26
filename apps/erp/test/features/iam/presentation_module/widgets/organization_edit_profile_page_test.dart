import 'package:erp/features/iam/presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';

import '../../support/scripted_iam_repositories.dart';

void main() {
  testWidgets('wgt_e02_u02_fr01_01: edit profile submits UpdateTenantProfileCommand', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = ScriptedOrganizationRepository(mode: OrganizationScript.updateOk);
    final cubit = OrganizationProfileCubit(organizationRepository: repository);
    await cubit.load();

    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationEditProfilePage(cubit: cubit),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chỉnh thông tin tổ chức'), findsOneWidget);
    expect(find.text('Lưu thay đổi'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Mậu Hiên Updated');
    await tester.tap(find.widgetWithText(VButton, 'Lưu thay đổi'));
    await tester.pumpAndSettle();

    expect(repository.updates, hasLength(1));
    expect(repository.updates.single['displayName'], 'Mậu Hiên Updated');
    await cubit.close();
  });

  testWidgets('marks readiness blocker contact fields as required', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cubit = OrganizationProfileCubit(
      organizationRepository: ScriptedOrganizationRepository(),
    );
    await cubit.load();

    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationEditProfilePage(cubit: cubit),
      ),
    );
    await tester.pumpAndSettle();

    expect(_fieldLabel('Tên tổ chức', isRequired: true), findsOneWidget);
    expect(_fieldLabel('Số điện thoại', isRequired: true), findsOneWidget);
    expect(_fieldLabel('Email liên hệ', isRequired: true), findsOneWidget);
    expect(_fieldLabel('Địa chỉ liên hệ', isRequired: true), findsOneWidget);
    expect(_fieldLabel('Tỉnh / thành phố', isRequired: true), findsNothing);
    expect(_fieldLabel('Xã / phường', isRequired: true), findsNothing);

    await cubit.close();
  });

  group('PopScope discard confirmation in OrganizationEditProfilePage', () {
    Future<void> pumpForm(WidgetTester tester, OrganizationProfileCubit cubit) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => OrganizationEditProfilePage(cubit: cubit),
                  ),
                ),
                child: const Text('Mở form'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Mở form'));
      await tester.pumpAndSettle();
    }

    testWidgets('unmodified form pops directly on back without dialog', (tester) async {
      final cubit = OrganizationProfileCubit(
        organizationRepository: ScriptedOrganizationRepository(),
      );
      await cubit.load();

      await pumpForm(tester, cubit);
      expect(find.text('Chỉnh thông tin tổ chức'), findsOneWidget);

      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();

      expect(find.text('Bỏ thay đổi?'), findsNothing);
      expect(find.text('Chỉnh thông tin tổ chức'), findsNothing);
      await cubit.close();
    });

    testWidgets('modified form asks confirmation on back, can keep editing or discard', (tester) async {
      final cubit = OrganizationProfileCubit(
        organizationRepository: ScriptedOrganizationRepository(),
      );
      await cubit.load();

      await pumpForm(tester, cubit);

      await tester.enterText(find.byType(TextField).first, 'Mậu Hiên Thay Đổi');
      await tester.pumpAndSettle();

      // Tap back button
      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();
      expect(find.text('Bỏ thay đổi?'), findsOneWidget);

      // Tap 'Tiếp tục sửa'
      await tester.tap(find.text('Tiếp tục sửa'));
      await tester.pumpAndSettle();
      expect(find.text('Bỏ thay đổi?'), findsNothing);
      expect(find.text('Chỉnh thông tin tổ chức'), findsOneWidget);
      expect(find.text('Mậu Hiên Thay Đổi'), findsOneWidget);

      // Tap back button again and discard
      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();
      expect(find.text('Bỏ thay đổi?'), findsOneWidget);
      await tester.tap(find.text('Bỏ thay đổi'));
      await tester.pumpAndSettle();
      expect(find.text('Chỉnh thông tin tổ chức'), findsNothing);
      await cubit.close();
    });

    testWidgets('modified form asks confirmation on cancel button', (tester) async {
      final cubit = OrganizationProfileCubit(
        organizationRepository: ScriptedOrganizationRepository(),
      );
      await cubit.load();

      await pumpForm(tester, cubit);

      await tester.enterText(find.byType(TextField).first, 'Mậu Hiên Thay Đổi');
      await tester.pumpAndSettle();

      // Tap 'Hủy' button
      await tester.tap(find.widgetWithText(VButton, 'Hủy'));
      await tester.pumpAndSettle();
      expect(find.text('Bỏ thay đổi?'), findsOneWidget);

      await tester.tap(find.text('Bỏ thay đổi'));
      await tester.pumpAndSettle();
      expect(find.text('Chỉnh thông tin tổ chức'), findsNothing);
      await cubit.close();
    });
  });

  testWidgets('390: two cards, units above address, note at the end', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cubit = OrganizationProfileCubit(
      organizationRepository: ScriptedOrganizationRepository(),
    );
    await cubit.load();

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: OrganizationEditProfilePage(cubit: cubit),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(VCard), findsNWidgets(2));
    final provinceTop = tester
        .getTopLeft(find.byKey(const Key('field_select_province')))
        .dy;
    final addressTop = tester.getTopLeft(find.text('Địa chỉ liên hệ')).dy;
    final noteTop = tester
        .getTopLeft(
          find.text(
            'Thông tin liên hệ này độc lập với hồ sơ pháp lý và chứng từ đã phát hành.',
          ),
        )
        .dy;
    expect(provinceTop, lessThan(addressTop));
    expect(addressTop, lessThan(noteTop));
    await cubit.close();
  });

  testWidgets('1280: grid — phone and email share a row, units share a row', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cubit = OrganizationProfileCubit(
      organizationRepository: ScriptedOrganizationRepository(),
    );
    await cubit.load();

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: OrganizationEditProfilePage(cubit: cubit),
      ),
    );
    await tester.pumpAndSettle();

    final phoneTop = tester.getTopLeft(find.text('Số điện thoại')).dy;
    final emailTop = tester.getTopLeft(find.text('Email liên hệ')).dy;
    expect(phoneTop, emailTop);

    final provinceTop = tester
        .getTopLeft(find.byKey(const Key('field_select_province')))
        .dy;
    final wardTop = tester
        .getTopLeft(find.byKey(const Key('field_select_ward')))
        .dy;
    expect(provinceTop, wardTop);
    await cubit.close();
  });

  testWidgets('resizing keeps values and still asks before leaving', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cubit = OrganizationProfileCubit(
      organizationRepository: ScriptedOrganizationRepository(),
    );
    await cubit.load();

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => OrganizationEditProfilePage(cubit: cubit),
                ),
              ),
              child: const Text('Mở form'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Mở form'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Tên mới 900');
    await tester.pumpAndSettle();

    tester.view.physicalSize = const Size(700, 800);
    await tester.pumpAndSettle();

    expect(find.text('Tên mới 900'), findsOneWidget);
    await tester.tap(find.byTooltip('Quay lại'));
    await tester.pumpAndSettle();
    expect(find.text('Bỏ thay đổi?'), findsOneWidget);
    await cubit.close();
  });

  testWidgets('320 at text scale 2.0 and 840x900 do not overflow', (
    tester,
  ) async {
    final cubit = OrganizationProfileCubit(
      organizationRepository: ScriptedOrganizationRepository(),
    );
    await cubit.load();

    for (final size in const [Size(320, 568), Size(840, 900)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: const TextScaler.linear(2.0),
            ),
            child: OrganizationEditProfilePage(cubit: cubit),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'overflow at $size');
    }
    await cubit.close();
  });
}

Finder _fieldLabel(String text, {bool isRequired = false}) {
  return find.byWidgetPredicate(
    (widget) => widget is VFieldLabel && widget.text == text && widget.isRequired == isRequired,
  );
}
