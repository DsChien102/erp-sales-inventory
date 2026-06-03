import 'package:vet45_annotations/vet45_annotations.dart';

import 'cqrs.dart';

@QueryHandlerFor(GetTaskByIdQuery)
final class GetTaskByIdQueryHandler implements IQueryHandler<GetTaskByIdQuery, String> {
  GetTaskByIdQueryHandler();

  @override
  Future<String> handle(GetTaskByIdQuery query) async => 'task-dto';
}

final class GetTaskByIdQuery implements IQuery<String> {
  GetTaskByIdQuery(this.taskId);

  final String taskId;

  @override
  String get id => taskId;
}
