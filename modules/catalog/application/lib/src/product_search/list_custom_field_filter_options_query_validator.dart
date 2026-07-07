import 'package:vet45_shared_application/application.dart';

import 'list_custom_field_filter_options_query.dart';

final class ListCustomFieldFilterOptionsQueryValidator
    implements ICommandValidator<ListCustomFieldFilterOptionsQuery> {
  @override
  Future<void> validate(ListCustomFieldFilterOptionsQuery query) async {
    if (query.tenantId.trim().isEmpty) {
      throw ValidationException('Tenant is required.');
    }
    if (query.maxOptionsPerField < 1 || query.maxOptionsPerField > 200) {
      throw ValidationException('maxOptionsPerField must be between 1 and 200.');
    }
  }
}
