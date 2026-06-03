/// Generated module manifest for documentation and architecture checks.
final class GeneratedModuleManifest {
  const GeneratedModuleManifest({
    required this.name,
    required this.permissions,
    required this.commandTypes,
    required this.queryTypes,
    this.version,
  });

  final String name;
  final List<String> permissions;
  final List<Type> commandTypes;
  final List<Type> queryTypes;
  final String? version;
}
