/// Declares which command type a handler class handles (codegen metadata).
class CommandHandlerFor {
  const CommandHandlerFor(this.commandType);

  final Type commandType;
}

/// Declares which query type a handler class handles (codegen metadata).
class QueryHandlerFor {
  const QueryHandlerFor(this.queryType);

  final Type queryType;
}
