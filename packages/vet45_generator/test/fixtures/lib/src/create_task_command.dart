import 'package:vet45_annotations/vet45_annotations.dart';

import 'cqrs.dart';

@RequiresPermission('task.create')
@RequiresTenant()
@Idempotent(keyField: 'requestId')
final class CreateTaskCommand implements ICommand<String> {
  CreateTaskCommand({required this.requestId, required this.title});

  final String requestId;
  final String title;

  @override
  String get id => requestId;
}

@PublicAccess()
final class LoginCommand implements ICommand<String> {
  LoginCommand({required this.id});

  @override
  final String id;
}
