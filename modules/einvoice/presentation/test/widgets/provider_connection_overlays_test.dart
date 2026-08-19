import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_einvoice_presentation/presentation.dart';

void main() {
  testWidgets(
    'wgt_e01_u01_fr06_01: O02 lists recheck, reconnect, and disconnect',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: const Scaffold(
            body: ProviderConnectionActionSheet(),
          ),
        ),
      );

      expect(find.byKey(const Key('wgt_e01_u01_fr06_01')), findsOneWidget);
      expect(find.text('Kết nối MISA'), findsOneWidget);
      expect(find.text('Kiểm tra lại kết nối'), findsOneWidget);
      expect(find.text('Xác minh trạng thái kết nối hiện tại'), findsOneWidget);
      expect(find.text('Kết nối lại'), findsOneWidget);
      expect(find.text('Thay đổi tài khoản hoặc mật khẩu'), findsOneWidget);
      expect(find.text('Ngắt kết nối'), findsOneWidget);
      expect(find.text('Không thể phát hành hóa đơn điện tử mới'), findsOneWidget);
    },
  );

  testWidgets(
    'wgt_e01_u01_fr08_01: O01 shows centered disconnect confirmation copy',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => VButton(
                label: 'Open',
                onPressed: () => showDisconnectProviderSheet(context),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Ngắt kết nối MISA?'), findsOneWidget);
      expect(
        find.text(
          'Sau khi ngắt kết nối, không thể phát hành hóa đơn điện tử mới. Hóa đơn và lịch sử đã phát sinh vẫn được giữ nguyên.',
        ),
        findsOneWidget,
      );
      expect(find.text('Giữ kết nối'), findsOneWidget);
      expect(find.text('Ngắt kết nối'), findsOneWidget);
    },
  );
}
