import 'package:vet45_shared_application/application.dart';
import '../../shared/password_reset_verify_result_dto.dart';

@PublicAccess()
final class VerifyMyPasswordResetCommand
    extends CommandBase<PasswordResetVerifyResultDto>
    implements ICommand<PasswordResetVerifyResultDto> {
  VerifyMyPasswordResetCommand({
    String? id,
    required this.operationId,
    required this.code,
  }) : super(id);

  final String operationId;
  final String code;
}
