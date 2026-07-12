import 'package:vet45_shared_application/application.dart';

import 'product_custom_field_value_input.dart';
import 'upsert_custom_field_values_command.dart';

final class UpsertCustomFieldValuesCommandValidator
    implements ICommandValidator<UpsertCustomFieldValuesCommand> {
  @override
  Future<void> validate(UpsertCustomFieldValuesCommand command) async {
    if (command.tenantId.trim().isEmpty) {
      throw ValidationException('Tenant id is required.');
    }
    if (command.productId.trim().isEmpty) {
      throw ValidationException('Product id is required.');
    }

    final fieldIds = <String>{};
    for (final value in command.values) {
      if (value.fieldId.trim().isEmpty) {
        throw ValidationException('Field id is required.');
      }
      if (!fieldIds.add(value.fieldId)) {
        throw ValidationException('Duplicate custom field value.');
      }
      if (_typedValueCount(value) > 1) {
        throw ValidationException(
          'Only one typed value is allowed per custom field.',
        );
      }
    }
  }

  int _typedValueCount(ProductCustomFieldValueInput input) {
    return [
      input.textValue != null && input.textValue!.trim().isNotEmpty,
      input.numberValue != null,
      input.dateValue != null,
      input.booleanValue != null,
      input.optionId != null && input.optionId!.trim().isNotEmpty,
    ].where((hasValue) => hasValue).length;
  }
}
