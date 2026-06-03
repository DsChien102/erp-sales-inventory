/// Marks a command handler for business command bus registration.
@Deprecated('Use CommandHandlerFor on the handler class instead')
class CqrsBusinessHandler {
  const CqrsBusinessHandler();
}

/// Marks a command handler for internal async command registration.
class CqrsInternalHandler {
  const CqrsInternalHandler();
}

/// Marks a query handler for query bus registration.
@Deprecated('Use QueryHandlerFor on the handler class instead')
class CqrsQueryHandler {
  const CqrsQueryHandler();
}

/// Marks a command validator for GetIt factory registration.
class CqrsValidator {
  const CqrsValidator();
}

/// Excludes a handler/validator from CQRS registration codegen.
class CqrsExclude {
  const CqrsExclude();
}
