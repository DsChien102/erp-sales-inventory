import 'package:vet45_shared_application/application.dart';

import '../ports/i_product_command_gateway.dart';
import 'change_product_business_status_result.dart';
import 'deactivate_product_command.dart';

@CommandHandlerFor(DeactivateProductCommand)
final class DeactivateProductCommandHandler
    implements ICommandHandler<DeactivateProductCommand, ChangeProductBusinessStatusResult> {
  DeactivateProductCommandHandler({
    required IProductCommandGateway commandGateway,
  }) : _commandGateway = commandGateway;

  final IProductCommandGateway _commandGateway;

  @override
  Future<ChangeProductBusinessStatusResult> handle(
    DeactivateProductCommand command,
  ) {
    return _commandGateway.deactivateProduct(command);
  }
}
