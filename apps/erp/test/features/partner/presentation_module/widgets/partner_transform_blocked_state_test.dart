import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/features/partner/data/models/partner_models.dart';
import 'package:erp/features/partner/presentation.dart';

void main() {
  testWidgets('wgt_e01_u06_fr08_01 no permission blocked state', (tester) async {
    var backCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PartnerTransformBlockedState.noPermission(
            onActionPressed: () => backCount++,
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('transform_blocked_no_permission')), findsOneWidget);
    expect(find.text('Không có quyền chuyển đổi'), findsOneWidget);
    expect(
      find.text('Bạn không có quyền thực hiện chuyển đổi hồ sơ này.'),
      findsOneWidget,
    );
    expect(find.text('Quay lại'), findsOneWidget);

    await tester.tap(find.byKey(const Key('transform_blocked_back')));
    expect(backCount, 1);
  });

  testWidgets('wgt_e01_u06_fr08_02 stale data blocked state', (tester) async {
    var reloadCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PartnerTransformBlockedState.staleData(
            onActionPressed: () => reloadCount++,
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('transform_blocked_stale_data')), findsOneWidget);
    expect(find.text('Dữ liệu đã thay đổi'), findsOneWidget);
    expect(
      find.text(
        'Hồ sơ đã được cập nhật ở nơi khác. Vui lòng tải lại để tiếp tục.',
      ),
      findsOneWidget,
    );
    expect(find.text('Tải lại'), findsOneWidget);

    await tester.tap(find.byKey(const Key('transform_blocked_reload')));
    expect(reloadCount, 1);
  });

  test('maps blocked codes for later command wiring', () {
    expect(
      partnerTransformBlockedKindFromCode(PartnerErrorCodes.noPermission),
      PartnerTransformBlockedKind.noPermission,
    );
    expect(
      partnerTransformBlockedKindFromCode(PartnerErrorCodes.stateChanged),
      PartnerTransformBlockedKind.staleData,
    );
    expect(
      partnerTransformBlockedKindFromCode(PartnerErrorCodes.validationError),
      isNull,
    );
  });

  testWidgets('outline action uses success tone', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PartnerTransformBlockedState.noPermission(onActionPressed: () {}),
        ),
      ),
    );

    final button = tester.widget<VButton>(
      find.byKey(const Key('transform_blocked_back')),
    );
    expect(button.variant, VButtonVariant.secondary);
    expect(button.foregroundColor, VColorScheme.light.success);
  });
}
