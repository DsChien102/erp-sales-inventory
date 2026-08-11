import 'package:vet45_shared_application/application.dart';

import '../../shared/password_reset_completion_result_dto.dart';

@PublicAccess()
final class CompletePasswordResetByEmailCommand
    extends CommandBase<PasswordResetCompletionResultDto>
    implements ICommand<PasswordResetCompletionResultDto> {
  CompletePasswordResetByEmailCommand({
    String? id,
    required this.operationId,
    required this.newPassword,
  }) : super(id);

  final String operationId;
  final String newPassword;
}
