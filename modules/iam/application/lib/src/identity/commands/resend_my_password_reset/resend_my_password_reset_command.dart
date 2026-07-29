import 'package:vet45_shared_application/application.dart';

import '../../shared/password_reset_operation_dto.dart';

@PublicAccess()
final class ResendMyPasswordResetCommand
    extends CommandBase<PasswordResetOperationDto>
    implements ICommand<PasswordResetOperationDto> {
  ResendMyPasswordResetCommand({
    String? id,
    required this.operationId,
  }) : super(id);

  final String operationId;
}
