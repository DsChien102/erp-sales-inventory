typedef BusHandlerFn = Future<dynamic> Function(Object message);

/// Type-keyed message dispatcher shared by command and query buses.
final class TypedBus<TMessage extends Object, TResult> {
  final Map<Type, BusHandlerFn> _handlers = {};

  void register<T extends TMessage, R>(
    Future<R> Function(T message) handler,
  ) {
    _handlers[T] = (message) => handler(message as T);
  }

  bool isRegistered<T extends TMessage>() => _handlers.containsKey(T);

  Future<TResult> execute(TMessage message) async {
    final handler = _handlers[message.runtimeType];
    if (handler == null) {
      throw StateError(
        'No handler registered for ${message.runtimeType}',
      );
    }

    return await handler(message) as TResult;
  }
}
