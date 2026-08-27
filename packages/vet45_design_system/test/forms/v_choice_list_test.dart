import 'package:flutter/material.dart';
// ignore_for_file: deprecated_member_use
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

void main() {
  group('VChoiceList', () {
    testWidgets('single choice selects one radio option', (tester) async {
      var selected = <String>['hidden'];

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: VChoiceList<String>(
              title: 'Tên công ty',
              selected: selected,
              choices: const [
                VChoiceOption(value: 'hidden', label: 'Ẩn'),
                VChoiceOption(value: 'optional', label: 'Tùy chọn'),
              ],
              onChanged: (values) => selected = values,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tùy chọn'));
      await tester.pumpAndSettle();

      expect(selected, ['optional']);
    });

    testWidgets('multiple choice toggles checkboxes', (tester) async {
      var selected = <String>['email'];

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: VChoiceList<String>(
              title: 'Thông báo',
              allowMultiple: true,
              selected: selected,
              choices: const [
                VChoiceOption(value: 'email', label: 'Email'),
                VChoiceOption(value: 'sms', label: 'SMS'),
              ],
              onChanged: (values) => selected = values,
            ),
          ),
        ),
      );

      await tester.tap(find.text('SMS'));
      await tester.pumpAndSettle();

      expect(selected, containsAll(['email', 'sms']));
    });

    testWidgets('childBuilder renders when option selected', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: VChoiceList<String>(
              title: 'Tên công ty',
              selected: const ['required'],
              choices: [
                VChoiceOption(
                  value: 'required',
                  label: 'Bắt buộc',
                  childBuilder: (isSelected) => isSelected
                      ? const TextField(key: Key('child-field'))
                      : const SizedBox.shrink(),
                ),
              ],
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('child-field')), findsOneWidget);
    });

    testWidgets('external errorText overrides internal error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: VChoiceList<String>(
              title: 'Thanh toán',
              isRequired: true,
              selected: const [],
              errorText: 'Lỗi từ parent',
              choices: const [
                VChoiceOption(value: 'cash', label: 'Tiền mặt'),
              ],
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Lỗi từ parent'), findsOneWidget);
      expect(find.text(VChoiceListValidator.defaultRequiredMessage), findsNothing);
    });

    testWidgets('shows required asterisk in title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: VChoiceList<String>(
              title: 'Thanh toán',
              isRequired: true,
              selected: const [],
              choices: const [
                VChoiceOption(value: 'cash', label: 'Tiền mặt'),
              ],
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Thanh toán'), findsOneWidget);
      expect(find.text(' *'), findsOneWidget);
    });
  });
}
