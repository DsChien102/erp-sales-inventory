import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp/features/partner/presentation.dart';

void main() {
  testWidgets('wgt_e01_u06_fr06_02 renders confirmation contract copy', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PartnerTransformConfirmationDialog(
            onBack: () {},
            onConfirm: () {},
          ),
        ),
      ),
    );

    expect(find.text('Xác nhận chuyển thành tổ chức?'), findsOneWidget);
    expect(
      find.text('Hồ sơ hiện tại sẽ trở thành Tổ chức.'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Thông tin cá nhân hiện tại sẽ được lưu làm Người liên hệ chính.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Lịch sử giao dịch, hóa đơn và công nợ vẫn được giữ nguyên.',
      ),
      findsOneWidget,
    );
    expect(find.text('Quay lại'), findsOneWidget);
    expect(find.text('Xác nhận chuyển'), findsOneWidget);
  });

  testWidgets('wgt_e01_u06_fr06_03 emits confirmation actions', (
    tester,
  ) async {
    var backCount = 0;
    var confirmCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PartnerTransformConfirmationDialog(
            onBack: () => backCount++,
            onConfirm: () => confirmCount++,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('transform_confirmation_back')));
    await tester.tap(find.byKey(const Key('transform_confirmation_confirm')));

    expect(backCount, 1);
    expect(confirmCount, 1);
  });
}
