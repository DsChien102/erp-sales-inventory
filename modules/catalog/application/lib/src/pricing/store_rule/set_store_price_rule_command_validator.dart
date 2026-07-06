import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'set_store_price_rule_command.dart';

final class SetStorePriceRuleCommandValidator
    implements ICommandValidator<SetStorePriceRuleCommand> {
  @override
  Future<void> validate(SetStorePriceRuleCommand command) async {
    if (command.tenantId.trim().isEmpty) {
      throw ValidationException('Tenant id is required.');
    }
    if (command.name.trim().isEmpty) {
      throw ValidationException('Tên quy tắc giá là bắt buộc.');
    }

    final listRule = MarkupRatioMustBeNonNegativeRule(
      ratio: command.listMarkupRatio,
      label: 'Tỷ lệ cộng thêm Giá niêm yết',
    );
    if (listRule.isBroken()) {
      throw ValidationException(listRule.message);
    }

    final floorRule = MarkupRatioMustBeNonNegativeRule(
      ratio: command.floorMarkupRatio,
      label: 'Tỷ lệ cộng thêm Giá sàn',
    );
    if (floorRule.isBroken()) {
      throw ValidationException(floorRule.message);
    }

    final orderingRule = SuggestedFloorNotGreaterThanListRule(
      basePrice: 100,
      listMarkupRatio: command.listMarkupRatio,
      floorMarkupRatio: command.floorMarkupRatio,
    );
    if (orderingRule.isBroken()) {
      throw ValidationException(orderingRule.message);
    }
  }
}
