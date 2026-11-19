import 'typed_bus.dart';

export 'typed_bus.dart';

/// Type-keyed handler registry shared by command and query buses.
typedef HandlerRegistry<TMessage extends Object, TResult> = TypedBus<TMessage, TResult>;
