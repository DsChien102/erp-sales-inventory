import 'package:vet45_shared_application/application.dart';

import 'package:vet45_catalog_application/src/ports/i_catalog_unit_gateway.dart';
import 'set_product_base_unit_command.dart';
import 'set_product_base_unit_result.dart';

@CommandHandlerFor(SetProductBaseUnitCommand)
final class SetProductBaseUnitCommandHandler
    implements ICommandHandler<SetProductBaseUnitCommand, SetProductBaseUnitResult> {
  SetProductBaseUnitCommandHandler({
    required ICatalogUnitGateway unitGateway,
  }) : _unitGateway = unitGateway;

  final ICatalogUnitGateway _unitGateway;

  @override
  Future<SetProductBaseUnitResult> handle(
    SetProductBaseUnitCommand command,
  ) {
    return _unitGateway.setProductBaseUnit(command: command);
  }
}
