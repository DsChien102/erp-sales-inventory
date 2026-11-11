import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/features/inventory/presentation/patterns/expiry_date_field.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: VTheme.lightTheme,
      home: Scaffold(body: child),
    );
  }

  group('InventoryExpiryField', () {
    testWidgets('renders_label_and_hint', (tester) async {
      await tester.pumpWidget(
        wrap(
          InventoryExpiryField(
            label: 'Hạn dùng',
            errorText: 'Hạn dùng chưa đúng dạng',
            value: '',
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.text('Hạn dùng'), findsOneWidget);
      expect(find.text('dd/mm/yyyy'), findsOneWidget);
    });

    testWidgets('shows_error_when_invalid', (tester) async {
      await tester.pumpWidget(
        wrap(
          InventoryExpiryField(
            label: 'Hạn dùng',
            errorText: 'Hạn dùng chưa đúng dạng',
            value: '31/02/2026',
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.text('Hạn dùng chưa đúng dạng'), findsOneWidget);
    });

    testWidgets('valid_date_no_error', (tester) async {
      await tester.pumpWidget(
        wrap(
          InventoryExpiryField(
            label: 'Hạn dùng',
            errorText: 'Hạn dùng chưa đúng dạng',
            value: '30/11/2026',
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.text('Hạn dùng chưa đúng dạng'), findsNothing);
    });
  });
}

