import 'package:vet45_shared_application/application.dart';

import 'list_custom_field_config_query.dart';

final class ListCustomFieldConfigQueryValidator
    implements ICommandValidator<ListCustomFieldConfigQuery> {
  @override
  Future<void> validate(ListCustomFieldConfigQuery query) async {
    if (query.tenantId.trim().isEmpty) {
      throw ValidationException('Tenant id is required.');
    }
  }
}
