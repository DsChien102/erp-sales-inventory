/// Maps transport-layer failures to caller-facing errors.
abstract interface class IErrorMapper {
  Object map(Object error, [StackTrace? stackTrace]);
}
