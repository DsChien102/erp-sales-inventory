import 'package:vet45_shared_application/application.dart';

import '../ports/i_product_command_gateway.dart';
import 'change_product_business_status_result.dart';
import 'deactivate_product_command.dart';
import 'deactivate_product_command_validator.dart';

@CommandHandlerFor(DeactivateProductCommand)
final class DeactivateProductCommandHandler
    implements ICommandHandler<DeactivateProductCommand, ChangeProductBusinessStatusResult> {
  DeactivateProductCommandHandler({
    required IProductCommandGateway commandGateway,
    DeactivateProductCommandValidator? validator,
  }) : _commandGateway = commandGateway,
       _validator = validator ?? DeactivateProductCommandValidator();

  final IProductCommandGateway _commandGateway;
  final DeactivateProductCommandValidator _validator;

  @override
  Future<ChangeProductBusinessStatusResult> handle(
    DeactivateProductCommand command,
  ) async {
    await _validator.validate(command);
    return _commandGateway.deactivateProduct(command);
  }
}
