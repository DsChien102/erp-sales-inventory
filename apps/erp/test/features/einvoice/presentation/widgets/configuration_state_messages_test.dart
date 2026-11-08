import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/features/einvoice/presentation/widgets/configuration_load_error_state.dart';
import 'package:erp/features/einvoice/presentation/widgets/configuration_permission_denied_state.dart';

void main() {
  testWidgets(
    'wgt_e01_s01_01: S01 shows permission denied copy and back action',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: ConfigurationPermissionDeniedState(onBack: () {}),
          ),
        ),
      );

      expect(find.byKey(const Key('wgt_e01_s01_01')), findsOneWidget);
      expect(find.text('Không có quyền truy cập'), findsOneWidget);
      expect(
        find.text(
          'Bạn không có quyền xem hoặc thay đổi thiết lập hóa đơn điện tử của Tổ chức này.',
        ),
        findsOneWidget,
      );
      expect(find.text('Quay lại'), findsOneWidget);
    },
  );

  testWidgets(
    'wgt_e01_s02_01: S02 shows load error copy and retry action',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: const Scaffold(
            body: ConfigurationLoadErrorState(),
          ),
        ),
      );

      expect(find.byKey(const Key('wgt_e01_s02_01')), findsOneWidget);
      expect(find.text('Không thể tải dữ liệu'), findsOneWidget);
      expect(
        find.text(
          'Không thể tải thiết lập hóa đơn điện tử. Hãy thử lại để kiểm tra mức sẵn sàng.',
        ),
        findsOneWidget,
      );
      expect(find.text('Thử lại'), findsOneWidget);
    },
  );
}
