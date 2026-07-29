import 'package:vet45_shared_application/application.dart';

@PublicAccess()
final class VerifyMyPasswordResetCommand extends CommandBase<void>
    implements ICommand<void> {
  VerifyMyPasswordResetCommand({
    String? id,
    required this.operationId,
    required this.code,
  }) : super(id);

  final String operationId;
  final String code;
}
