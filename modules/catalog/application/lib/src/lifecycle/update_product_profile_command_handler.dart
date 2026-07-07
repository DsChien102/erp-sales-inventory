import 'package:vet45_shared_application/application.dart';

import '../ports/i_product_command_gateway.dart';
import 'update_product_profile_command.dart';
import 'update_product_profile_result.dart';

@CommandHandlerFor(UpdateProductProfileCommand)
final class UpdateProductProfileCommandHandler
    implements ICommandHandler<UpdateProductProfileCommand, UpdateProductProfileResult> {
  UpdateProductProfileCommandHandler({
    required IProductCommandGateway commandGateway,
  }) : _commandGateway = commandGateway;

  final IProductCommandGateway _commandGateway;

  @override
  Future<UpdateProductProfileResult> handle(
    UpdateProductProfileCommand command,
  ) {
    return _commandGateway.updateProductProfile(command);
  }
}
