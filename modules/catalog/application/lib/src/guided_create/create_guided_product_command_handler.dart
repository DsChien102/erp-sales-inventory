import 'package:vet45_shared_application/application.dart';

import '../ports/i_guided_product_command_gateway.dart';
import 'create_guided_product_command.dart';
import 'create_guided_product_result.dart';

@CommandHandlerFor(CreateGuidedProductCommand)
final class CreateGuidedProductCommandHandler
    implements ICommandHandler<CreateGuidedProductCommand, CreateGuidedProductResult> {
  const CreateGuidedProductCommandHandler({required IGuidedProductCommandGateway gateway})
      : _gateway = gateway;

  final IGuidedProductCommandGateway _gateway;

  @override
  Future<CreateGuidedProductResult> handle(CreateGuidedProductCommand command) =>
      _gateway.createGuidedProduct(command);
}
