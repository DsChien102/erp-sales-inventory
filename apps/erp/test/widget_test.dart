import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ERP greenfield shell placeholder', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Vet45 ERP greenfield baseline'),
          ),
        ),
      ),
    );

    expect(find.textContaining('greenfield baseline'), findsOneWidget);
  });
}
