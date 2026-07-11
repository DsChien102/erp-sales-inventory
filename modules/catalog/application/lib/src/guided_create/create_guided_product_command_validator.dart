import 'package:vet45_shared_application/application.dart';

import '../custom_fields/product_values/product_custom_field_value_input.dart';
import '../units/base_unit_selection.dart';
import 'create_guided_product_command.dart';

final class CreateGuidedProductCommandValidator
    implements ICommandValidator<CreateGuidedProductCommand> {
  @override
  Future<void> validate(CreateGuidedProductCommand command) async {
    if (command.tenantId.trim().isEmpty ||
        command.actorId.trim().isEmpty ||
        command.productName.trim().isEmpty) {
      throw ValidationException('Tenant, actor and product name are required.');
    }
    if (command.images.length > 8) {
      throw ValidationException('A product can have at most 8 images.');
    }
    if (command.images.where((image) => image.isPrimary).length > 1) {
      throw ValidationException('Only one primary image is allowed.');
    }
    if (command.baseUnit case ExistingTenantUnit(:final unitId)) {
      if (unitId.trim().isEmpty) throw ValidationException('Base unit id is required.');
    }
    if (command.baseUnit case NewTenantUnit(:final name)) {
      if (name.trim().isEmpty) throw ValidationException('Base unit name is required.');
    }
    final hasOperationalData = command.initialStock != null ||
        command.basePrice != null ||
        command.listPrice != null ||
        command.floorPrice != null ||
        command.useStorePriceRule;
    if (hasOperationalData && command.baseUnit == null) {
      throw ValidationException('Cần thiết lập đơn vị cơ sở trước tồn kho hoặc giá.');
    }
    if (command.initialStock != null && command.initialStock! < 0) {
      throw ValidationException('Số lượng tồn kho ban đầu phải là số nguyên không âm.');
    }
    for (final value in [command.basePrice, command.listPrice, command.floorPrice]) {
      if (value != null && (!value.isFinite || value < 0)) {
        throw ValidationException('Giá phải là số không âm.');
      }
    }
    if (command.floorPrice != null &&
        command.listPrice != null &&
        command.floorPrice! > command.listPrice!) {
      throw ValidationException('Giá sàn không được lớn hơn giá niêm yết.');
    }
    final fieldIds = <String>{};
    for (final value in command.customFieldValues) {
      if (value.fieldId.trim().isEmpty || !fieldIds.add(value.fieldId)) {
        throw ValidationException('Custom field value không hợp lệ.');
      }
      if (_typedValueCount(value) > 1) {
        throw ValidationException('Mỗi custom field chỉ được có một kiểu giá trị.');
      }
    }
  }

  int _typedValueCount(ProductCustomFieldValueInput input) => [
        input.textValue?.trim().isNotEmpty == true,
        input.numberValue != null,
        input.dateValue != null,
        input.booleanValue != null,
        input.optionId?.trim().isNotEmpty == true,
      ].where((value) => value).length;
}
