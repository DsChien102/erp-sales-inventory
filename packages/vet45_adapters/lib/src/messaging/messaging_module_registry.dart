import 'i_messaging_module.dart';

/// Ordered registry of messaging modules (sales → catalog → partner → …).
final class MessagingModuleRegistry {
  MessagingModuleRegistry(List<IMessagingModule> modules)
      : _modules = List.unmodifiable(_validateUniqueNames(modules));

  final List<IMessagingModule> _modules;

  Iterable<IMessagingModule> get modules => _modules;

  static List<IMessagingModule> _validateUniqueNames(List<IMessagingModule> modules) {
    final seen = <String>{};
    for (final module in modules) {
      if (!seen.add(module.name)) {
        throw ArgumentError.value(
          module.name,
          'modules',
          'Duplicate messaging module name.',
        );
      }
    }
    return modules;
  }
}
