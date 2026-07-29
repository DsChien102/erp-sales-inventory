import 'package:vet45_shared_application/application.dart';

@PublicAccess()
final class CompleteMyPasswordResetCommand extends CommandBase<void>
    implements ICommand<void> {
  CompleteMyPasswordResetCommand({
    String? id,
    required this.operationId,
    required this.newPassword,
  }) : super(id);

  final String operationId;
  final String newPassword;
}
