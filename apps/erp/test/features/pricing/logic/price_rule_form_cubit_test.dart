import 'package:erp/features/pricing/presentation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_customer_price_rule_repository.dart';
import '../support/pricing_detail_dto_builder.dart';

void main() {
  group('B4 — form edit keeps note when no reason', () {
    test('b4_update_without_reason_keeps_note', () async {
      final repo = FakeCustomerPriceRuleRepository();
      final cubit = PriceRuleFormCubit(
        existingRule: buildPricingDetailDto(note: 'Ghi chú cũ'),
        mode: PriceRuleFormMode.edit,
        repository: repo,
      );

      cubit.updatePrice(100000);
      await cubit.submit(changeReason: null);

      expect(repo.calls.last.method, 'update');
      expect(repo.calls.last.args['note'], 'Ghi chú cũ');

      await cubit.close();
    });
  });

  group('H5 — change reason handling', () {
    test('h5_reason_goes_to_change_reason', () async {
      final repo = FakeCustomerPriceRuleRepository();
      final cubit = PriceRuleFormCubit(
        existingRule: buildPricingDetailDto(note: 'Ghi chú cũ'),
        mode: PriceRuleFormMode.edit,
        repository: repo,
      );

      cubit.updatePrice(100000);
      await cubit.submit(changeReason: 'Theo hợp đồng Q3');

      expect(repo.calls.last.method, 'update');
      expect(repo.calls.last.args['note'], 'Ghi chú cũ');
      expect(repo.calls.last.args['changeReason'], 'Theo hợp đồng Q3');

      await cubit.close();
    });

    test('h5_no_reason_sends_null', () async {
      final repo = FakeCustomerPriceRuleRepository();
      final cubit = PriceRuleFormCubit(
        existingRule: buildPricingDetailDto(note: 'Ghi chú cũ'),
        mode: PriceRuleFormMode.edit,
        repository: repo,
      );

      cubit.updatePrice(100000);
      await cubit.submit(changeReason: null);

      expect(repo.calls.last.method, 'update');
      expect(repo.calls.last.args['note'], 'Ghi chú cũ');
      expect(repo.calls.last.args['changeReason'], isNull);

      await cubit.close();
    });

    test('h5_overwrite_keeps_reason', () async {
      final repo = FakeCustomerPriceRuleRepository();
      final cubit = PriceRuleFormCubit(
        existingRule: buildPricingDetailDto(note: 'Ghi chú cũ'),
        mode: PriceRuleFormMode.edit,
        repository: repo,
      );

      cubit.updatePrice(100000);
      await cubit.confirmOverwrite(changeReason: 'X');

      expect(repo.calls.last.method, 'update');
      expect(repo.calls.last.args['note'], 'Ghi chú cũ');
      expect(repo.calls.last.args['changeReason'], 'X');
      expect(repo.calls.last.args['acknowledgeOverwrite'], isTrue);

      await cubit.close();
    });
  });
}
