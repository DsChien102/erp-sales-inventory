import 'package:vet45_shared_application/application.dart';

import 'package:vet45_catalog_application/src/ports/i_catalog_custom_field_value_gateway.dart';
import 'upsert_custom_field_values_command.dart';
import 'upsert_custom_field_values_command_validator.dart';
import 'upsert_custom_field_values_result.dart';

@CommandHandlerFor(UpsertCustomFieldValuesCommand)
final class UpsertCustomFieldValuesCommandHandler
    implements ICommandHandler<UpsertCustomFieldValuesCommand, UpsertCustomFieldValuesResult> {
  UpsertCustomFieldValuesCommandHandler({
    required ICatalogCustomFieldValueGateway customFieldValueGateway,
    UpsertCustomFieldValuesCommandValidator? validator,
  }) : _customFieldValueGateway = customFieldValueGateway,
       _validator = validator ?? UpsertCustomFieldValuesCommandValidator();

  final ICatalogCustomFieldValueGateway _customFieldValueGateway;
  final UpsertCustomFieldValuesCommandValidator _validator;

  @override
  Future<UpsertCustomFieldValuesResult> handle(
    UpsertCustomFieldValuesCommand command,
  ) async {
    await _validator.validate(command);
    return _customFieldValueGateway.upsertValues(command: command);
  }
}
