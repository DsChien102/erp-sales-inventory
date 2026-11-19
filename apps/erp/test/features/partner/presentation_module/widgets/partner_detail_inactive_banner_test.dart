import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/features/partner/presentation.dart';

void main() {
  testWidgets('wgt_e02_u01_fr02_01: inactive banner matches D-04 copy', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PartnerDetailInactiveBanner(),
        ),
      ),
    );

    expect(find.byKey(const Key('wgt_e02_u01_fr02_01')), findsOneWidget);
    expect(
      find.text(PartnerDetailInactiveBanner.message),
      findsOneWidget,
    );
    expect(find.byIcon(VIcons.warning.value), findsOneWidget);
  });
}
