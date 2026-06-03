abstract interface class ICommandHandler<TCommand, TResult> {
  Future<TResult> handle(TCommand command);
}

abstract interface class IQuery<TResult> {
  String get id;
}

abstract interface class IQueryHandler<TQuery, TResult> {
  Future<TResult> handle(TQuery query);
}

abstract interface class ICommandValidator<TCommand> {
  Future<void> validate(TCommand command);
}

abstract interface class ISerializableInternalCommand {
  String get commandType;
  String get tenantId;
  Map<String, dynamic> toJson();
}

abstract class InternalCommandBase<TResult> implements ICommand<dynamic> {
  InternalCommandBase([String? id]) : id = id ?? 'id';

  @override
  final String id;
}

abstract interface class ICommand<TResult> {
  String get id;
}
