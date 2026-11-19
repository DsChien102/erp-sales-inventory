/// Global map from integration event [Type] to routing [eventType] string.
///
/// Modules register their events at startup before [IEventsBus.subscribe].
final class IntegrationEventTypeRegistry {
  IntegrationEventTypeRegistry._();

  static final Map<Type, String> _types = {};

  static void registerAll(Map<Type, String> types) {
    _types.addAll(types);
  }

  static String typeOf(Type type) {
    final eventType = _types[type];
    if (eventType == null) {
      throw StateError('No event type registered for $type');
    }
    return eventType;
  }

  static void clear() => _types.clear();
}
