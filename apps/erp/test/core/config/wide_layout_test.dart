import 'package:erp/core/config/wide_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('threshold', () {
    expect(isWideSize(const Size(839, 900)), isFalse);
    expect(isWideSize(const Size(840, 900)), isTrue);
    expect(isWideSize(const Size(840, 480)), isTrue);
    expect(isWideSize(const Size(1280, 479)), isFalse);
    expect(isWideSize(const Size(844, 390)), isFalse); // iPhone xoay ngang
    expect(isWideSize(const Size(932, 430)), isFalse);
  });

  testWidgets('keyboard does not change the layout', (tester) async {
    late bool wide;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(900, 600),
          viewInsets: EdgeInsets.only(bottom: 327),
        ),
        child: Builder(
          builder: (context) {
            wide = isWideLayout(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(wide, isTrue);
  });
}
