import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/features/sales/presentation.dart';

void main() {
  testWidgets('loading state renders card skeletons plus a count skeleton', (
    tester,
  ) async {
    await _pumpBody(tester, const SalesCustomerPickerLoading());

    expect(find.byKey(const Key('wgt_sg04_loading')), findsOneWidget);
    expect(find.byKey(const Key('txt_sg04_result_count')), findsNothing);
    expect(_countBone(), findsOneWidget);
    expect(_cardBones(), findsWidgets);
  });

  testWidgets('loading state drops the count skeleton when the count is hidden', (
    tester,
  ) async {
    await _pumpBody(
      tester,
      const SalesCustomerPickerLoading(),
      showResultCount: false,
    );

    expect(_countBone(), findsNothing);
    expect(_cardBones(), findsWidgets);
  });

  testWidgets('loaded state renders the count label and cards', (tester) async {
    await _pumpBody(
      tester,
      const SalesCustomerPickerLoaded(
        query: 'Nguyen',
        items: [
          SalesCustomerListItemVm(
            partnerId: 'partner-1',
            displayName: 'Nguyen Van A',
          ),
        ],
      ),
    );

    expect(find.byKey(const Key('txt_sg04_result_count')), findsOneWidget);
    expect(find.text('1 kết quả · “Nguyen”'), findsOneWidget);
    expect(find.byType(VSkeleton), findsNothing);
  });
}

/// Bone của nhãn đếm là bone duy nhất có bề rộng cố định; bone thẻ khách hàng
/// giãn hết chiều ngang. Tránh phụ thuộc số item của skeleton list.
Finder _countBone() {
  return find.byWidgetPredicate(
    (widget) => widget is VSkeleton && widget.width != null,
  );
}

Finder _cardBones() {
  return find.byWidgetPredicate(
    (widget) => widget is VSkeleton && widget.width == null,
  );
}

Future<void> _pumpBody(
  WidgetTester tester,
  SalesCustomerPickerState state, {
  bool showResultCount = true,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: VTheme.lightTheme,
      home: Scaffold(
        body: SalesCustomerPickerBody(
          state: state,
          showResultCount: showResultCount,
          onTapCustomer: (_) {},
        ),
      ),
    ),
  );
  await tester.pump();
}
