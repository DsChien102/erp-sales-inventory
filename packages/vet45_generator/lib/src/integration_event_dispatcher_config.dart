final class IntegrationEventDispatcherConfig {
  const IntegrationEventDispatcherConfig({
    required this.id,
    required this.factoryFunction,
    required this.dispatcherClass,
    required this.dispatcherImport,
    required this.eventPackages,
    this.integrationEventsImport,
  });

  final String id;
  final String factoryFunction;
  final String dispatcherClass;
  final String dispatcherImport;
  final List<String> eventPackages;
  final String? integrationEventsImport;

  factory IntegrationEventDispatcherConfig.fromMap(Map<dynamic, dynamic> map) {
    final id = map['id'] as String?;
    final factoryFunction = map['factory_function'] as String?;
    final dispatcherClass = map['dispatcher_class'] as String?;
    final dispatcherImport = map['dispatcher_import'] as String?;
    final eventPackages = (map['event_packages'] as List?)?.cast<String>();

    if (id == null || id.isEmpty) {
      throw ArgumentError('dispatcher id must be non-empty');
    }
    if (factoryFunction == null || factoryFunction.isEmpty) {
      throw ArgumentError('dispatcher factory_function must be non-empty for id=$id');
    }
    if (dispatcherClass == null || dispatcherClass.isEmpty) {
      throw ArgumentError('dispatcher dispatcher_class must be non-empty for id=$id');
    }
    if (dispatcherImport == null || dispatcherImport.isEmpty) {
      throw ArgumentError('dispatcher dispatcher_import must be non-empty for id=$id');
    }
    if (eventPackages == null || eventPackages.isEmpty) {
      throw ArgumentError('dispatcher event_packages must be non-empty for id=$id');
    }

    return IntegrationEventDispatcherConfig(
      id: id,
      factoryFunction: factoryFunction,
      dispatcherClass: dispatcherClass,
      dispatcherImport: dispatcherImport,
      eventPackages: eventPackages,
      integrationEventsImport: map['integration_events_import'] as String?,
    );
  }

  String integrationEventsImportForPackage(String packageName) =>
      integrationEventsImport ?? 'package:$packageName/integration_events.dart';
}
