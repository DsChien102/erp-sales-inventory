import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/features/partner/data/models/partner_models.dart';
import 'package:erp/features/partner/presentation.dart';

void main() {
  testWidgets('D-10 no permission copy + Quay lại', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PartnerOperationFeedbackState.noPermission(
            onActionPressed: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('wgt_e02_d10_no_permission')), findsOneWidget);
    expect(find.text('Không có quyền thực hiện thao tác'), findsOneWidget);
    expect(
      find.text('Bạn không có quyền xem hoặc thực hiện thao tác này.'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('feedback_no_permission_back')));
    expect(tapped, isTrue);
  });

  testWidgets('D-10 source changed copy + Tải lại', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PartnerOperationFeedbackState.sourceChanged(
            onActionPressed: () {},
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('wgt_e02_d10_source_changed')), findsOneWidget);
    expect(find.text('Dữ liệu đã thay đổi'), findsOneWidget);
    expect(find.text('Tải lại'), findsOneWidget);
    expect(find.byIcon(VIcons.refresh.value), findsOneWidget);
  });

  testWidgets('D-10 error copy + Thử lại', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PartnerOperationFeedbackState.error(
            onActionPressed: () {},
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('wgt_e02_d10_error')), findsOneWidget);
    expect(find.text('Đã xảy ra lỗi'), findsOneWidget);
    expect(find.text('Vui lòng thử lại sau.'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
  });

  test('maps blocked codes to feedback kinds', () {
    expect(
      partnerOperationFeedbackKindFromCode(PartnerErrorCodes.noPermission),
      PartnerOperationFeedbackKind.noPermission,
    );
    expect(
      partnerOperationFeedbackKindFromCode(PartnerErrorCodes.stateChanged),
      PartnerOperationFeedbackKind.sourceChanged,
    );
    expect(
      partnerOperationFeedbackKindFromCode(PartnerErrorCodes.systemError),
      PartnerOperationFeedbackKind.error,
    );
    expect(
      partnerOperationFeedbackKindFromCode(PartnerErrorCodes.hasTransactions),
      isNull,
    );
  });
}
